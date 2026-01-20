---
description: 查看琢循环和限额状态
allowed-tools: Bash(bash:*), Read
---

# 琢 · 状态查看

```bash
# 查找脚本路径
SCRIPT=""
for path in \
    "${CLAUDE_PLUGIN_ROOT}/scripts/zhuo-daemon.sh" \
    "./zhuo/scripts/zhuo-daemon.sh" \
    "$(find . -name 'zhuo-daemon.sh' -type f 2>/dev/null | head -1)"
do
    if [[ -f "$path" ]]; then
        SCRIPT="$path"
        break
    fi
done

if [[ -n "$SCRIPT" ]]; then
    bash "$SCRIPT" status
else
    echo "错误: 找不到 zhuo-daemon.sh"
fi
```
