#!/bin/bash

# ============================================================================
# 琢 (Zhuo) - 限额恢复守护进程
#
# 检测 Claude Code 限额状态，等待重置后自动恢复
# ============================================================================

set -e

STATE_FILE=".zhuo/zhuo-loop.local.md"
PID_FILE=".zhuo/daemon.pid"
LOG_FILE=".zhuo/daemon.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ----------------------------------------------------------------------------
# 日志函数
# ----------------------------------------------------------------------------
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

# ----------------------------------------------------------------------------
# 检测限额状态并获取重置时间
# ----------------------------------------------------------------------------
check_rate_limit() {
    # 运行 claude -p 'check' 来检测限额状态
    local output
    output=$(claude -p 'hi' 2>&1 || true)

    # 检查是否包含限额信息
    # 格式: "limit reached ∙ resets Xpm" 或 "usage limit reached"
    if echo "$output" | grep -qi "limit.*reached\|usage.*limit"; then
        # 尝试提取重置时间
        # 格式可能是: "resets 5pm", "resets 11:00pm", "resets in X hours"
        local reset_time
        reset_time=$(echo "$output" | grep -oE "resets [0-9:]+\s*(am|pm|AM|PM)" | head -1 | sed 's/resets //')

        if [[ -n "$reset_time" ]]; then
            echo "$reset_time"
            return 0
        fi

        # 尝试匹配 "resets in X hours"
        local hours
        hours=$(echo "$output" | grep -oE "resets in [0-9]+ hours?" | grep -oE "[0-9]+")
        if [[ -n "$hours" ]]; then
            # 计算重置时间
            local reset_ts=$(($(date +%s) + hours * 3600))
            date -r "$reset_ts" '+%I:%M%p' 2>/dev/null || date -d "@$reset_ts" '+%I:%M%p'
            return 0
        fi

        # 有限额但无法解析时间
        echo "unknown"
        return 0
    fi

    # 没有限额
    return 1
}

# ----------------------------------------------------------------------------
# 解析时间字符串为今天或明天的 Unix 时间戳
# ----------------------------------------------------------------------------
parse_reset_time() {
    local time_str="$1"
    local now_ts=$(date +%s)
    local now_hour=$(date +%H)

    # 解析时间 (如 "5pm", "11:00pm", "5:30PM")
    local hour minute ampm

    if [[ "$time_str" =~ ^([0-9]+):?([0-9]*)([aApP][mM])$ ]]; then
        hour="${BASH_REMATCH[1]}"
        minute="${BASH_REMATCH[2]:-00}"
        ampm="${BASH_REMATCH[3],,}"  # 转小写

        # 转换为 24 小时制
        if [[ "$ampm" == "pm" ]] && [[ "$hour" -ne 12 ]]; then
            hour=$((hour + 12))
        elif [[ "$ampm" == "am" ]] && [[ "$hour" -eq 12 ]]; then
            hour=0
        fi

        # 构建今天的重置时间
        local today_reset
        today_reset=$(date -v${hour}H -v${minute}M -v0S +%s 2>/dev/null || \
                      date -d "today $hour:$minute:00" +%s 2>/dev/null)

        # 如果今天的时间已过，则是明天
        if [[ "$today_reset" -le "$now_ts" ]]; then
            today_reset=$((today_reset + 86400))
        fi

        echo "$today_reset"
    else
        # 无法解析，默认 1 小时后
        echo $((now_ts + 3600))
    fi
}

# ----------------------------------------------------------------------------
# 显示倒计时
# ----------------------------------------------------------------------------
show_countdown() {
    local target_ts="$1"
    local now_ts=$(date +%s)
    local remaining=$((target_ts - now_ts))

    while [[ "$remaining" -gt 0 ]]; do
        local hours=$((remaining / 3600))
        local minutes=$(((remaining % 3600) / 60))
        local seconds=$((remaining % 60))

        printf "\r${CYAN}琢 · 等待限额重置: %02d:%02d:%02d${NC}  " "$hours" "$minutes" "$seconds"

        sleep 1
        now_ts=$(date +%s)
        remaining=$((target_ts - now_ts))
    done

    echo ""
}

