# WebGuide - 网页引导助手

一个帮助用户逐步完成网页操作的智能引导工具。支持从本地文件、URL 或直接粘贴 JSON 导入自定义引导任务。

## 创建自定义引导任务

你可以使用以下提示词，发送给任意 AI（如 ChatGPT、Claude、Gemini 等），让它帮你生成符合 WebGuide 格式的引导任务 JSON 文件。

---

## 提示词一：根据网页生成引导任务（推荐）

> 这个提示词会让 AI 先分析网页结构，再生成精确的引导 JSON。适用于你能提供目标网页 URL 或截图的场景。

```
你是一个专业的 WebGuide 引导任务生成器。请根据我提供的网页信息，生成一个完整的 WebGuide 引导任务 JSON 文件。

## 你的工作流程

### 第一步：分析网页结构

根据我提供的网页信息（URL、截图描述、或 HTML 片段），分析以下内容：
1. 网页的主要功能和用途
2. 用户完成核心操作需要经过哪些步骤
3. 每个步骤涉及哪些交互元素（输入框、按钮、链接、复选框等）
4. 这些元素的 HTML 标签、类型属性、文本内容

### 第二步：规划引导步骤

将用户操作流程拆分为 5-10 个清晰的步骤，每个步骤聚焦一个操作：
- 步骤顺序应与用户实际操作流程完全一致
- 第一步通常是确认页面已加载（click 第一个输入框）
- 中间步骤依次引导用户完成每个表单字段或操作
- 最后一步是确认操作完成（等待页面跳转或成功提示出现）
- 如果流程中需要用户离开 APP 操作（如查收邮件、短信验证码），用 `wait` + `manual` 验证

### 第三步：生成 JSON

按照下面的 JSON 格式输出完整的引导任务文件。

## 我提供的网页信息

- **网页 URL**：【在此粘贴网页地址，如 https://signup.example.com】
- **网页截图/描述**：【描述网页上能看到的内容，或粘贴关键 HTML 片段】
- **我要引导用户完成的操作**：【描述目标操作，如"注册一个新账号"、"发布一篇文章"】
- **任务名称**：【如"Example 注册引导"】
- **难度**：【easy / medium / hard】
- **分类**：【signup / shopping / social / tools / development / other】

## JSON 输出格式

严格按照以下格式输出，每个字段都必须存在，值类型必须匹配。下面是一个带真实值的完整模板：

```json
{
  "id": "bilibili_signup",
  "name": "B站注册引导",
  "description": "手把手引导你在哔哩哔哩上完成账号注册，从打开注册页面到完成手机验证的全流程。",
  "category": "signup",
  "difficulty": "easy",
  "estimatedTime": 10,
  "targetUrl": "https://passport.bilibili.com/register",
  "icon": "📺",
  "tags": ["B站", "bilibili", "注册", "视频"],
  "version": "1.0.0",
  "author": "WebGuide",
  "downloadCount": 0,
  "rating": 0,
  "createdAt": "2026-06-14T00:00:00Z",
  "updatedAt": "2026-06-14T00:00:00Z",
  "steps": [
    {
      "id": "step_1",
      "order": 1,
      "title": "确认注册页面已加载",
      "description": "首先打开B站的注册页面，确认页面已加载完成，可以看到手机号输入框。",
      "target": {
        "selector": "input[type='tel']",
        "tag": "input",
        "text": "请输入手机号",
        "attributes": {"type": "tel"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "elementAppeared",
      "hint": "如果页面没有自动跳转，请手动访问 passport.bilibili.com/register",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_2",
      "order": 2,
      "title": "输入手机号",
      "description": "在手机号输入框中输入你的手机号码，B站会向该手机号发送验证码。",
      "target": {
        "selector": "input[type='tel']",
        "tag": "input",
        "text": "请输入手机号",
        "attributes": {"type": "tel"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "请输入真实的手机号码，后续需要接收验证码",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_3",
      "order": 3,
      "title": "点击发送验证码",
      "description": "点击「发送验证码」按钮，B站会向你输入的手机号发送一条包含6位数字验证码的短信。",
      "target": {
        "selector": "button[type='button']",
        "tag": "button",
        "text": "发送验证码",
        "attributes": {"type": "button"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "elementAppeared",
      "hint": "如果60秒内未收到，可以点击重新发送",
      "waitAfterComplete": 3000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_4",
      "order": 4,
      "title": "输入验证码",
      "description": "查看手机短信中的6位验证码，在验证码输入框中依次输入。",
      "target": {
        "selector": "input[type='text']",
        "tag": "input",
        "text": "请输入验证码",
        "attributes": {"type": "text"},
        "waitForElement": true,
        "waitTimeout": 120000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "验证码是6位数字，注意区分大小写",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 180000
    },
    {
      "id": "step_5",
      "order": 5,
      "title": "设置密码",
      "description": "为你的B站账号设置一个密码。密码需要8-16位，包含字母和数字。",
      "target": {
        "selector": "input[type='password']",
        "tag": "input",
        "text": "设置密码",
        "attributes": {"type": "password"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "建议使用包含大小写字母和数字的强密码",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_6",
      "order": 6,
      "title": "点击注册按钮",
      "description": "确认所有信息填写正确后，点击「注册」按钮完成账号创建。",
      "target": {
        "selector": "button[type='button']",
        "tag": "button",
        "text": "注册",
        "attributes": {"type": "button"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "urlChange",
      "hint": "如果提示手机号已注册，请尝试其他手机号或直接登录",
      "waitAfterComplete": 3000,
      "isOptional": false,
      "timeout": 60000
    }
  ]
}
```

### 字段值说明

| 字段 | 值类型 | 示例值 | 说明 |
|------|--------|--------|------|
| `id` | string | `"bilibili_signup"` | 英文小写+下划线，唯一标识 |
| `name` | string | `"B站注册引导"` | 显示在任务列表的名称 |
| `description` | string | `"手把手引导你..."` | 一两句话描述 |
| `category` | string | `"signup"` | 必须是：signup / shopping / social / tools / development / other |
| `difficulty` | string | `"easy"` | 必须是：easy / medium / hard |
| `estimatedTime` | number | `10` | 预计完成分钟数（整数） |
| `targetUrl` | string | `"https://..."` | 引导开始时加载的网页地址 |
| `icon` | string | `"📺"` | 一个 emoji 字符 |
| `tags` | array | `["B站", "注册"]` | 3-5个搜索标签 |
| `version` | string | `"1.0.0"` | 语义化版本号 |
| `author` | string | `"WebGuide"` | 作者名称 |
| `downloadCount` | number | `0` | 固定填 0 |
| `rating` | number | `0` | 固定填 0 |
| `createdAt` | string | `"2026-06-14T00:00:00Z"` | ISO 8601 格式时间 |
| `updatedAt` | string | `"2026-06-14T00:00:00Z"` | ISO 8601 格式时间 |
| `steps` | array | `[{...}, ...]` | 步骤数组，至少1个 |

### 步骤字段值说明

| 字段 | 值类型 | 示例值 | 说明 |
|------|--------|--------|------|
| `id` | string | `"step_1"` | 步骤唯一标识 |
| `order` | number | `1` | 步骤顺序，从1开始递增 |
| `title` | string | `"输入手机号"` | 简短标题，显示在引导卡片上 |
| `description` | string | `"在手机号输入框中..."` | 详细描述，面向普通用户 |
| `target.selector` | string | `"input[type='tel']"` | CSS选择器，用于定位网页元素 |
| `target.tag` | string | `"input"` | HTML标签名 |
| `target.text` | string | `"请输入手机号"` | 元素的可见文本，用于辅助定位 |
| `target.attributes` | object | `{"type": "tel"}` | 元素的HTML属性，用于辅助定位 |
| `target.waitForElement` | boolean | `true` | 固定填 true |
| `target.waitTimeout` | number | `30000` | 等待元素出现的超时（毫秒） |
| `action` | string | `"input"` | 必须是：click / input / wait |
| `validation` | string | `"elementAppeared"` | 必须是：elementAppeared / urlChange / manual |
| `hint` | string | `"请输入真实手机号"` | 给用户的提示信息 |
| `waitAfterComplete` | number | `2000` | 步骤完成后等待时间（毫秒） |
| `isOptional` | boolean | `false` | 固定填 false |
| `timeout` | number | `60000` | 步骤整体超时（毫秒） |

## CSS 选择器规则（非常重要）

选择器用于在网页中定位元素，必须准确且稳定：

1. **优先使用基于 type 的选择器**（最稳定）：
   - `input[type='email']` — 邮箱输入框
   - `input[type='password']` — 密码输入框
   - `input[type='text']` — 文本输入框
   - `input[type='tel']` — 电话输入框
   - `input[type='number']` — 数字输入框
   - `input[type='checkbox']` — 复选框
   - `button[type='submit']` — 提交按钮
   - `button[type='button']` — 普通按钮
   - `select` — 下拉选择框

2. **可以使用基于文本内容的选择器**（较稳定）：
   - `button:text('注册')` — 包含"注册"文本的按钮
   - `a:text('忘记密码')` — 包含"忘记密码"文本的链接

3. **可以使用基于 placeholder 的选择器**（较稳定）：
   - `input[placeholder*='邮箱']` — placeholder 包含"邮箱"的输入框

4. **避免使用**（不稳定，容易失效）：
   - `#id` — 动态生成的 ID 每次可能不同
   - `.class-name` — CSS 类名可能被压缩或自动生成
   - `input[name='xxx']` — name 属性可能变化

5. **当同一页面有多个相同 type 的元素时**，用 `text` 或 `attributes` 辅助区分：
   - 第一个密码框：`input[type='password']` + text: "Password"
   - 确认密码框：`input[type='password']` + text: "Confirm"

## action 操作类型

| 类型 | 用途 | 适用元素 |
|------|------|----------|
| `click` | 点击/聚焦元素 | 按钮、链接、输入框（聚焦）、复选框 |
| `input` | 在输入框中输入内容 | text、email、password、tel 等输入框 |
| `wait` | 等待页面变化或用户手动操作 | 需要用户离开 APP 的场景（查邮件等） |

## validation 验证方式

| 类型 | 用途 | 适用场景 |
|------|------|----------|
| `elementAppeared` | 等待元素出现在页面上 | 页面加载、表单字段出现 |
| `urlChange` | 等待页面 URL 发生变化 | 点击提交按钮后页面跳转 |
| `manual` | 需要用户手动确认完成 | 查收邮件验证码、短信验证 |

## 超时时间设置

| 场景 | waitTimeout | timeout |
|------|-------------|---------|
| 普通步骤（页面元素加载） | 30000（30秒） | 60000（60秒） |
| 需要用户离开 APP（查邮件/短信） | 120000（2分钟） | 180000（3分钟） |
| 网页可能加载较慢 | 60000（60秒） | 120000（2分钟） |

## 完整示例

以下是一个 GitHub 注册引导的完整 JSON，供你参考格式和写法：

```json
{
  "id": "github_signup",
  "name": "GitHub 注册引导",
  "description": "手把手引导你在 GitHub 上完成账号注册，从访问注册页面到完成邮箱验证的全流程。",
  "category": "signup",
  "difficulty": "medium",
  "estimatedTime": 15,
  "targetUrl": "https://github.com/signup",
  "icon": "🐙",
  "tags": ["GitHub", "注册", "开发工具"],
  "version": "1.0.0",
  "author": "WebGuide",
  "downloadCount": 0,
  "rating": 0,
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z",
  "steps": [
    {
      "id": "step_1",
      "order": 1,
      "title": "访问注册页面",
      "description": "打开 GitHub 的注册页面，页面会显示邮箱输入框。",
      "target": {
        "selector": "input[type='email']",
        "tag": "input",
        "text": "Email",
        "attributes": {"type": "email"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "elementAppeared",
      "hint": "如果页面没有自动跳转，请手动访问 github.com/signup",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_2",
      "order": 2,
      "title": "输入邮箱地址",
      "description": "在邮箱输入框中输入你想用来注册 GitHub 的邮箱地址。",
      "target": {
        "selector": "input[type='email']",
        "tag": "input",
        "text": "Email",
        "attributes": {"type": "email"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "input",
      "validation": "urlChange",
      "hint": "请确保输入有效的邮箱地址",
      "waitAfterComplete": 3000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_3",
      "order": 3,
      "title": "设置密码",
      "description": "为你的 GitHub 账号设置一个安全的密码。",
      "target": {
        "selector": "input[type='password']",
        "tag": "input",
        "text": "Password",
        "attributes": {"type": "password"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "密码至少 8 个字符，建议包含字母和数字",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_4",
      "order": 4,
      "title": "输入用户名",
      "description": "选择一个唯一的 GitHub 用户名。",
      "target": {
        "selector": "input[type='text']",
        "tag": "input",
        "text": "Username",
        "attributes": {"type": "text"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "用户名将作为你的个人主页地址",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_5",
      "order": 5,
      "title": "验证邮箱",
      "description": "GitHub 会向你注册的邮箱发送验证码，请查收邮件并输入验证码。",
      "target": {
        "selector": "input[type='text']",
        "tag": "input",
        "text": "Verify",
        "attributes": {"type": "text"},
        "waitForElement": true,
        "waitTimeout": 120000
      },
      "action": "wait",
      "validation": "manual",
      "hint": "验证码通常在几秒内发送，如果没有收到请检查垃圾邮件",
      "waitAfterComplete": 3000,
      "isOptional": false,
      "timeout": 180000
    },
    {
      "id": "step_6",
      "order": 6,
      "title": "点击验证按钮",
      "description": "输入验证码后，点击验证按钮完成邮箱验证。",
      "target": {
        "selector": "button[type='submit']",
        "tag": "button",
        "text": "Verify",
        "attributes": {"type": "submit"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "urlChange",
      "hint": "如果验证码过期，可以点击重新发送",
      "waitAfterComplete": 3000,
      "isOptional": false,
      "timeout": 60000
    }
  ]
}
```

## 注意事项

1. 每个步骤的 `target.selector` 必须能在页面中唯一定位到目标元素
2. 如果同一个页面有多个相同 type 的输入框（如两个 `input[type='password']`），需要通过 `text` 字段或 `attributes` 来区分
3. 步骤描述使用中文，语气友好，面向不熟悉技术的普通用户
4. `hint` 字段提供实用的小贴士，帮助用户顺利完成操作
5. 只输出 JSON，不要输出任何其他解释文字
```

---

## 提示词二：根据任务描述生成引导任务（简化版）

> 如果你已经知道引导流程，只需要 AI 帮你生成 JSON 格式，使用这个简化版提示词。

```
请帮我生成一个 WebGuide 引导任务的 JSON 文件。

WebGuide 是一个 Flutter APP，通过 WebView 加载网页，逐步引导用户完成操作。

## 任务信息

- **任务名称**：【填写任务名称】
- **目标网站**：【填写目标网址】
- **任务描述**：【简要描述】
- **难度**：【easy / medium / hard】
- **预计时间**：【分钟数】
- **分类**：【signup / shopping / social / tools / development / other】
- **图标 emoji**：【如 🎬、🛒、💬】

## 引导步骤

请描述用户需要完成的每一步操作。

## JSON 格式要求

严格按照以下格式输出（这是一个 B站注册的完整示例，请参照此格式生成）：

```json
{
  "id": "bilibili_signup",
  "name": "B站注册引导",
  "description": "手把手引导你在哔哩哔哩上完成账号注册，从打开注册页面到完成手机验证的全流程。",
  "category": "signup",
  "difficulty": "easy",
  "estimatedTime": 10,
  "targetUrl": "https://passport.bilibili.com/register",
  "icon": "📺",
  "tags": ["B站", "bilibili", "注册", "视频"],
  "version": "1.0.0",
  "author": "WebGuide",
  "downloadCount": 0,
  "rating": 0,
  "createdAt": "2026-06-14T00:00:00Z",
  "updatedAt": "2026-06-14T00:00:00Z",
  "steps": [
    {
      "id": "step_1",
      "order": 1,
      "title": "确认注册页面已加载",
      "description": "首先打开B站的注册页面，确认页面已加载完成，可以看到手机号输入框。",
      "target": {
        "selector": "input[type='tel']",
        "tag": "input",
        "text": "请输入手机号",
        "attributes": {"type": "tel"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "elementAppeared",
      "hint": "如果页面没有自动跳转，请手动访问 passport.bilibili.com/register",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_2",
      "order": 2,
      "title": "输入手机号",
      "description": "在手机号输入框中输入你的手机号码，B站会向该手机号发送验证码。",
      "target": {
        "selector": "input[type='tel']",
        "tag": "input",
        "text": "请输入手机号",
        "attributes": {"type": "tel"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "请输入真实的手机号码，后续需要接收验证码",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_3",
      "order": 3,
      "title": "点击发送验证码",
      "description": "点击「发送验证码」按钮，B站会向你输入的手机号发送一条包含6位数字验证码的短信。",
      "target": {
        "selector": "button[type='button']",
        "tag": "button",
        "text": "发送验证码",
        "attributes": {"type": "button"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "elementAppeared",
      "hint": "如果60秒内未收到，可以点击重新发送",
      "waitAfterComplete": 3000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_4",
      "order": 4,
      "title": "输入验证码",
      "description": "查看手机短信中的6位验证码，在验证码输入框中依次输入。",
      "target": {
        "selector": "input[type='text']",
        "tag": "input",
        "text": "请输入验证码",
        "attributes": {"type": "text"},
        "waitForElement": true,
        "waitTimeout": 120000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "验证码是6位数字，注意区分大小写",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 180000
    },
    {
      "id": "step_5",
      "order": 5,
      "title": "设置密码",
      "description": "为你的B站账号设置一个密码。密码需要8-16位，包含字母和数字。",
      "target": {
        "selector": "input[type='password']",
        "tag": "input",
        "text": "设置密码",
        "attributes": {"type": "password"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "input",
      "validation": "elementAppeared",
      "hint": "建议使用包含大小写字母和数字的强密码",
      "waitAfterComplete": 2000,
      "isOptional": false,
      "timeout": 60000
    },
    {
      "id": "step_6",
      "order": 6,
      "title": "点击注册按钮",
      "description": "确认所有信息填写正确后，点击「注册」按钮完成账号创建。",
      "target": {
        "selector": "button[type='button']",
        "tag": "button",
        "text": "注册",
        "attributes": {"type": "button"},
        "waitForElement": true,
        "waitTimeout": 30000
      },
      "action": "click",
      "validation": "urlChange",
      "hint": "如果提示手机号已注册，请尝试其他手机号或直接登录",
      "waitAfterComplete": 3000,
      "isOptional": false,
      "timeout": 60000
    }
  ]
}
```

规则：CSS 选择器优先用 `input[type='xxx']`、`button[type='submit']` 等类型选择器；waitTimeout 普通步骤 30000ms，需离开 APP 的步骤 120000ms；只输出 JSON。
```

---

## 使用生成的 JSON 文件

生成 JSON 后，通过以下任一方式导入到 WebGuide APP：

| 方式 | 操作 |
|------|------|
| **直接粘贴** | 打开 APP > 首页右上角下载图标 > "直接粘贴 JSON" > 粘贴 > 导入 |
| **本地文件** | 保存为 `.json` 文件 > 传到手机 > APP 中选择"从本地文件导入" |
| **URL 导入** | 上传 JSON 到任意可访问的 URL > APP 中输入 URL > 导入 |

## 任务 JSON 字段参考

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 唯一标识，英文小写+下划线 |
| `name` | string | 是 | 任务名称 |
| `description` | string | 是 | 任务描述 |
| `category` | string | 是 | signup / shopping / social / tools / development / other |
| `difficulty` | string | 是 | easy / medium / hard |
| `estimatedTime` | int | 是 | 预计分钟数 |
| `targetUrl` | string | 是 | 引导起始 URL |
| `icon` | string | 是 | Emoji 图标 |
| `tags` | array | 是 | 搜索标签 |
| `steps` | array | 是 | 步骤数组（至少 1 个） |
| `steps[].action` | string | 是 | click / input / wait |
| `steps[].validation` | string | 是 | elementAppeared / urlChange / manual |
| `steps[].target.selector` | string | 是 | CSS 选择器 |

## 内置任务

| 任务 | 分类 | 难度 | 时间 |
|------|------|------|------|
| GitHub 注册引导 | signup | medium | 15 分钟 |
| Gitee 注册引导 | signup | easy | 10 分钟 |

## 开发

```bash
git clone https://github.com/weijia/webguide.git
cd webguide
flutter pub get
flutter run
flutter build apk --release
```

## 许可证

MIT License
