import 'dart:async';

import '../../data/models/guide_step.dart';
import '../../domain/entities/element_info.dart';

/// 叠加层渲染回调类型
/// 返回需要显示的高亮区域
typedef HighlightRectCallback = ElementInfo? Function();

/// 叠加层渲染状态
enum OverlayState {
  /// 空闲 - 无叠加层显示
  idle,

  /// 显示高亮框
  highlighting,

  /// 显示引导卡片
  showingCard,

  /// 显示扫描提示
  scanning,

  /// 完整引导模式（高亮 + 卡片 + 遮罩）
  guiding,
}

/// 叠加层渲染逻辑
/// 管理引导过程中的 UI 叠加层状态，包括高亮框、引导卡片、遮罩等
/// 注意：实际 UI 渲染由 Flutter Widget 完成，此类负责状态管理和通知
class OverlayRenderer {
  // ==================== 属性 ====================

  /// 当前叠加层状态
  OverlayState _state = OverlayState.idle;

  /// 当前高亮的元素
  ElementInfo? _highlightedElement;

  /// 当前显示的步骤
  GuideStep? _currentStep;

  /// 当前步骤索引
  int _stepIndex = 0;

  /// 总步骤数
  int _totalSteps = 0;

  /// 是否有下一步
  bool _hasNext = false;

  /// 是否有上一步
  bool _hasPrevious = false;

  /// 扫描提示消息
  String _scanningMessage = '';

  /// 遮罩透明度（0.0 - 1.0）
  double _maskOpacity = 0.6;

  /// 高亮区域内边距
  double _highlightPadding = 8.0;

  /// 状态变化回调
  void Function(OverlayState state)? onStateChanged;

  /// 高亮元素变化回调
  void Function(ElementInfo? element)? onHighlightChanged;

  /// 引导卡片数据变化回调
  void Function(GuideStep? step, int index, int total, bool hasNext, bool hasPrevious)?
      onCardChanged;

  /// 扫描提示变化回调
  void Function(String message)? onScanningHintChanged;

  /// 控制器用于通知 Flutter Widget 重建
  StreamController<OverlayState>? _stateController;

  /// 获取状态流（供 Widget 监听）
  Stream<OverlayState> get stateStream {
    _stateController ??= StreamController<OverlayState>.broadcast();
    return _stateController!.stream;
  }

  // ==================== Getter ====================

  /// 当前叠加层状态
  OverlayState get state => _state;

  /// 当前高亮元素
  ElementInfo? get highlightedElement => _highlightedElement;

  /// 当前步骤
  GuideStep? get currentStep => _currentStep;

  /// 步骤索引
  int get stepIndex => _stepIndex;

  /// 总步骤数
  int get totalSteps => _totalSteps;

  /// 是否有下一步
  bool get hasNext => _hasNext;

  /// 是否有上一步
  bool get hasPrevious => _hasPrevious;

  /// 扫描提示消息
  String get scanningMessage => _scanningMessage;

  /// 遮罩透明度
  double get maskOpacity => _maskOpacity;

  /// 高亮区域内边距
  double get highlightPadding => _highlightPadding;

  // ==================== 公共方法 ====================

  /// 显示高亮框
  void showHighlight(ElementInfo element) {
    _highlightedElement = element;
    _setState(OverlayState.highlighting);
    onHighlightChanged?.call(element);
  }

  /// 显示引导卡片
  void showGuideCard({
    required GuideStep step,
    required int stepIndex,
    required int totalSteps,
    required bool hasNext,
    required bool hasPrevious,
  }) {
    _currentStep = step;
    _stepIndex = stepIndex;
    _totalSteps = totalSteps;
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    _setState(OverlayState.showingCard);
    onCardChanged?.call(step, stepIndex, totalSteps, hasNext, hasPrevious);
  }

  /// 显示完整引导模式（高亮 + 卡片）
  void showGuidingMode({
    required ElementInfo element,
    required GuideStep step,
    required int stepIndex,
    required int totalSteps,
    required bool hasNext,
    required bool hasPrevious,
  }) {
    _highlightedElement = element;
    _currentStep = step;
    _stepIndex = stepIndex;
    _totalSteps = totalSteps;
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    _setState(OverlayState.guiding);
    onHighlightChanged?.call(element);
    onCardChanged?.call(step, stepIndex, totalSteps, hasNext, hasPrevious);
  }

  /// 显示扫描提示
  void showScanningHint({
    required String message,
    required GuideStep step,
  }) {
    _scanningMessage = message;
    _currentStep = step;
    _setState(OverlayState.scanning);
    onScanningHintChanged?.call(message);
  }

  /// 更新高亮元素位置（动画过渡）
  void updateHighlightPosition(ElementInfo newElement) {
    _highlightedElement = newElement;
    onHighlightChanged?.call(newElement);
  }

  /// 设置遮罩透明度
  void setMaskOpacity(double opacity) {
    _maskOpacity = opacity.clamp(0.0, 1.0);
  }

  /// 设置高亮区域内边距
  void setHighlightPadding(double padding) {
    _highlightPadding = padding;
  }

  /// 隐藏引导卡片（保留高亮）
  void hideCard() {
    _currentStep = null;
    if (_highlightedElement != null) {
      _setState(OverlayState.highlighting);
    } else {
      _setState(OverlayState.idle);
    }
    onCardChanged?.call(null, 0, 0, false, false);
  }

  /// 隐藏高亮框（保留卡片）
  void hideHighlight() {
    _highlightedElement = null;
    if (_currentStep != null) {
      _setState(OverlayState.showingCard);
    } else {
      _setState(OverlayState.idle);
    }
    onHighlightChanged?.call(null);
  }

  /// 清除所有叠加层
  void clearAll() {
    _highlightedElement = null;
    _currentStep = null;
    _scanningMessage = '';
    _setState(OverlayState.idle);
    onHighlightChanged?.call(null);
    onCardChanged?.call(null, 0, 0, false, false);
    onScanningHintChanged?.call('');
  }

  // ==================== 内部方法 ====================

  /// 更新状态并通知
  void _setState(OverlayState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(_state);
      _stateController?.add(_state);
    }
  }

  /// 释放资源
  void dispose() {
    _stateController?.close();
    _stateController = null;
  }
}