# ----------------------------------------------------------------------------
# 恢复 Claude Code 会话
# ----------------------------------------------------------------------------
resume_claude() {
    local session_id="$1"
    local prompt="$2"

    log "${GREEN}限额已重置，正在恢复...${NC}"

    if [[ -n "$session_id" ]]; then
        # 使用 -c 继续会话
        log "继续会话: $session_id"

        # 发送 continue 命令
        # 注意: 这需要 Claude Code 在 tmux 或可以接收输入的环境中
        if command -v tmux &> /dev/null; then
            # 尝试找到运行 Claude Code 的 tmux pane
            local pane
            pane=$(tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null | \
                   grep -i claude | head -1 | awk '{print $1}')

            if [[ -n "$pane" ]]; then
                tmux send-keys -t "$pane" Escape
                sleep 0.5
                tmux send-keys -t "$pane" "continue" Enter
                log "已发送 continue 到 tmux pane: $pane"
                return 0
            fi
        fi

        # 如果无法继续现有会话，启动新会话
        log "无法继续现有会话，启动新会话..."
    fi

    # 启动新的 Claude Code 会话
    if [[ -n "$prompt" ]]; then
        log "启动新会话，任务: $prompt"

        # 在后台启动 Claude Code
        nohup claude --dangerously-skip-permissions -p "$prompt" > .zhuo/claude-output.log 2>&1 &

        log "Claude Code 已启动 (PID: $!)"
    else
        log "${YELLOW}没有找到待恢复的任务${NC}"
    fi
}

# ----------------------------------------------------------------------------
# 从状态文件读取任务信息
# ----------------------------------------------------------------------------
read_task_info() {
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi

    # 读取 prompt
    sed -n '/^prompt: |$/,/^[a-z_]*:/{ /^prompt: |$/d; /^[a-z_]*:/d; s/^  //p; }' "$STATE_FILE"
}

# ----------------------------------------------------------------------------
# 更新状态文件为 rate_limited
# ----------------------------------------------------------------------------
update_state_rate_limited() {
    local reset_time="$1"

    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi

    # 添加或更新 status 和 reset_at 字段
    if grep -q "^status:" "$STATE_FILE"; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/^status:.*/status: rate_limited/" "$STATE_FILE"
        else
            sed -i "s/^status:.*/status: rate_limited/" "$STATE_FILE"
        fi
    else
        # 在 --- 后添加 status
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/^---$/a\\
status: rate_limited" "$STATE_FILE"
        else
            sed -i "/^---$/a status: rate_limited" "$STATE_FILE"
        fi
    fi

    # 添加 reset_at
    if grep -q "^reset_at:" "$STATE_FILE"; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/^reset_at:.*/reset_at: \"$reset_time\"/" "$STATE_FILE"
        else
            sed -i "s/^reset_at:.*/reset_at: \"$reset_time\"/" "$STATE_FILE"
        fi
    else
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/^status:/a\\
reset_at: \"$reset_time\"" "$STATE_FILE"
        else
            sed -i "/^status:/a reset_at: \"$reset_time\"" "$STATE_FILE"
        fi
    fi
}

