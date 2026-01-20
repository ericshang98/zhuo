---
description: 取消当前的琢打磨循环
allowed-tools:
  - Bash
  - Read
---

# 取消琢循环

检查并取消当前的打磨循环。

```bash
STATE_FILE=".zhuo/zhuo-loop.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "没有发现活跃的琢循环"
else
    echo "=== 当前循环状态 ==="
    cat "$STATE_FILE"
    echo ""

    # 创建停止标记
    touch .zhuo/STOP

    # 读取迭代次数
    CURRENT_ITERATION=$(sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep "^current_iteration:" | sed 's/^current_iteration:[[:space:]]*//')

    echo "琢循环已取消"
    echo "完成了 $((CURRENT_ITERATION - 1)) 轮完整迭代"
    echo ""
    echo "循环将在当前操作完成后停止。"
fi
```
