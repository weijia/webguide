import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 引导卡片组件
/// 支持展开/折叠两种模式：
/// - 紧凑模式：单行显示步骤标题 + 操作按钮，不遮挡网页内容
/// - 展开模式：显示完整描述、提示和操作按钮
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

  /// 初始是否展开
  final bool initiallyExpanded;

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
    this.initiallyExpanded = false,
  });

  @override
  State<GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<GuideCard>
    with SingleTickerProviderStateMixin {
  /// 动画控制器
  late AnimationController _animationController;

  /// 滑入动画
  late Animation<Offset> _slideAnimation;

  /// 透明度动画
  late Animation<double> _fadeAnimation;

  /// 是否展开
  bool _isExpanded = false;

  /// 展开/折叠动画控制器
  late AnimationController _expandController;

  /// 展开动画
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

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

    // 展开/折叠动画
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );

    // 播放入场动画
    _animationController.forward();

    // 初始展开状态
    if (_isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(GuideCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 步骤变化时自动折叠，减少遮挡
    if (oldWidget.currentStep != widget.currentStep) {
      _collapse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  /// 切换展开/折叠
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  /// 折叠
  void _collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _expandController.reverse();
      });
    }
  }

  /// 计算进度百分比
  double get _progress =>
      widget.totalSteps > 0
          ? (widget.currentStep / widget.totalSteps).clamp(0.0, 1.0)
          : 0.0;

  @override
  Widget build(BuildContext context) {
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
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.surfaceHighlightColor,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 3,
              ),
            ),

            // ==================== 紧凑模式：单行标题 + 按钮 ====================
            InkWell(
              onTap: _toggleExpand,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // 步骤序号标签
                    if (widget.showStepNumber)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.currentStep}/${widget.totalSteps}',
                          style: const TextStyle(
                            color: Color(0xFF0f172a),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                    const SizedBox(width: 10),

                    // 步骤标题
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 展开/折叠指示图标
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.expand_more,
                          size: 20,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // 跳过按钮（紧凑模式）
                    if (widget.onSkip != null)
                      _CompactButton(
                        label: '跳过',
                        onTap: widget.onSkip,
                        isOutlined: true,
                      ),

                    if (widget.onSkip != null) const SizedBox(width: 6),

                    // 下一步按钮（紧凑模式）
                    _CompactButton(
                      label: widget.hasNext ? '下一步' : '完成',
                      onTap: widget.hasNext ? widget.onNext : null,
                      isPrimary: true,
                      icon: widget.hasNext ? Icons.arrow_forward : Icons.check,
                    ),
                  ],
                ),
              ),
            ),

            // ==================== 展开模式：详细内容 ====================
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _expandAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分隔线
                    Container(
                      height: 1,
                      color: AppTheme.dividerColor,
                      margin: const EdgeInsets.only(bottom: 12),
                    ),

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
                      const SizedBox(height: 10),
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

                    const SizedBox(height: 14),

                    // 展开模式下的完整操作按钮
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('跳过'),
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

                        if (widget.onClose != null) const SizedBox(width: 8),

                        // 下一步按钮
                        SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed:
                                widget.hasNext ? widget.onNext : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: const Color(0xFF0f172a),
                              disabledBackgroundColor:
                                  AppTheme.surfaceHighlightColor,
                              disabledForegroundColor:
                                  AppTheme.textDisabledColor,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(
                              widget.hasNext ? '下一步' : '完成',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 紧凑模式下的按钮组件
class _CompactButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isOutlined;
  final IconData? icon;

  const _CompactButton({
    required this.label,
    this.onTap,
    this.isPrimary = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Material(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: const Color(0xFF0f172a)),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0f172a),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isOutlined) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
