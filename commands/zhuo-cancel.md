---
description: 取消当前的琢打磨循环
allowed-tools: Bash(cat:*), Bash(touch:*), Bash(rm:*), Read
---

# 取消琢循环

执行以下命令取消循环：

```bash
STATE_FILE=".zhuo/zhuo-loop.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "没有发现活跃的琢循环"
else
    echo "=== 当前循环状态 ==="
    cat "$STATE_FILE"
    touch .zhuo/STOP
    echo ""
    echo "琢循环已标记取消，将在当前操作完成后停止。"
fi
```
