---
description: 启动琢打磨循环 - 玉不琢不成器
argument-hint: '"<prompt>" [--max-iterations <n>] [--completion-promise "<text>"]'
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-zhuo-loop.sh $ARGUMENTS)
hidden: true
---

Execute the setup script with the provided arguments to initialize the Zhuo polishing loop.
