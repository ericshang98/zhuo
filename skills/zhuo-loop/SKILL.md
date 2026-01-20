---
name: zhuo-loop
description: 琢打磨循环 - 迭代式开发直到完美。当用户说"打磨"、"琢"、"迭代改进"、"追求完美"、"反复优化"、"启动循环"时使用。Use for iterative refinement loops where Claude polishes work until completion.
user-invocable: true
---

# 琢 · 打磨循环

玉不琢，不成器。这是一个追求完美的迭代开发循环。

## 启动循环

当用户请求启动打磨循环时，执行初始化脚本：

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

## 用法

```
/zhuo:zhuo-loop "任务描述" --max-iterations 5 --completion-promise "完成条件"
```

## 核心机制

1. **匠人（Creator）**：专注执行任务
2. **知音（Zhiyin）**：以用户视角审视产出
3. **Stop Hook**：代码层面控制循环继续/停止

## 完成循环

当任务完美完成时，输出：
```
<promise>你设置的完成条件</promise>
```

只有当这个陈述完全为真时才能输出它。
