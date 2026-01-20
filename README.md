# 琢 (Zhuo)

**玉不琢，不成器** — 一个追求完美的 Claude Code 插件

> "琢"源自中国玉文化，意为雕琢、打磨。
> 不是一步到位的完美，而是一轮又一轮的打磨，直到"这是我们能做到的最好"。

---

## 快速开始

### 安装方式

**方式一：使用 `--plugin-dir` 加载（推荐）**

```bash
# 1. 克隆仓库
git clone https://github.com/ericshang98/zhuo.git
cd zhuo

# 2. 启动 Claude Code 并加载插件
claude --plugin-dir .

# 或者指定完整路径
claude --plugin-dir /path/to/zhuo
```

**方式二：复制到项目 `.claude` 目录**

```bash
# 复制 skills 和 commands 到项目的 .claude 目录
mkdir -p /your/project/.claude/skills
cp -r zhuo/skills/zhuo-loop /your/project/.claude/skills/
cp -r zhuo/commands/* /your/project/.claude/commands/ 2>/dev/null || true
cp zhuo/hooks/* /your/project/.claude/hooks/ 2>/dev/null || true

# 在项目目录启动
cd /your/project
claude
```

**方式三：全局安装到个人目录**

```bash
# 复制 skill 到个人目录
mkdir -p ~/.claude/skills
cp -r zhuo/skills/zhuo-loop ~/.claude/skills/

# 复制 hooks（需要在项目目录下才能生效）
# hooks 是项目级别的，需要在每个项目中配置
```

### 验证安装

```bash
# 方式一：使用 skill（推荐）
# 直接问 Claude："启动琢打磨循环"

# 方式二：使用 slash command
/zhuo:zhuo-loop "测试任务" --max-iterations 2

# 方式三：查看帮助
/zhuo:zhuo-help
```

> **注意**：插件命令格式为 `/插件名:命令名`，即 `/zhuo:zhuo-loop`

### 使用

```bash
# 启动打磨循环
/zhuo "构建一个用户登录系统"

# 限制迭代次数
/zhuo "重构这个模块" --max-iterations 5

# 设置完成条件
/zhuo "优化性能" --max-iterations 8 --completion-promise "性能优化完成"

# 取消循环
/zhuo-cancel

# 查看帮助
/zhuo-help
```

---

## 命令参数

```
/zhuo "<prompt>" [--max-iterations <n>] [--completion-promise "<text>"]
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `<prompt>` | 任务描述 | 必需 |
| `--max-iterations <n>` | 最大迭代次数 | 0 (无限制) |
| `--completion-promise "<text>"` | 完成条件 | 无 |

### 完成循环

当设置了 `--completion-promise` 时，需要输出以下格式来结束循环：

```
<promise>你设置的完成条件</promise>
```

**重要**：只有当这个陈述完全、毫无疑问地为真时，才能输出它。不要为了退出循环而撒谎。

---

## 工作原理

### 核心机制

琢基于 Claude Code 的 **Stop Hook** 机制实现迭代循环：

```
用户运行: /zhuo "任务" --completion-promise "完成"
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│                 琢 · 打磨循环                      │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │  第 1 轮                                     │ │
│  │  匠人: 执行任务                              │ │
│  │  知音: 审视 - "还能更好"                      │ │
│  │  → Stop Hook 阻止退出，继续下一轮             │ │
│  └─────────────────────────────────────────────┘ │
│                      ↓                            │
│  ┌─────────────────────────────────────────────┐ │
│  │  第 2 轮                                     │ │
│  │  匠人: 根据审视改进                          │ │
│  │  知音: 审视 - "满意了"                        │ │
│  │  → 输出 <promise>完成</promise>               │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
└──────────────────────────────────────────────────┘
                    │
                    ▼
            循环结束，任务完成
