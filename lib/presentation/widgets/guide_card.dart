import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 引导卡片组件
/// 显示当前步骤的标题、说明和操作按钮
class GuideCard extends StatefulWidget {
  /// 步骤标题
  final String title;

  /// 步骤描述
  final String description;

  /// 当前步骤序号（从 1 开始）
  final int currentStep;

  /// 总步骤数
  final int totalSteps;

  /// 是否有下一步
  final bool hasNext;

  /// 是否有上一步
  final bool hasPrevious;

  /// 下一步回调
  final VoidCallback? onNext;

  /// 上一步回调
  final VoidCallback? onPrevious;

  /// 跳过回调
  final VoidCallback? onSkip;

  /// 关闭回调
  final VoidCallback? onClose;

  /// 是否显示步骤序号
  final bool showStepNumber;

  /// 提示文本（可选）
  final String? hint;

  const GuideCard({
    super.key,
    required this.title,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    this.hasNext = true,
    this.hasPrevious = false,
    this.onNext,
    this.onPrevious,
    this.onSkip,
    this.onClose,
    this.showStepNumber = true,
    this.hint,
  });

  @override
  State<GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<GuideCard> with SingleTickerProviderStateMixin {
  /// 动画控制器
  late AnimationController _animationController;

  /// 滑入动画
  late Animation<Offset> _slideAnimation;

  /// 透明度动画
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 播放入场动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 计算进度百分比
    final progress = widget.totalSteps > 0
        ? (widget.currentStep / widget.totalSteps).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * 20,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 360,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 进度条 ====================
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceHighlightColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 3,
              ),
            ),

            // ==================== 卡片内容 ====================
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 步骤序号和关闭按钮
                  Row(
                    children: [
                      if (widget.showStepNumber)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '步骤 ${widget.currentStep}/${widget.totalSteps}',
                            style: const TextStyle(
                              color: Color(0xFF0f172a),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // 关闭按钮
                      if (widget.onClose != null)
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHighlightColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 步骤标题
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 步骤描述
                  Text(
                    widget.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  // 提示文本
                  if (widget.hint != null && widget.hint!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.warningColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.hint!,
                              style: const TextStyle(
                                color: AppTheme.warningColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ==================== 操作按钮 ====================
                  Row(
                    children: [
                      // 上一步按钮
                      if (widget.hasPrevious)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onPrevious,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondaryColor,
                              side: BorderSide(color: AppTheme.dividerColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('上一步'),
                          ),
                        ),

                      if (widget.hasPrevious) const SizedBox(width: 8),

                      // 跳过按钮
                      if (widget.onSkip != null)
                        TextButton(
                          onPressed: widget.onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('跳过'),
                        ),

                      const Spacer(),

                      // 下一步按钮
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: widget.hasNext ? widget.onNext : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: const Color(0xFF0f172a),
                            disabledBackgroundColor: AppTheme.surfaceHighlightColor,
                            disabledForegroundColor: AppTheme.textDisabledColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(
                            widget.hasNext ? '下一步' : '完成',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
