---
description: 启动琢打磨循环 - 玉不琢不成器
argument-hint: "<prompt>" [--max-iterations <n>] [--completion-promise "<text>"]
---

# 琢 · 打磨循环

首先执行初始化脚本：

```bash
bash "${CLAUDE_PROJECT_ROOT:-.}/scripts/setup-zhuo-loop.sh" $ARGUMENTS
```

如果脚本不存在，请查找插件目录并执行：

```bash
# 查找 zhuo 插件目录
ZHUO_DIR=$(find ~/.claude/plugins -name "zhuo" -type d 2>/dev/null | head -1)
if [[ -z "$ZHUO_DIR" ]]; then
    ZHUO_DIR=$(find . -name "zhuo" -type d 2>/dev/null | head -1)
fi

if [[ -n "$ZHUO_DIR" ]] && [[ -f "$ZHUO_DIR/scripts/setup-zhuo-loop.sh" ]]; then
    bash "$ZHUO_DIR/scripts/setup-zhuo-loop.sh" $ARGUMENTS
else
    echo "错误: 找不到 zhuo 插件的 setup-zhuo-loop.sh 脚本"
    echo "请确保插件已正确安装"
fi
```

执行完成后，按照脚本输出的指引开始打磨循环。
