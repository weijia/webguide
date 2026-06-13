/// 引导错误类型定义
/// 封装引导流程中可能出现的各种错误
class GuideError {
  /// 错误类型
  final GuideErrorType type;

  /// 错误消息
  final String message;

  /// 错误详情
  final String? details;

  /// 关联的步骤索引（如果有）
  final int? stepIndex;

  /// 关联的元素信息（如果有）
  final String? elementSelector;

  /// 原始异常（用于调试）
  final Object? originalError;

  /// 堆栈跟踪（用于调试）
  final StackTrace? stackTrace;

  /// 时间戳
  final DateTime timestamp;

  GuideError({
    required this.type,
    required this.message,
    this.details,
    this.stepIndex,
    this.elementSelector,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 创建元素未找到错误
  factory GuideError.elementNotFound({
    String? selector,
    int? stepIndex,
    String? details,
  }) {
    return GuideError(
      type: GuideErrorType.elementNotFound,
      message: '无法找到目标元素',
      details: details ?? (selector != null ? '选择器: $selector' : null),
      stepIndex: stepIndex,
      elementSelector: selector,
    );
  }

  /// 创建元素定位超时错误
  factory GuideError.elementTimeout({
    String? selector,
    int? stepIndex,
    int? timeoutMs,
  }) {
    return GuideError(
      type: GuideErrorType.elementTimeout,
      message: '元素定位超时',
      details: timeoutMs != null ? '超时时间: ${timeoutMs}ms' : null,
      stepIndex: stepIndex,
      elementSelector: selector,
    );
  }

  /// 创建页面加载错误
  factory GuideError.pageLoadFailed({
    required String url,
    int? statusCode,
    String? details,
  }) {
    return GuideError(
      type: GuideErrorType.pageLoadFailed,
      message: '页面加载失败',
      details: 'URL: $url${statusCode != null ? ', 状态码: $statusCode' : ''}',
    );
  }

  /// 创建 JS Bridge 通信错误
  factory GuideError.jsBridgeError({
    required String message,
    String? details,
  }) {
    return GuideError(
      type: GuideErrorType.jsBridgeError,
      message: 'JS Bridge 通信错误: $message',
      details: details,
    );
  }

  /// 创建步骤验证失败错误
  factory GuideError.validationFailed({
    required int stepIndex,
    String? expected,
    String? actual,
  }) {
    return GuideError(
      type: GuideErrorType.validationFailed,
      message: '步骤验证失败',
      details: '期望: $expected, 实际: $actual',
      stepIndex: stepIndex,
    );
  }

  /// 创建网络错误
  factory GuideError.networkError({
    required String message,
    String? details,
  }) {
    return GuideError(
      type: GuideErrorType.networkError,
      message: '网络错误: $message',
      details: details,
    );
  }

  /// 创建用户取消错误
  factory GuideError.userCancelled({int? stepIndex}) {
    return GuideError(
      type: GuideErrorType.userCancelled,
      message: '用户取消了引导',
      stepIndex: stepIndex,
    );
  }

  /// 创建未知错误
  factory GuideError.unknown({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return GuideError(
      type: GuideErrorType.unknown,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 判断错误是否可恢复
  bool get isRecoverable {
    switch (type) {
      case GuideErrorType.elementNotFound:
      case GuideErrorType.elementTimeout:
      case GuideErrorType.validationFailed:
        return true;
      case GuideErrorType.pageLoadFailed:
      case GuideErrorType.jsBridgeError:
      case GuideErrorType.networkError:
        return true;
      case GuideErrorType.userCancelled:
        return false;
      case GuideErrorType.unknown:
        return false;
    }
  }

  /// 判断错误是否可重试
  bool get isRetryable {
    switch (type) {
      case GuideErrorType.elementNotFound:
      case GuideErrorType.elementTimeout:
      case GuideErrorType.networkError:
      case GuideErrorType.pageLoadFailed:
        return true;
      default:
        return false;
    }
  }

  /// 获取用户友好的错误提示
  String get userFriendlyMessage {
    switch (type) {
      case GuideErrorType.elementNotFound:
        return '找不到目标元素，请确认页面已正确加载';
      case GuideErrorType.elementTimeout:
        return '元素加载超时，请检查网络连接后重试';
      case GuideErrorType.pageLoadFailed:
        return '页面加载失败，请检查网络连接';
      case GuideErrorType.jsBridgeError:
        return '通信异常，请刷新页面后重试';
      case GuideErrorType.validationFailed:
        return '操作验证失败，请重新尝试';
      case GuideErrorType.networkError:
        return '网络连接异常，请检查网络设置';
      case GuideErrorType.userCancelled:
        return '引导已取消';
      case GuideErrorType.unknown:
        return '发生未知错误，请稍后重试';
    }
  }

  @override
  String toString() {
    return 'GuideError(type: $type, message: $message, details: $details)';
  }
}

/// 引导错误类型枚举
enum GuideErrorType {
  /// 目标元素未找到
  elementNotFound,

  /// 元素定位超时
  elementTimeout,

  /// 页面加载失败
  pageLoadFailed,

  /// JS Bridge 通信错误
  jsBridgeError,

  /// 步骤验证失败
  validationFailed,

  /// 网络错误
  networkError,

  /// 用户取消
  userCancelled,

  /// 未知错误
  unknown,
}
