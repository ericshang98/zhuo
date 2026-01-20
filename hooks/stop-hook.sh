#!/bin/bash

# ============================================================================
# 琢 (Zhuo) - Stop Hook
# 玉不琢，不成器
#
# 控制打磨循环的继续或终止
# ============================================================================

# 状态文件 - 在当前工作目录查找
STATE_FILE=".zhuo/zhuo-loop.local.md"

# ----------------------------------------------------------------------------
# 如果状态文件不存在，说明不在循环中，正常退出
# ----------------------------------------------------------------------------
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# ----------------------------------------------------------------------------
# 读取 stdin 获取 hook 输入
# ----------------------------------------------------------------------------
HOOK_INPUT=$(cat)

# 获取 transcript 路径
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | grep -o '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//' || true)

# 展开 ~ 为 HOME
TRANSCRIPT_PATH="${TRANSCRIPT_PATH/#\~/$HOME}"

# ----------------------------------------------------------------------------
# 读取状态文件中的配置
# ----------------------------------------------------------------------------
read_frontmatter() {
    local key="$1"
    # 读取 YAML frontmatter 中的值
    sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep "^${key}:" | sed "s/^${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//'
}

MAX_ITERATIONS=$(read_frontmatter "max_iterations")
COMPLETION_PROMISE=$(read_frontmatter "completion_promise")
CURRENT_ITERATION=$(read_frontmatter "current_iteration")

# 设置默认值
MAX_ITERATIONS=${MAX_ITERATIONS:-0}
CURRENT_ITERATION=${CURRENT_ITERATION:-1}

# ----------------------------------------------------------------------------
# 检查是否有手动停止标记
# ----------------------------------------------------------------------------
if [[ -f ".zhuo/STOP" ]]; then
    rm -f ".zhuo/STOP"
    rm -f "$STATE_FILE"
    # 允许退出
    exit 0
fi

# ----------------------------------------------------------------------------
# 检查 completion-promise
# ----------------------------------------------------------------------------
if [[ -n "$COMPLETION_PROMISE" ]] && [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    # 获取最后一条 assistant 消息
    LAST_ASSISTANT_MSG=$(tail -100 "$TRANSCRIPT_PATH" | grep '"role":"assistant"' | tail -1 || true)

    if [[ -n "$LAST_ASSISTANT_MSG" ]]; then
        # 检查是否包含 <promise>completion_promise</promise>
        if echo "$LAST_ASSISTANT_MSG" | grep -q "<promise>.*${COMPLETION_PROMISE}.*</promise>"; then
            # 找到完成标记，清理并退出
            rm -f "$STATE_FILE"
            exit 0
        fi
    fi
fi

# ----------------------------------------------------------------------------
# 检查迭代次数
# ----------------------------------------------------------------------------
if [[ "$MAX_ITERATIONS" -gt 0 ]] && [[ "$CURRENT_ITERATION" -ge "$MAX_ITERATIONS" ]]; then
    # 达到最大迭代次数，清理并退出
    rm -f "$STATE_FILE"
    exit 0
fi

# ----------------------------------------------------------------------------
# 继续循环：更新迭代次数并阻止退出
# ----------------------------------------------------------------------------
NEW_ITERATION=$((CURRENT_ITERATION + 1))

# 更新状态文件中的迭代次数
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^current_iteration: .*/current_iteration: $NEW_ITERATION/" "$STATE_FILE"
else
    sed -i "s/^current_iteration: .*/current_iteration: $NEW_ITERATION/" "$STATE_FILE"
fi

# 读取原始 prompt (单行，用于显示)
PROMPT=$(sed -n '/^prompt: |$/,/^[a-z_]*:/{ /^prompt: |$/d; /^[a-z_]*:/d; s/^  //p; }' "$STATE_FILE" | head -1 | cut -c1-50)

# 构建继续循环的提示信息 (简洁格式)
if [[ "$MAX_ITERATIONS" -gt 0 ]]; then
    ITERATION_INFO="第 $NEW_ITERATION 轮 / 最多 $MAX_ITERATIONS 轮"
else
    ITERATION_INFO="第 $NEW_ITERATION 轮"
fi

# 构建 reason - 使用简洁格式避免 JSON 转义问题
REASON="琢 · 继续打磨 ($ITERATION_INFO) | 任务: ${PROMPT}..."

if [[ -n "$COMPLETION_PROMISE" ]]; then
    REASON="$REASON | 完成时输出: <promise>$COMPLETION_PROMISE</promise>"
fi

# 输出 JSON 阻止退出 - 使用 python3 确保正确的 JSON 转义
python3 -c "
import json
reason = '''$REASON'''
print(json.dumps({'decision': 'block', 'reason': reason}))
" 2>/dev/null || echo '{"decision": "block", "reason": "继续打磨循环"}'

exit 0
