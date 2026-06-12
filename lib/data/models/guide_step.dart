import 'package:freezed_annotation/freezed_annotation.dart';

part 'guide_step.freezed.dart';
part 'guide_step.g.dart';

/// 引导步骤数据模型
/// 定义引导流程中的每一个操作步骤
@freezed
class GuideStep with _$GuideStep {
  const factory GuideStep({
    /// 步骤唯一标识
    required String id,

    /// 步骤序号（从 1 开始）
    required int order,

    /// 步骤标题
    required String title,

    /// 步骤详细描述
    required String description,

    /// 目标元素信息
    required StepTarget target,

    /// 用户需要执行的操作
    @Default(StepAction.click) StepAction action,

    /// 步骤验证方式
    @Default(StepValidation.auto) StepValidation validation,

    /// 步骤提示文本（可选）
    String? hint,

    /// 步骤提示截图 URL（可选）
    String? screenshotUrl,

    /// 步骤完成后的等待时间（毫秒）
    @Default(1000) int waitAfterComplete,

    /// 是否为可选步骤
    @Default(false) bool isOptional,

    /// 超时时间（毫秒），0 表示无超时
    @Default(30000) int timeout,
  }) = _GuideStep;

  /// 从 JSON 创建 GuideStep 实例
  factory GuideStep.fromJson(Map<String, dynamic> json) => _$GuideStepFromJson(json);
}

/// 步骤目标元素定义
/// 描述步骤需要定位的网页元素
@freezed
class StepTarget with _$StepTarget {
  const factory StepTarget({
    /// CSS 选择器（优先级最高）
    String? selector,

    /// 目标元素的文本内容（用于文本匹配）
    String? text,

    /// XPath 表达式
    String? xpath,

    /// 相对定位描述（如 "登录按钮旁边"）
    String? relative,

    /// iframe 选择器（如果目标在 iframe 内）
    String? iframeSelector,

    /// 期望的元素标签类型
    String? tag,

    /// 期望的元素属性
    Map<String, String>? attributes,

    /// 期望的元素类名
    List<String>? classNames,

    /// 是否需要等待元素出现
    @Default(true) bool waitForElement,

    /// 元素出现等待超时（毫秒）
    @Default(10000) int waitTimeout,
  }) = _StepTarget;

  /// 从 JSON 创建 StepTarget 实例
  factory StepTarget.fromJson(Map<String, dynamic> json) => _$StepTargetFromJson(json);
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
