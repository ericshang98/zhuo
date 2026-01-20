---
description: 显示琢插件的使用说明
---

# 琢 (Zhuo) - 帮助

**玉不琢，不成器** — 一个追求完美的 Claude Code 插件

---

## 命令

| 命令 | 说明 |
|------|------|
| `/zhuo "<prompt>" [options]` | 启动打磨循环 |
| `/zhuo-cancel` | 取消当前循环 |
| `/zhuo-help` | 显示此帮助 |

## 参数

```
/zhuo "<prompt>" [--max-iterations <n>] [--completion-promise "<text>"]
```

| 参数 | 说明 |
|------|------|
| `<prompt>` | 任务描述（必需） |
| `--max-iterations <n>` | 最大迭代次数，0 表示无限制 |
| `--completion-promise "<text>"` | 完成条件，输出 `<promise>text</promise>` 时结束 |

## 示例

```bash
# 基本使用
/zhuo "构建一个用户登录系统"

# 限制迭代次数
/zhuo "重构这个模块" --max-iterations 5

# 设置完成条件
/zhuo "优化性能" --max-iterations 8 --completion-promise "性能优化完成"

# 取消循环
/zhuo-cancel
```

## 工作原理

1. 启动循环后，你以**匠人**身份执行任务
2. 每轮结束时，切换到**知音**视角审视产出
3. 如果还能更好，继续下一轮打磨
4. 当任务完美完成时，输出 `<promise>完成条件</promise>` 结束循环

## 结束条件

循环在以下情况结束：

1. 输出 `<promise>completion-promise</promise>`
2. 达到最大迭代次数
3. 运行 `/zhuo-cancel`

---

*玉不琢，不成器。*
