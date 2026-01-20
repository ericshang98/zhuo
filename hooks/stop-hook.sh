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

# 读取原始 prompt
PROMPT=$(sed -n '/^prompt: |$/,/^[a-z_]*:/{ /^prompt: |$/d; /^[a-z_]*:/d; s/^  //p; }' "$STATE_FILE" | head -20)

# 构建继续循环的提示信息
if [[ "$MAX_ITERATIONS" -gt 0 ]]; then
    ITERATION_INFO="第 $NEW_ITERATION 轮 / 最多 $MAX_ITERATIONS 轮"
else
    ITERATION_INFO="第 $NEW_ITERATION 轮 (无迭代限制)"
fi

REASON="琢 · 继续打磨 ($ITERATION_INFO)

## 知音审视

在继续下一轮之前，请以知音视角审视当前的工作：

1. **真正体验产出** - 运行代码、阅读文件，像用户一样使用它
2. **觉察感受** - 哪里满意？哪里还能更好？
3. **给出反馈** - 对自己诚实，指出可以改进的地方

## 原始任务

$PROMPT

## 本轮工作

以匠人身份继续改进。每一轮打磨都要有实质性进展。"

if [[ -n "$COMPLETION_PROMISE" ]]; then
    REASON="$REASON

## 完成循环

当任务完美完成时，输出：
<promise>$COMPLETION_PROMISE</promise>

只有当这个陈述完全为真时才能输出它。"
fi

# 输出 JSON 阻止退出
if command -v jq &> /dev/null; then
    jq -n --arg reason "$REASON" '{"decision": "block", "reason": $reason}'
else
    # 手动转义 JSON
    ESCAPED_REASON=$(printf '%s' "$REASON" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"继续打磨循环\"")
    echo "{\"decision\": \"block\", \"reason\": $ESCAPED_REASON}"
fi

exit 0
