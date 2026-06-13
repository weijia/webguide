import 'dart:ui';

/// 网页元素信息实体
/// 描述 WebView 中检测到的网页元素的完整信息
class ElementInfo {
  /// 元素在 WebView 中的位置和尺寸
  final ElementRect rect;

  /// CSS 选择器
  final String? selector;

  /// XPath 表达式
  final String? xpath;

  /// 元素标签名
  final String? tag;

  /// 元素文本内容
  final String? text;

  /// 元素类名列表
  final List<String>? classNames;

  /// 元素 ID
  final String? elementId;

  /// 元素属性映射
  final Map<String, String>? attributes;

  /// 元素类型（input, button, link, text 等）
  final String? type;

  /// 是否可见
  final bool isVisible;

  /// 是否可交互
  final bool isInteractive;

  /// 是否在 iframe 内
  final bool isInIframe;

  /// iframe 选择器（如果在 iframe 内）
  final String? iframeSelector;

  /// 元素匹配策略（selector, text, xpath, relative）
  final String? matchStrategy;

  /// 匹配置信度（0.0 - 1.0）
  final double matchConfidence;

  const ElementInfo({
    required this.rect,
    this.selector,
    this.xpath,
    this.tag,
    this.text,
    this.classNames,
    this.elementId,
    this.attributes,
    this.type,
    this.isVisible = true,
    this.isInteractive = true,
    this.isInIframe = false,
    this.iframeSelector,
    this.matchStrategy,
    this.matchConfidence = 1.0,
  });

  /// 从 JSON 创建 ElementInfo
  factory ElementInfo.fromJson(Map<String, dynamic> json) {
    return ElementInfo(
      rect: ElementRect.fromJson(json['rect'] as Map<String, dynamic>? ?? {}),
      selector: json['selector'] as String?,
      xpath: json['xpath'] as String?,
      tag: json['tag'] as String?,
      text: json['text'] as String?,
      classNames: (json['classNames'] as List<dynamic>?)?.cast<String>(),
      elementId: json['id'] as String?,
      attributes: (json['attributes'] as Map<String, dynamic>?)?.cast<String, String>(),
      type: json['type'] as String?,
      isVisible: json['isVisible'] as bool? ?? true,
      isInteractive: json['isInteractive'] as bool? ?? true,
      isInIframe: json['isInIframe'] as bool? ?? false,
      iframeSelector: json['iframeSelector'] as String?,
      matchStrategy: json['matchStrategy'] as String?,
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'rect': rect.toJson(),
      'selector': selector,
      'xpath': xpath,
      'tag': tag,
      'text': text,
      'classNames': classNames,
      'id': elementId,
      'attributes': attributes,
      'type': type,
      'isVisible': isVisible,
      'isInteractive': isInteractive,
      'isInIframe': isInIframe,
      'iframeSelector': iframeSelector,
      'matchStrategy': matchStrategy,
      'matchConfidence': matchConfidence,
    };
  }

  /// 创建副本
  ElementInfo copyWith({
    ElementRect? rect,
    String? selector,
    String? xpath,
    String? tag,
    String? text,
    List<String>? classNames,
    String? elementId,
    Map<String, String>? attributes,
    String? type,
    bool? isVisible,
    bool? isInteractive,
    bool? isInIframe,
    String? iframeSelector,
    String? matchStrategy,
    double? matchConfidence,
  }) {
    return ElementInfo(
      rect: rect ?? this.rect,
      selector: selector ?? this.selector,
      xpath: xpath ?? this.xpath,
      tag: tag ?? this.tag,
      text: text ?? this.text,
      classNames: classNames ?? this.classNames,
      elementId: elementId ?? this.elementId,
      attributes: attributes ?? this.attributes,
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
      isInteractive: isInteractive ?? this.isInteractive,
      isInIframe: isInIframe ?? this.isInIframe,
      iframeSelector: iframeSelector ?? this.iframeSelector,
      matchStrategy: matchStrategy ?? this.matchStrategy,
      matchConfidence: matchConfidence ?? this.matchConfidence,
    );
  }

  /// 获取元素的唯一标识字符串
  String get uniqueKey {
    if (selector != null && selector!.isNotEmpty) return 'sel:$selector';
    if (elementId != null && elementId!.isNotEmpty) return 'id:$elementId';
    if (xpath != null && xpath!.isNotEmpty) return 'xpath:$xpath';
    return 'text:${text ?? ''}';
  }

  /// 判断元素是否有效（有位置信息）
  bool get isValid => rect.width > 0 && rect.height > 0;

  /// 判断元素是否在屏幕内
  bool get isOnScreen =>
      rect.left >= 0 && rect.top >= 0 && rect.right > 0 && rect.bottom > 0;

  @override
  String toString() {
    return 'ElementInfo(tag: $tag, selector: $selector, text: ${text?.substring(0, text!.length > 30 ? 30 : text!.length)}, rect: $rect)';
  }
}

/// 元素位置和尺寸
class ElementRect {
  /// 左边距（相对于 WebView）
  final double left;

  /// 上边距（相对于 WebView）
  final double top;

  /// 右边距（相对于 WebView）
  final double right;

  /// 下边距（相对于 WebView）
  final double bottom;

  /// 宽度
  double get width => right - left;

  /// 高度
  double get height => bottom - top;

  /// 中心 X 坐标
  double get centerX => left + width / 2;

  /// 中心 Y 坐标
  double get centerY => top + height / 2;

  const ElementRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// 从 JSON 创建 ElementRect
  factory ElementRect.fromJson(Map<String, dynamic> json) {
    return ElementRect(
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      top: (json['top'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  /// 转换为 Rect 对象
  Rect toRect() => Rect.fromPoints(Offset(left, top), Offset(right, bottom));

  /// 创建副本
  ElementRect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return ElementRect(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  /// 判断两个矩形是否相交
  bool intersects(ElementRect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }

  /// 判断点是否在矩形内
  bool containsPoint(double x, double y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  /// 获取矩形面积
  double get area => width * height;

  @override
  String toString() => 'Rect($left, $top, $right, $bottom)';
}
