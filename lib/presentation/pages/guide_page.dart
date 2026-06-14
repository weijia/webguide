import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/guide_step.dart';
import '../../../domain/entities/element_info.dart';
import '../../../domain/entities/guide_error.dart';
import '../../../data/models/user_progress.dart';
import '../../../services/guide/guide_controller.dart';
import '../../../services/webview/webview_manager.dart';
import '../providers/task_provider.dart';
import '../widgets/guide_card.dart';

/// 引导页面
/// Stack 布局：WebView（全屏可操作） + 可拖动引导浮窗 + 顶部工具栏
class GuidePage extends ConsumerStatefulWidget {
  /// 任务 ID
  final String taskId;

  const GuidePage({super.key, required this.taskId});

  @override
  ConsumerState<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends ConsumerState<GuidePage> {
  /// WebView 管理器
  late WebViewManager _webViewManager;

  /// WebViewController
  WebViewController? _webViewController;

  /// 引导控制器
  late GuideController _guideController;

  /// 是否显示引导卡片
  bool _showGuideCard = false;

  /// 当前步骤标题
  String _stepTitle = '';

  /// 当前步骤描述
  String _stepDescription = '';

  /// 当前步骤索引
  int _currentStep = 0;

  /// 总步骤数
  int _totalSteps = 0;

  /// 是否有下一步
  bool _hasNext = false;

  /// 是否有上一步
  bool _hasPrevious = false;

  /// 引导状态
  GuideState _guideState = GuideState.idle;

  /// 错误信息
  String? _errorMessage;

  /// WebView 加载进度
  int _loadingProgress = 0;

  /// 是否正在加载 WebView
  bool _isWebViewLoading = true;

  /// 浮窗位置
  Offset _floatPosition = const Offset(16, 80);

  /// 浮窗是否被拖动过（用于记录用户偏好位置）
  bool _hasDragged = false;

  @override
  void initState() {
    super.initState();
    _initGuide();
  }

  /// 初始化引导
  void _initGuide() {
    _webViewManager = ref.read(webViewManagerProvider);
    _guideController = ref.read(guideControllerProvider);

    // 初始化 WebView
    _webViewController = _webViewManager.initWebView();

    // 设置 WebView 回调
    _webViewManager.onPageLoaded = _onPageLoaded;
    _webViewManager.onElementClicked = _onElementClicked;

    // 设置引导控制器回调
    _guideController.onStateChanged = _onGuideStateChanged;
    _guideController.onStepChanged = _onStepChanged;
    _guideController.onElementLocated = _onElementLocated;
    _guideController.onError = _onGuideError;
    _guideController.onCompleted = _onGuideCompleted;

    // 开始引导会话
    Future.delayed(const Duration(milliseconds: 500), () {
      _guideController.startSession(widget.taskId);
    });
  }

  @override
  void dispose() {
    _guideController.onStateChanged = null;
    _guideController.onStepChanged = null;
    _guideController.onElementLocated = null;
    _guideController.onError = null;
    _guideController.onCompleted = null;
    _guideController.stop();
    super.dispose();
  }

  // ==================== 回调处理 ====================

  /// WebView 页面加载完成
  void _onPageLoaded() {
    if (mounted) {
      setState(() {
        _isWebViewLoading = false;
      });
    }
  }

  /// 元素被点击
  void _onElementClicked(String selector) {
    // 由引导控制器处理
  }

  /// 引导状态变化
  void _onGuideStateChanged(GuideState state) {
    if (mounted) {
      setState(() {
        _guideState = state;
        _showGuideCard = state == GuideState.running;
        if (state == GuideState.idle || state == GuideState.completed || state == GuideState.error) {
          _showGuideCard = false;
        }
      });
    }
  }

  /// 步骤变化
  void _onStepChanged(int stepIndex, GuideStep step) {
    if (mounted) {
      setState(() {
        _currentStep = stepIndex;
        _totalSteps = _guideController.totalSteps;
        _hasNext = _guideController.hasNextStep;
        _hasPrevious = _guideController.hasPreviousStep;
        _stepTitle = step.title;
        _stepDescription = step.description;
      });
    }
  }

  /// 元素定位成功（保留用于未来扩展，当前不显示高亮框）
  void _onElementLocated(ElementInfo element) {
    // 不再显示高亮框和遮罩，用户可以直接操作网页
  }

  /// 引导错误
  void _onGuideError(GuideError error) {
    if (mounted) {
      setState(() {
        _errorMessage = error.userFriendlyMessage;
      });
    }
  }

  /// 引导完成
  void _onGuideCompleted(UserProgress progress) {
    if (mounted) {
      setState(() {
        _showGuideCard = false;
      });

      // 显示完成对话框
      _showCompletionDialog();
    }
  }

  /// 显示完成对话框
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.successColor),
            ),
            const SizedBox(width: 12),
            const Text('引导完成'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('恭喜！你已成功完成所有引导步骤。'),
            const SizedBox(height: 16),
            Text(
              '完成进度: $_currentStep / $_totalSteps',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('返回首页'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guideController.restart();
            },
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  // ==================== 用户操作 ====================

  /// 下一步
  void _handleNext() {
    _guideController.nextStep();
  }

  /// 上一步
  void _handlePrevious() {
    _guideController.previousStep();
  }

  /// 跳过
  void _handleSkip() {
    _guideController.skipStep();
  }

  /// 暂停
  void _handlePause() {
    _guideController.pause();
  }

  /// 重试
  void _handleRetry() {
    _guideController.retry();
  }

  /// 退出
  void _handleExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('退出引导'),
        content: const Text('确定要退出当前引导吗？进度将自动保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guideController.stop();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ==================== 第一层：WebView（全屏可操作） ====================
          Positioned.fill(
            child: _webViewController != null
                ? Stack(
                    children: [
                      WebViewWidget(controller: _webViewController!),
                      // WebView 加载指示器
                      if (_isWebViewLoading)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
          ),

          // ==================== 第二层：可拖动引导浮窗 ====================
          if (_showGuideCard && _stepTitle.isNotEmpty)
            Positioned(
              left: _floatPosition.dx,
              top: _floatPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _hasDragged = true;
                    _floatPosition += details.delta;
                    // 限制在屏幕范围内
                    _floatPosition = Offset(
                      _floatPosition.dx.clamp(0, screenSize.width - 280),
                      _floatPosition.dy.clamp(0, screenSize.height - 120),
                    );
                  });
                },
                child: GuideCard(
                  title: _stepTitle,
                  description: _stepDescription,
                  currentStep: _currentStep + 1,
                  totalSteps: _totalSteps,
                  hasNext: _hasNext,
                  hasPrevious: _hasPrevious,
                  onNext: _handleNext,
                  onPrevious: _handlePrevious,
                  onSkip: _handleSkip,
                  onClose: () {
                    setState(() {
                      _showGuideCard = false;
                    });
                  },
                ),
              ),
            ),

          // ==================== 第三层：顶部工具栏（半透明，不阻挡操作） ====================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.backgroundColor.withOpacity(0.85),
                      AppTheme.backgroundColor.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // 返回按钮
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _handleExit,
                    ),
                    const Spacer(),
                    // 步骤进度指示
                    if (_guideState == GuideState.running)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_currentStep / $_totalSteps',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // 暂停按钮
                    if (_guideState == GuideState.running)
                      IconButton(
                        icon: const Icon(Icons.pause_circle_outline, color: Colors.white),
                        onPressed: _handlePause,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ==================== 第四层：错误提示 ====================
          if (_guideState == GuideState.error && _errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              top: 80,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '出错了',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),

          // ==================== 第五层：加载中指示 ====================
          if (_guideState == GuideState.loading)
            Positioned.fill(
              child: Container(
                color: AppTheme.backgroundColor.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text(
                        '正在初始化引导...',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ==================== 第六层：完成界面 ====================
          if (_guideState == GuideState.completed)
            Positioned.fill(
              child: Container(
                color: AppTheme.backgroundColor.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '引导完成',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.successColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '所有步骤已成功完成',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go('/'),
                            child: const Text('返回首页'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () => _guideController.restart(),
                            child: const Text('重新开始'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