```

### 知音监督者

启动循环时，会注入**知音（Zhiyin）**监督者角色指引：

- **匠人视角**：专注执行，全力以赴
- **知音视角**：以用户角度审视产出
  - 真正体验（运行代码、阅读文档）
  - 觉察感受（哪里满意？哪里能更好？）
  - 建设性反馈

### 打磨原则

1. **对话，而非判决** - 不是"这不行"，而是"这里能更好吗？"
2. **感受，而非清单** - 真正体验产出，而非机械检查
3. **追求卓越，但要收敛** - 每轮要有实质进展

---

## 插件结构

```
zhuo/
├── .claude-plugin/
│   ├── plugin.json           # 插件元信息
│   └── hooks.json            # Stop Hook 配置
├── commands/
│   ├── zhuo.md               # /zhuo 主命令
│   ├── zhuo-cancel.md        # /zhuo-cancel 取消命令
│   └── zhuo-help.md          # /zhuo-help 帮助
├── scripts/
│   └── setup-zhuo-loop.sh    # 初始化脚本
├── hooks/
│   └── stop-hook.sh          # Stop Hook 脚本
├── agents/
│   └── zhiyin.md             # 知音 Agent 参考
└── README.md
```

### 运行时文件

```
.zhuo/
└── zhuo-loop.local.md        # 循环状态文件
```

---

## 结束条件

循环在以下情况结束：

1. **输出完成标记** - `<promise>completion-promise</promise>`
2. **达到最大迭代次数** - `--max-iterations`
3. **手动取消** - `/zhuo-cancel`

---

## 使用场景

### 功能开发
```bash
/zhuo "构建用户认证系统，包含注册、登录、密码重置" \
  --max-iterations 10 \
  --completion-promise "认证系统开发完成，所有功能正常工作"
```

### 代码重构
```bash
/zhuo "重构 src/utils 目录，提高代码质量" \
  --max-iterations 5 \
  --completion-promise "重构完成，代码更清晰易维护"
```

### 性能优化
```bash
/zhuo "优化应用性能，减少加载时间" \
  --max-iterations 8 \
  --completion-promise "性能优化完成，加载时间显著减少"
```

### 文档改善
```bash
/zhuo "改善 README，让新开发者 5 分钟内能上手" \
  --max-iterations 3 \
  --completion-promise "文档清晰完整，新人可快速上手"
```

---

## 与 Ralph Loop 的对比

| 特性 | Ralph Loop | 琢 |
|------|------------|-----|
| 核心理念 | 自动化迭代 | 工匠精神 |
| 监督机制 | 自我观察文件变化 | 知音审视者角色 |
| 退出方式 | completion-promise | 同样支持 |
| 额外特色 | 通用迭代 | 注入打磨哲学 |

琢在 Ralph Loop 的技术基础上，增加了：
- **知音监督者**角色指引
- **匠人-知音**双重视角
- **打磨哲学**（对话、感受、收敛）

---

## 技术细节

### 为什么需要 Stop Hook（而非角色扮演）

| 方式 | 控制者 | 可靠性 |
|------|--------|--------|
| 角色扮演 | Claude 自己决定 | ❌ 不可靠，可能提前退出 |
| Stop Hook | 外部脚本强制控制 | ✅ 可靠，代码层面阻止退出 |

Stop Hook 是**代码层面**的控制，不是提示词层面的"请求"：
- Claude 尝试停止时，`stop-hook.sh` 被操作系统执行
- 脚本检查状态文件和 transcript
- 输出 `{"decision": "block"}` 则 Claude **必须**继续
- 这是 Claude Code 的内置机制，不是角色扮演

### Stop Hook 输出格式

**继续循环**：
```json
{"decision": "block", "reason": "继续打磨的提示..."}
```

**结束循环**：
```bash
exit 0  # 无 JSON 输出，允许退出
```

### 状态文件格式

`.zhuo/zhuo-loop.local.md`:
```yaml
---
prompt: |
  任务描述...
max_iterations: 8
completion_promise: "完成条件"
current_iteration: 2
started_at: 2024-01-20T10:30:00+08:00
---
```

---

## 致谢

- **Ralph Loop**：提供了 Stop Hook 循环的技术基础
- **中国玉文化**：提供了"琢"的哲学内涵
- **伯牙子期**：提供了"知音"的人文精神

---

*"玉不琢，不成器。"*
