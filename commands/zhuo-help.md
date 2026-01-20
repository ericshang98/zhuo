---
description: 显示琢插件的使用说明
---

# 琢 (Zhuo) - 帮助

**玉不琢，不成器** — 迭代式打磨循环插件

## 命令

| 命令 | 说明 |
|------|------|
| `/zhuo:zhuo-loop "<task>" [options]` | 启动打磨循环 |
| `/zhuo:zhuo-cancel` | 取消当前循环 |
| `/zhuo:zhuo-help` | 显示此帮助 |

## 参数

```
/zhuo:zhuo-loop "<prompt>" [--max-iterations <n>] [--completion-promise "<text>"]
```

| 参数 | 说明 |
|------|------|
| `<prompt>` | 任务描述（必需） |
| `--max-iterations <n>` | 最大迭代次数 |
| `--completion-promise "<text>"` | 完成条件 |

## 示例

```bash
/zhuo:zhuo-loop "写一个 hello world" --max-iterations 3 --completion-promise "代码完成"
```

## 完成循环

当任务完成时，输出：
```
<promise>你设置的完成条件</promise>
```

## 工作原理

1. 启动循环，执行任务
2. Stop Hook 阻止退出，继续迭代
3. 检测到 `<promise>` 或达到最大迭代次数时结束

---

*玉不琢，不成器。*
