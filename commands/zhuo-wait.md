---
description: 等待限额重置后自动恢复
argument-hint: [--daemon]
allowed-tools: Bash(bash:*), Read
---

# 琢 · 等待限额重置

检查 Claude Code 限额状态，等待重置后自动恢复任务。

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
    if [[ "$ARGUMENTS" == *"--daemon"* ]]; then
        # 后台守护进程模式
        nohup bash "$SCRIPT" daemon > /dev/null 2>&1 &
        echo "琢 · 守护进程已启动 (PID: $!)"
        bash "$SCRIPT" status
    else
        # 前台等待模式
        bash "$SCRIPT" wait
    fi
else
    echo "错误: 找不到 zhuo-daemon.sh"
fi
```

## 用法

- `/zhuo:zhuo-wait` - 前台等待，显示倒计时
- `/zhuo:zhuo-wait --daemon` - 后台守护，自动检测和恢复

## 工作原理

1. 运行 `claude -p 'hi'` 检测限额状态
2. 解析 "resets Xpm" 获取重置时间
3. 显示倒计时等待
4. 重置后自动恢复任务
