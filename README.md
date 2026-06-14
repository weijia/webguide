# WebGuide - 网页引导助手

一个帮助用户逐步完成网页操作的智能引导工具。支持从本地文件或 URL 导入自定义引导任务。

## 创建自定义引导任务

你可以使用以下提示词，发送给任意 AI（如 ChatGPT、Claude、Gemini 等），让它帮你生成符合 WebGuide 格式的引导任务 JSON 文件。

---

## AI 提示词：生成 WebGuide 引导任务

```
请帮我生成一个 WebGuide 引导任务的 JSON 文件。

WebGuide 是一个 Flutter APP，通过在 WebView 中加载网页，然后高亮特定元素并显示引导提示，帮助用户逐步完成网页操作。

### 任务信息

请根据以下信息生成任务：

- **任务名称**：【填写任务名称，如"B站注册引导"】
- **目标网站**：【填写目标网址，如 https://www.bilibili.com】
- **任务描述**：【简要描述这个任务帮助用户做什么】
- **难度**：【easy / medium / hard】
- **预计时间**：【预计完成时间，单位分钟】
- **分类**：【signup / shopping / social / tools / development / other】
- **图标 emoji**：【如 🎬、🛒、💬 等】
- **标签**：【3-5 个关键词标签】

### 引导步骤

请描述用户需要完成的每一个步骤，包括：
1. 步骤标题（简短，如"输入手机号"）
2. 步骤描述（详细说明用户需要做什么）
3. 目标元素（网页上的哪个元素需要操作）
4. 操作类型（click / input / wait）
5. 提示信息（给用户的小贴士）

### 输出要求

请输出一个完整的 JSON 文件，格式如下：

```json
{
  "id": "唯一标识（英文小写+下划线）",
  "name": "任务名称",
  "description": "任务描述",
  "category": "分类",
  "difficulty": "难度",
  "estimatedTime": 预计分钟数,
  "targetUrl": "目标网站URL",
  "icon": "emoji图标",
  "tags": ["标签1", "标签2"],
  "version": "1.0.0",
  "author": "作者名",
  "downloadCount": 0,
  "rating": 0,
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z",
  "steps": [
    {
      "id": "step_1",
      "order": 1,
      "title": "步骤标题",
      "description": "步骤详细描述",
      "target": {
        "selector": "CSS选择器",
        "tag": "HTML标签名",
        "attributes": {"属性名": "属性值"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "elementAppeared",
      "hint": "提示信息",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    }
  ]
}
```

### 关键规则

1. **CSS 选择器**：使用最稳定的选择器，优先使用 `input[type='xxx']`、`button[type='submit']` 等基于类型的选择器，避免使用可能变化的 `name`、`id` 属性
2. **waitTimeout**：普通步骤 30000ms（30秒），需要用户手动操作的步骤（如邮箱验证）120000ms（2分钟）
3. **action 类型**：
   - `click`：点击元素（按钮、链接、复选框）
   - `input`：在输入框中输入内容
   - `wait`：等待页面变化或用户操作
4. **validation 类型**：
   - `elementAppeared`：元素出现在页面上
   - `urlChange`：页面 URL 发生变化
   - `manual`：需要用户手动确认（如查看邮箱）
5. **步骤数量**：建议 5-10 步，每步聚焦一个操作
6. **描述语言**：使用中文，面向普通用户，避免技术术语

### 示例步骤

以 GitHub 注册为例：

步骤1：访问注册页面
- 目标：`input[type='email']`（邮箱输入框）
- 操作：click
- 说明：让用户点击邮箱输入框，确认页面已加载

步骤2：输入邮箱
- 目标：`input[type='email']`
- 操作：input
- 说明：引导用户在邮箱框中输入邮箱地址

步骤3：设置密码
- 目标：`input[type='password']`
- 操作：input
- 说明：引导用户设置密码

请根据我提供的任务信息，生成完整的 JSON 文件。
```

---

## 使用生成的 JSON 文件

生成 JSON 文件后，你有两种方式导入到 WebGuide APP 中：

### 方式一：从本地文件导入

1. 将 AI 生成的 JSON 内容保存为 `.json` 文件（如 `my_task.json`）
2. 将文件传输到手机存储
3. 打开 WebGuide APP，点击首页右上角的下载图标
4. 选择"从本地文件导入"，选择你的 JSON 文件

### 方式二：从 URL 导入

1. 将 JSON 文件上传到一个可访问的 URL（如 GitHub Raw、Gist、个人服务器等）
2. 打开 WebGuide APP，点击首页右上角的下载图标
3. 选择"从 URL 导入"，输入 JSON 文件的 URL
4. 点击"导入"

## 任务 JSON 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 唯一标识，英文小写+下划线，如 `github_signup` |
| `name` | string | 是 | 任务名称，显示在列表中 |
| `description` | string | 是 | 任务描述，显示在详情页 |
| `category` | string | 是 | 分类：`signup`、`shopping`、`social`、`tools`、`development`、`other` |
| `difficulty` | string | 是 | 难度：`easy`、`medium`、`hard` |
| `estimatedTime` | int | 是 | 预计完成时间（分钟） |
| `targetUrl` | string | 是 | 引导开始时加载的网页 URL |
| `icon` | string | 是 | Emoji 图标，如 `🐙`、`🛒` |
| `tags` | array | 是 | 标签数组，用于搜索 |
| `version` | string | 是 | 版本号，如 `1.0.0` |
| `author` | string | 是 | 作者名称 |
| `steps` | array | 是 | 步骤数组，至少包含一个步骤 |

### 步骤字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 步骤唯一标识 |
| `order` | int | 是 | 步骤顺序，从 1 开始 |
| `title` | string | 是 | 步骤标题，显示在引导卡片上 |
| `description` | string | 是 | 步骤详细描述 |
| `target.selector` | string | 是 | CSS 选择器，用于定位网页元素 |
| `target.tag` | string | 否 | HTML 标签名，辅助验证 |
| `target.attributes` | object | 否 | 元素属性，辅助定位 |
| `target.waitTimeout` | int | 是 | 等待元素出现的超时时间（毫秒） |
| `action` | string | 是 | 操作类型：`click`、`input`、`wait` |
| `validation` | string | 是 | 验证方式：`elementAppeared`、`urlChange`、`manual` |
| `hint` | string | 否 | 提示信息，显示在引导卡片中 |
| `timeout` | int | 是 | 步骤整体超时时间（毫秒） |

## 内置任务

当前内置以下引导任务：

| 任务 | 分类 | 难度 | 预计时间 |
|------|------|------|----------|
| GitHub 注册引导 | signup | medium | 15 分钟 |
| Gitee 注册引导 | signup | easy | 10 分钟 |

## 开发

```bash
# 克隆项目
git clone https://github.com/weijia/webguide.git
cd webguide

# 安装依赖
flutter pub get

# 运行
flutter run

# 构建 APK
flutter build apk --release
```

## 许可证

MIT License
