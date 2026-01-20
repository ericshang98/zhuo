---
description: 启动琢打磨循环 - 玉不琢不成器
argument-hint: "<prompt>" [--max-iterations <n>] [--completion-promise "<text>"]
allowed-tools: Bash(bash:*), Bash(mkdir:*), Bash(cat:*), Read, Write, Edit, Glob, Grep
---

# 琢 · 打磨循环

执行以下命令启动打磨循环：

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$CLAUDE_PROJECT_ROOT}/scripts/setup-zhuo-loop.sh" $ARGUMENTS
```

用户的任务: $ARGUMENTS

按照脚本输出的指引开始打磨循环。完成任务后，如果设置了 completion-promise，输出 `<promise>你的完成条件</promise>` 来结束循环。
