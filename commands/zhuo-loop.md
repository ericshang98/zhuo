---
description: 启动琢打磨循环 - 玉不琢不成器
argument-hint: "<prompt>" [--max-iterations <n>] [--completion-promise "<text>"]
allowed-tools: Bash(bash:*), Bash(mkdir:*), Bash(cat:*), Bash(find:*), Read, Write, Edit, Glob, Grep
---

# 琢 · 打磨循环

执行以下命令启动打磨循环：

```bash
# 尝试多个可能的路径
SCRIPT=""
for path in \
    "${CLAUDE_PLUGIN_ROOT}/scripts/setup-zhuo-loop.sh" \
    "${CLAUDE_PROJECT_ROOT}/scripts/setup-zhuo-loop.sh" \
    "${CLAUDE_PROJECT_ROOT}/zhuo/scripts/setup-zhuo-loop.sh" \
    "./zhuo/scripts/setup-zhuo-loop.sh" \
    "./scripts/setup-zhuo-loop.sh" \
    "$(find . -name 'setup-zhuo-loop.sh' -type f 2>/dev/null | head -1)"
do
    if [[ -f "$path" ]]; then
        SCRIPT="$path"
        break
    fi
done

if [[ -n "$SCRIPT" ]]; then
    bash "$SCRIPT" $ARGUMENTS
else
    echo "错误: 找不到 setup-zhuo-loop.sh"
    echo "请确保 zhuo 插件目录在当前项目中"
fi
```

用户的任务: $ARGUMENTS

按照脚本输出的指引开始打磨循环。完成任务后，如果设置了 completion-promise，输出 `<promise>你的完成条件</promise>` 来结束循环。
