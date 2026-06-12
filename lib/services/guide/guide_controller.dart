import 'dart:async';

import '../../data/models/guide_step.dart';
import '../../data/models/guide_task.dart';
import '../../data/models/user_progress.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/entities/element_info.dart';
import '../../domain/entities/guide_error.dart';
import '../webview/webview_manager.dart';
import 'element_resolver.dart';
import 'overlay_renderer.dart';

/// 引导状态枚举
enum GuideState {
  /// 空闲状态 - 未开始或已结束
  idle,

  /// 加载中 - 正在初始化引导会话
  loading,

  /// 运行中 - 正在执行引导步骤
  running,

  /// 暂停 - 用户暂停了引导
  paused,

  /// 已完成 - 所有步骤执行完毕
  completed,

  /// 错误 - 发生了错误
  error,
}

/// 引导控制器
/// 核心状态机，管理引导流程的完整生命周期
/// 负责步骤推进、错误处理、状态通知
class GuideController {
  // ==================== 属性 ====================

  /// 当前引导任务
  GuideTask? _task;

  /// 当前步骤索引
  int _currentStepIndex = 0;

  /// 引导状态
  GuideState _state = GuideState.idle;

  /// 当前错误
  GuideError? _error;

  /// 当前定位到的元素信息
  ElementInfo? _currentElement;

  /// 用户进度
  UserProgress? _progress;

  /// 步骤开始时间（用于计算耗时）
  DateTime? _stepStartTime;

  /// 引导开始时间
  DateTime? _sessionStartTime;

  /// 任务仓库
  final TaskRepository _repository;

  /// WebView 管理器
  final WebViewManager _webViewManager;

  /// 元素识别引擎
  final ElementResolver _elementResolver;

  /// 叠加层渲染器
  final OverlayRenderer _overlayRenderer;

  /// 状态变化回调
  void Function(GuideState state)? onStateChanged;

  /// 步骤变化回调
  void Function(int stepIndex, GuideStep step)? onStepChanged;

  /// 元素定位回调
  void Function(ElementInfo element)? onElementLocated;

  /// 错误回调
  void Function(GuideError error)? onError;

  /// 完成回调
  void Function(UserProgress progress)? onCompleted;

  /// 进度更新回调
  void Function(UserProgress progress)? onProgressUpdated;

  /// 元素扫描定时器
  Timer? _scanTimer;

  /// 重试次数
  int _retryCount = 0;

  /// 最大重试次数
  static const int maxRetries = 3;

  /// 构造函数
  GuideController({
    TaskRepository? repository,
    WebViewManager? webViewManager,
    ElementResolver? elementResolver,
    OverlayRenderer? overlayRenderer,
  })  : _repository = repository ?? TaskRepository(),
        _webViewManager = webViewManager ?? WebViewManager(),
        _elementResolver = elementResolver ?? ElementResolver(),
        _overlayRenderer = overlayRenderer ?? OverlayRenderer();

  // ==================== Getter ====================

  /// 当前引导任务
  GuideTask? get task => _task;

  /// 当前步骤索引
  int get currentStepIndex => _currentStepIndex;

  /// 当前引导状态
  GuideState get state => _state;

  /// 当前错误
  GuideError? get error => _error;

  /// 当前定位到的元素
  ElementInfo? get currentElement => _currentElement;

  /// 当前用户进度
  UserProgress? get progress => _progress;

  /// 当前步骤
  GuideStep? get currentStep {
    if (_task == null || _currentStepIndex >= _task!.steps.length) return null;
    return _task!.steps[_currentStepIndex];
  }

  /// 是否有下一步
  bool get hasNextStep {
    if (_task == null) return false;
    return _currentStepIndex < _task!.steps.length - 1;
  }

  /// 是否有上一步
  bool get hasPreviousStep => _currentStepIndex > 0;

  /// 总步骤数
  int get totalSteps => _task?.steps.length ?? 0;

  /// 进度百分比
  double get progressPercentage {
    if (totalSteps == 0) return 0;
    return (_currentStepIndex / totalSteps) * 100;
  }

  // ==================== 生命周期方法 ====================

