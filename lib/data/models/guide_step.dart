/// 引导步骤数据模型
/// 手写不可变数据类，支持 JSON 序列化和 copyWith
class GuideStep {
  /// 步骤唯一标识
  final String id;

  /// 步骤序号（从 1 开始）
  final int order;

  /// 步骤标题
  final String title;

  /// 步骤详细描述
  final String description;

  /// 目标元素信息
  final StepTarget target;

  /// 用户需要执行的操作
  final StepAction action;

  /// 步骤验证方式
  final StepValidation validation;

  /// 步骤提示文本（可选）
  final String? hint;

  /// 步骤提示截图 URL（可选）
  final String? screenshotUrl;

  /// 步骤完成后的等待时间（毫秒）
  final int waitAfterComplete;

  /// 是否为可选步骤
  final bool isOptional;

  /// 超时时间（毫秒），0 表示无超时
  final int timeout;

  const GuideStep({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.target,
    this.action = StepAction.click,
    this.validation = StepValidation.auto,
    this.hint,
    this.screenshotUrl,
    this.waitAfterComplete = 1000,
    this.isOptional = false,
    this.timeout = 30000,
  });

  /// 从 JSON 创建 GuideStep 实例
  factory GuideStep.fromJson(Map<String, dynamic> json) {
    return GuideStep(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      target: StepTarget.fromJson(
          json['target'] as Map<String, dynamic>? ?? {}),
      action: json['action'] != null
          ? StepAction.values.firstWhere(
              (e) => e.name == json['action'],
              orElse: () => StepAction.click,
            )
          : StepAction.click,
      validation: json['validation'] != null
          ? StepValidation.values.firstWhere(
              (e) => e.name == json['validation'],
              orElse: () => StepValidation.auto,
            )
          : StepValidation.auto,
      hint: json['hint'] as String?,
      screenshotUrl: json['screenshotUrl'] as String?,
      waitAfterComplete: json['waitAfterComplete'] as int? ?? 1000,
      isOptional: json['isOptional'] as bool? ?? false,
      timeout: json['timeout'] as int? ?? 30000,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'title': title,
      'description': description,
      'target': target.toJson(),
      'action': action.name,
      'validation': validation.name,
      'hint': hint,
      'screenshotUrl': screenshotUrl,
      'waitAfterComplete': waitAfterComplete,
      'isOptional': isOptional,
      'timeout': timeout,
    };
  }

  /// 创建副本
  GuideStep copyWith({
    String? id,
    int? order,
    String? title,
    String? description,
    StepTarget? target,
    StepAction? action,
    StepValidation? validation,
    String? hint,
    String? screenshotUrl,
    int? waitAfterComplete,
    bool? isOptional,
    int? timeout,
  }) {
    return GuideStep(
      id: id ?? this.id,
      order: order ?? this.order,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      action: action ?? this.action,
      validation: validation ?? this.validation,
      hint: hint ?? this.hint,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      waitAfterComplete: waitAfterComplete ?? this.waitAfterComplete,
      isOptional: isOptional ?? this.isOptional,
      timeout: timeout ?? this.timeout,
    );
  }
}

/// 步骤目标元素定义
/// 描述步骤需要定位的网页元素
class StepTarget {
  /// CSS 选择器（优先级最高）
  final String? selector;

  /// 目标元素的文本内容（用于文本匹配）
  final String? text;

  /// XPath 表达式
  final String? xpath;

  /// 相对定位描述（如 "登录按钮旁边"）
  final String? relative;

  /// iframe 选择器（如果目标在 iframe 内）
  final String? iframeSelector;

  /// 期望的元素标签类型
  final String? tag;

  /// 期望的元素属性
  final Map<String, String>? attributes;

  /// 期望的元素类名
  final List<String>? classNames;

  /// 是否需要等待元素出现
  final bool waitForElement;

  /// 元素出现等待超时（毫秒）
  final int waitTimeout;

  const StepTarget({
    this.selector,
    this.text,
    this.xpath,
    this.relative,
    this.iframeSelector,
    this.tag,
    this.attributes,
    this.classNames,
    this.waitForElement = true,
    this.waitTimeout = 10000,
  });

  /// 从 JSON 创建 StepTarget 实例
  factory StepTarget.fromJson(Map<String, dynamic> json) {
    return StepTarget(
      selector: json['selector'] as String?,
      text: json['text'] as String?,
      xpath: json['xpath'] as String?,
      relative: json['relative'] as String?,
      iframeSelector: json['iframeSelector'] as String?,
      tag: json['tag'] as String?,
      attributes: (json['attributes'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      classNames: (json['classNames'] as List<dynamic>?)?.cast<String>(),
      waitForElement: json['waitForElement'] as bool? ?? true,
      waitTimeout: json['waitTimeout'] as int? ?? 10000,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'selector': selector,
      'text': text,
      'xpath': xpath,
      'relative': relative,
      'iframeSelector': iframeSelector,
      'tag': tag,
      'attributes': attributes,
      'classNames': classNames,
      'waitForElement': waitForElement,
      'waitTimeout': waitTimeout,
    };
  }

  /// 创建副本
  StepTarget copyWith({
    String? selector,
    String? text,
    String? xpath,
    String? relative,
    String? iframeSelector,
    String? tag,
    Map<String, String>? attributes,
    List<String>? classNames,
    bool? waitForElement,
    int? waitTimeout,
  }) {
    return StepTarget(
      selector: selector ?? this.selector,
      text: text ?? this.text,
      xpath: xpath ?? this.xpath,
      relative: relative ?? this.relative,
      iframeSelector: iframeSelector ?? this.iframeSelector,
      tag: tag ?? this.tag,
      attributes: attributes ?? this.attributes,
      classNames: classNames ?? this.classNames,
      waitForElement: waitForElement ?? this.waitForElement,
      waitTimeout: waitTimeout ?? this.waitTimeout,
    );
  }
}

/// 用户操作类型
enum StepAction {
  /// 点击元素
  click,

  /// 输入文本
  input,

  /// 选择选项
  select,

  /// 滚动到元素
  scroll,

  /// 等待页面加载
  wait,

  /// 勾选复选框
  check,

  /// 上传文件
  upload,

  /// 按键操作
  keyPress,

  /// 自定义操作
  custom,
}

/// 步骤验证方式
enum StepValidation {
  /// 自动验证（检测元素状态变化）
  auto,

  /// URL 变化验证
  urlChange,

  /// 元素出现验证
  elementAppeared,

  /// 元素消失验证
  elementDisappeared,

  /// 自定义 JS 验证脚本
  customJs,

  /// 手动确认（用户点击"完成"按钮）
  manual,

  /// 无需验证
  none,
}