# ----------------------------------------------------------------------------
# 主逻辑
# ----------------------------------------------------------------------------
main() {
    local mode="${1:-check}"

    mkdir -p .zhuo

    case "$mode" in
        check)
            # 检查当前限额状态
            log "${BLUE}琢 · 检查限额状态...${NC}"

            local reset_time
            if reset_time=$(check_rate_limit); then
                log "${YELLOW}检测到限额，重置时间: $reset_time${NC}"
                echo "$reset_time"
                return 0
            else
                log "${GREEN}未检测到限额，可以正常使用${NC}"
                return 1
            fi
            ;;

        wait)
            # 等待限额重置
            log "${BLUE}琢 · 检查限额并等待...${NC}"

            local reset_time
            if reset_time=$(check_rate_limit); then
                if [[ "$reset_time" == "unknown" ]]; then
                    log "${YELLOW}检测到限额但无法解析重置时间，默认等待 1 小时${NC}"
                    reset_time=$(date -v+1H '+%I:%M%p' 2>/dev/null || date -d '+1 hour' '+%I:%M%p')
                fi

                local reset_ts
                reset_ts=$(parse_reset_time "$reset_time")

                local reset_display
                reset_display=$(date -r "$reset_ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || \
                               date -d "@$reset_ts" '+%Y-%m-%d %H:%M:%S')

                log "${YELLOW}限额将在 $reset_display 重置${NC}"

                # 更新状态文件
                update_state_rate_limited "$reset_display"

                # 显示倒计时
                show_countdown "$reset_ts"

                log "${GREEN}限额已重置！${NC}"

                # 恢复任务
                local prompt
                prompt=$(read_task_info)
                resume_claude "" "$prompt"
            else
                log "${GREEN}未检测到限额，无需等待${NC}"
            fi
            ;;

        daemon)
            # 后台守护进程模式
            log "${BLUE}琢 · 启动守护进程...${NC}"

            # 检查是否已有守护进程运行
            if [[ -f "$PID_FILE" ]]; then
                local old_pid
                old_pid=$(cat "$PID_FILE")
                if kill -0 "$old_pid" 2>/dev/null; then
                    log "${YELLOW}守护进程已在运行 (PID: $old_pid)${NC}"
                    return 0
                fi
            fi

            # 记录 PID
            echo $$ > "$PID_FILE"

            # 循环检查
            while true; do
                local reset_time
                if reset_time=$(check_rate_limit); then
                    log "${YELLOW}检测到限额，重置时间: $reset_time${NC}"

                    local reset_ts
                    reset_ts=$(parse_reset_time "$reset_time")

                    # 等待重置
                    local now_ts=$(date +%s)
                    local wait_seconds=$((reset_ts - now_ts))

                    if [[ "$wait_seconds" -gt 0 ]]; then
                        log "等待 $wait_seconds 秒..."
                        sleep "$wait_seconds"
                    fi

                    # 恢复
                    local prompt
                    prompt=$(read_task_info)
                    resume_claude "" "$prompt"

                    # 清理并退出
                    rm -f "$PID_FILE"
                    break
                fi

                # 每 30 秒检查一次
                sleep 30
            done
            ;;

        stop)
            # 停止守护进程
            if [[ -f "$PID_FILE" ]]; then
                local pid
                pid=$(cat "$PID_FILE")
                if kill -0 "$pid" 2>/dev/null; then
                    kill "$pid"
                    log "${GREEN}守护进程已停止 (PID: $pid)${NC}"
                fi
                rm -f "$PID_FILE"
            else
                log "${YELLOW}没有运行中的守护进程${NC}"
            fi
            ;;

        status)
            # 查看状态
            echo ""
            echo -e "${BLUE}琢 · 限额恢复状态${NC}"
            echo "─────────────────────────────────"

            if [[ -f "$PID_FILE" ]]; then
                local pid
                pid=$(cat "$PID_FILE")
                if kill -0 "$pid" 2>/dev/null; then
                    echo -e "守护进程: ${GREEN}运行中${NC} (PID: $pid)"
                else
                    echo -e "守护进程: ${YELLOW}已停止${NC}"
                fi
            else
                echo -e "守护进程: ${YELLOW}未启动${NC}"
            fi

            if [[ -f "$STATE_FILE" ]]; then
                local status
                status=$(grep "^status:" "$STATE_FILE" | sed 's/status: //' || echo "active")
                local reset_at
                reset_at=$(grep "^reset_at:" "$STATE_FILE" | sed 's/reset_at: //' | tr -d '"' || echo "-")

                echo -e "循环状态: $status"
                if [[ "$status" == "rate_limited" ]]; then
                    echo -e "重置时间: $reset_at"
                fi
            else
                echo -e "循环状态: ${YELLOW}未启动${NC}"
            fi

            echo "─────────────────────────────────"
            ;;

        *)
            echo "用法: zhuo-daemon.sh [check|wait|daemon|stop|status]"
            echo ""
            echo "  check   - 检查当前限额状态"
            echo "  wait    - 检查限额并等待重置后恢复"
            echo "  daemon  - 后台运行，自动检测和恢复"
            echo "  stop    - 停止后台守护进程"
            echo "  status  - 查看当前状态"
            ;;
    esac
}

main "$@"