  /// 初始化引导会话
  /// [taskId] 任务 ID
  Future<void> startSession(String taskId) async {
    // 检查状态
    if (_state == GuideState.running) {
      _setError(GuideError.unknown(message: '引导会话已在运行中'));
      return;
    }

    // 切换到加载状态
    _setState(GuideState.loading);
    _error = null;
    _retryCount = 0;

    try {
      // 加载任务数据
      _task = await _repository.getTaskDetail(taskId, forceRefresh: false);
      if (_task == null) {
        _setError(GuideError.elementNotFound(
          selector: taskId,
          details: '任务不存在: $taskId',
        ));
        return;
      }

      // 加载或创建用户进度
      _progress = _repository.getUserProgress(taskId);
      if (_progress == null) {
        _progress = UserProgress(
          taskId: taskId,
          totalSteps: _task!.steps.length,
          startedAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      _sessionStartTime = DateTime.now();
      _currentStepIndex = _progress!.currentStepIndex;

      // 初始化 WebView
      await _webViewManager.loadUrl(_task!.targetUrl);

      // 等待页面加载完成
      await _webViewManager.waitForPageLoad();

      // 注入 JS 脚本
      await _webViewManager.injectScript('assets/js/element_scanner.js');

      // 设置 JS Bridge 回调
      _setupJsBridgeCallbacks();

      // 开始第一个步骤
      _setState(GuideState.running);
      await _executeCurrentStep();
    } catch (e, stack) {
      _setError(GuideError.unknown(
        message: '初始化引导会话失败',
        error: e,
        stackTrace: stack,
      ));
    }
  }

  /// 执行当前步骤
  Future<void> _executeCurrentStep() async {
    final step = currentStep;
    if (step == null || _state != GuideState.running) return;

    // 通知步骤变化
    _stepStartTime = DateTime.now();
    onStepChanged?.call(_currentStepIndex, step);

    try {
      // 定位目标元素
      final element = await _elementResolver.resolveElement(
        step.target,
        webViewManager: _webViewManager,
      );

      if (element == null || !element.isValid) {
        // 元素未找到，启动轮询扫描
        _startElementScanning(step);
        return;
      }

      // 更新当前元素
      _currentElement = element;
      onElementLocated?.call(element);

      // 渲染高亮和引导卡片
      _overlayRenderer.showHighlight(element);
      _overlayRenderer.showGuideCard(
        step: step,
        stepIndex: _currentStepIndex,
        totalSteps: totalSteps,
        hasNext: hasNextStep,
        hasPrevious: hasPreviousStep,
      );

      // 设置元素点击监听
      await _webViewManager.setupElementClickListener(element);
    } catch (e, stack) {
      _setError(GuideError.elementNotFound(
        selector: step.target.selector,
        stepIndex: _currentStepIndex,
        details: e.toString(),
      ));
    }
  }

  /// 启动元素轮询扫描
  void _startElementScanning(GuideStep step) {
    // 先显示提示信息
    _overlayRenderer.showScanningHint(
      message: '正在查找目标元素...',
      step: step,
    );

    // 停止之前的扫描
    _scanTimer?.cancel();

    // 启动定时扫描
    _scanTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) async {
        if (_state != GuideState.running) {
          timer.cancel();
          return;
        }

        try {
          final element = await _elementResolver.resolveElement(
            step.target,
            webViewManager: _webViewManager,
          );

          if (element != null && element.isValid) {
            // 找到元素，停止扫描
            timer.cancel();
            _currentElement = element;
            onElementLocated?.call(element);

            _overlayRenderer.showHighlight(element);
            _overlayRenderer.showGuideCard(
              step: step,
              stepIndex: _currentStepIndex,
              totalSteps: totalSteps,
              hasNext: hasNextStep,
              hasPrevious: hasPreviousStep,
            );

            await _webViewManager.setupElementClickListener(element);
          }
        } catch (e) {
          // 扫描出错，继续尝试
        }
      },
    );

    // 设置超时
    Future.delayed(
      Duration(milliseconds: step.target.waitTimeout),
      () {
        if (_scanTimer?.isActive == true) {
          _scanTimer?.cancel();
          _setError(GuideError.elementTimeout(
            selector: step.target.selector,
            stepIndex: _currentStepIndex,
            timeoutMs: step.target.waitTimeout,
          ));
        }
      },
    );
  }

  /// 设置 JS Bridge 回调
  void _setupJsBridgeCallbacks() {
    _webViewManager.onElementClicked = (selector) {
      _handleElementClicked(selector);
    };

    _webViewManager.onPageLoaded = () {
      if (_state == GuideState.running) {
        // 页面重新加载，重新注入脚本并执行当前步骤
        _webViewManager.injectScript('assets/js/element_scanner.js').then((_) {
          _executeCurrentStep();
        });
      }
    };
  }

  /// 处理元素点击事件
  void _handleElementClicked(String clickedSelector) {
    if (_state != GuideState.running) return;

    final step = currentStep;
    if (step == null) return;

    // 验证点击的元素是否为目标元素
    final isTarget = _elementResolver.isTargetElement(
      clickedSelector: clickedSelector,
      target: step.target,
    );

    if (isTarget) {
      _completeCurrentStep();
    }
  }

