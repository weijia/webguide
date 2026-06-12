import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/guide/guide_controller.dart';
import '../../../services/webview/webview_manager.dart';
import '../../providers/task_provider.dart';
import '../widgets/guide_mask.dart';
import '../widgets/guide_card.dart';
import '../widgets/highlight_border.dart';

/// 引导页面
/// Stack 布局：WebView + 遮罩 + 高亮框 + 引导卡片
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

  /// 当前高亮区域（相对于 WebView 的位置）
  Rect? _highlightRect;

  /// 是否显示遮罩
  bool _showMask = false;

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
        _showMask = state == GuideState.running;
        _showGuideCard = state == GuideState.running;
        if (state == GuideState.idle || state == GuideState.completed || state == GuideState.error) {
          _showMask = false;
          _showGuideCard = false;
          _highlightRect = null;
        }
      });
    }
  }

  /// 步骤变化
  void _onStepChanged(int stepIndex, dynamic step) {
    if (mounted) {
      setState(() {
        _currentStep = stepIndex;
        _totalSteps = _guideController.totalSteps;
        _hasNext = _guideController.hasNext;
        _hasPrevious = _guideController.hasPrevious;
        _stepTitle = step.title as String? ?? '';
        _stepDescription = step.description as String? ?? '';
      });
    }
  }

  /// 元素定位成功
  void _onElementLocated(dynamic element) {
    if (mounted && element != null) {
      setState(() {
        // 将元素位置转换为屏幕坐标
        final rect = element.rect;
        _highlightRect = Rect.fromPoints(
          Offset(rect.left, rect.top),
          Offset(rect.right, rect.bottom),
        );
      });
    }
  }

  /// 引导错误
  void _onGuideError(dynamic error) {
    if (mounted) {
      setState(() {
        _errorMessage = error.userFriendlyMessage as String? ?? '发生错误';
      });
    }
  }

  /// 引导完成
  void _onGuideCompleted(dynamic progress) {
    if (mounted) {
      setState(() {
        _showMask = false;
        _showGuideCard = false;
        _highlightRect = null;
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
    return Scaffold(
      body: Stack(
        children: [
          // ==================== 第一层：WebView ====================
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

          // ==================== 第二层：遮罩 ====================
          if (_showMask)
            Positioned.fill(
              child: GuideMask(
                highlightRect: _highlightRect,
                opacity: 0.6,
              ),
            ),

          // ==================== 第三层：高亮框 ====================
          if (_highlightRect != null && _showMask)
            Positioned(
              left: _highlightRect!.left - 4,
              top: _highlightRect!.top - 4,
              width: _highlightRect!.width + 8,
              height: _highlightRect!.height + 8,
              child: const HighlightBorder(),
            ),

          // ==================== 第四层：引导卡片 ====================
          if (_showGuideCard && _stepTitle.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
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
              ),
            ),

          // ==================== 第五层：顶部工具栏 ====================
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
                      AppTheme.backgroundColor.withOpacity(0.9),
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

          // ==================== 第六层：错误提示 ====================
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

          // ==================== 第七层：加载中指示 ====================
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

          // ==================== 第八层：完成界面 ====================
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