  /// 完成当前步骤
  Future<void> _completeCurrentStep() async {
    final step = currentStep;
    if (step == null) return;

    // 停止扫描
    _scanTimer?.cancel();

    // 计算步骤耗时
    final durationMs = _stepStartTime != null
        ? DateTime.now().difference(_stepStartTime!).inMilliseconds
        : 0;

    // 更新进度
    if (_progress != null) {
      _progress = _progress!.completeStep(_currentStepIndex, durationMs);
      await _repository.saveUserProgress(_progress!);
      onProgressUpdated?.call(_progress!);
    }

    // 等待步骤完成后的延迟
    if (step.waitAfterComplete > 0) {
      await Future.delayed(Duration(milliseconds: step.waitAfterComplete));
    }

    // 检查是否全部完成
    if (!hasNextStep) {
      _completeSession();
      return;
    }

    // 推进到下一步
    _currentStepIndex++;
    await _executeCurrentStep();
  }

  /// 完成整个引导会话
  void _completeSession() {
    _setState(GuideState.completed);

    // 更新进度为已完成
    if (_progress != null) {
      final totalDuration = _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inMilliseconds
          : 0;

      _progress = _progress!.copyWith(
        isCompleted: true,
        completedAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        completionCount: _progress!.completionCount + 1,
        totalDurationMs: totalDuration,
      );
      _repository.saveUserProgress(_progress!);
    }

    // 清理叠加层
    _overlayRenderer.clearAll();

    // 通知完成
    onCompleted?.call(_progress!);
  }

  // ==================== 用户操作 ====================

  /// 下一步（手动推进）
  Future<void> nextStep() async {
    if (_state != GuideState.running) return;
    if (!hasNextStep) return;

    _scanTimer?.cancel();
    _currentStepIndex++;
    await _executeCurrentStep();
  }

  /// 上一步
  Future<void> previousStep() async {
    if (_state != GuideState.running) return;
    if (!hasPreviousStep) return;

    _scanTimer?.cancel();
    _currentStepIndex--;
    await _executeCurrentStep();
  }

  /// 跳过当前步骤
  Future<void> skipStep() async {
    if (_state != GuideState.running) return;

    _scanTimer?.cancel();

    // 标记当前步骤为已完成（跳过）
    final durationMs = _stepStartTime != null
        ? DateTime.now().difference(_stepStartTime!).inMilliseconds
        : 0;

    if (_progress != null) {
      _progress = _progress!.completeStep(_currentStepIndex, durationMs);
      await _repository.saveUserProgress(_progress!);
    }

    // 推进到下一步
    if (hasNextStep) {
      _currentStepIndex++;
      await _executeCurrentStep();
    } else {
      _completeSession();
    }
  }

  /// 暂停引导
  void pause() {
    if (_state != GuideState.running) return;
    _scanTimer?.cancel();
    _setState(GuideState.paused);
    _overlayRenderer.clearAll();
  }

  /// 恢复引导
  Future<void> resume() async {
    if (_state != GuideState.paused) return;
    _setState(GuideState.running);
    await _executeCurrentStep();
  }

  /// 重试当前步骤
  Future<void> retry() async {
    if (_state == GuideState.error) {
      _error = null;
      _retryCount++;
      if (_retryCount > maxRetries) {
        _setError(GuideError.unknown(message: '已达到最大重试次数'));
        return;
      }
      _setState(GuideState.running);
      await _executeCurrentStep();
    }
  }

  /// 停止引导会话
  Future<void> stop() async {
    _scanTimer?.cancel();
    _setState(GuideState.idle);
    _overlayRenderer.clearAll();
    await _webViewManager.clearListeners();
  }

  /// 重新开始引导
  Future<void> restart() async {
    if (_task == null) return;
    await stop();
    _currentStepIndex = 0;
    _error = null;
    _retryCount = 0;

    if (_progress != null) {
      _progress = _progress!.reset();
      await _repository.saveUserProgress(_progress!);
    }

    await startSession(_task!.id);
  }

  // ==================== 内部方法 ====================

  /// 更新状态
  void _setState(GuideState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(_state);
    }
  }

  /// 设置错误
  void _setError(GuideError error) {
    _error = error;
    _setState(GuideState.error);
    onError?.call(error);
  }

  /// 释放资源
  void dispose() {
    _scanTimer?.cancel();
    _overlayRenderer.dispose();
    _webViewManager.dispose();
  }
}
