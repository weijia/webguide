import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 高亮边框组件
/// 在目标元素周围显示带发光效果的边框动画
class HighlightBorder extends StatefulWidget {
  /// 边框颜色
  final Color color;

  /// 边框宽度
  final double borderWidth;

  /// 圆角半径
  final double borderRadius;

  /// 是否启用脉冲动画
  final bool enablePulse;

  /// 是否启用发光效果
  final bool enableGlow;

  const HighlightBorder({
    super.key,
    this.color = AppTheme.primaryColor,
    this.borderWidth = 3.0,
    this.borderRadius = 8.0,
    this.enablePulse = true,
    this.enableGlow = true,
  });

  @override
  State<HighlightBorder> createState() => _HighlightBorderState();
}

class _HighlightBorderState extends State<HighlightBorder>
    with SingleTickerProviderStateMixin {
  /// 脉冲动画控制器
  late AnimationController _pulseController;

  /// 脉冲动画值（控制发光范围）
  late Animation<double> _pulseAnimation;

  /// 透明度动画（控制发光强度）
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 脉冲范围动画（0.0 - 1.0）
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 透明度动画（0.3 - 1.0）
    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 开始循环动画
    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: _HighlightBorderPainter(
            color: widget.color,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
            pulseValue: _pulseAnimation.value,
            opacityValue: _opacityAnimation.value,
            enableGlow: widget.enableGlow,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// 高亮边框绘制器
class _HighlightBorderPainter extends CustomPainter {
  /// 边框颜色
  final Color color;

  /// 边框宽度
  final double borderWidth;

  /// 圆角半径
  final double borderRadius;

  /// 脉冲值（0.0 - 1.0）
  final double pulseValue;

  /// 透明度值（0.3 - 1.0）
  final double opacityValue;

  /// 是否启用发光
  final bool enableGlow;

  _HighlightBorderPainter({
    required this.color,
    required this.borderWidth,
    required this.borderRadius,
    required this.pulseValue,
    required this.opacityValue,
    required this.enableGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // ==================== 外发光效果 ====================
    if (enableGlow) {
      // 外层发光（大范围，低透明度）
      final outerGlowPaint = Paint()
        ..color = color.withOpacity(0.08 * opacityValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 12 + pulseValue * 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 16);
      canvas.drawRRect(rrect, outerGlowPaint);

      // 中层发光（中等范围）
      final midGlowPaint = Paint()
        ..color = color.withOpacity(0.15 * opacityValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 6 + pulseValue * 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
      canvas.drawRRect(rrect, midGlowPaint);

      // 内层发光（小范围，高透明度）
      final innerGlowPaint = Paint()
        ..color = color.withOpacity(0.25 * opacityValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
      canvas.drawRRect(rrect, innerGlowPaint);
    }

    // ==================== 主边框 ====================
    final borderPaint = Paint()
      ..color = color.withOpacity(opacityValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(rrect, borderPaint);

    // ==================== 内边框（高亮） ====================
    final innerBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * opacityValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final innerRect = Rect.fromLTRB(
      borderWidth / 2 + 1,
      borderWidth / 2 + 1,
      size.width - borderWidth / 2 - 1,
      size.height - borderWidth / 2 - 1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(math.max(0, borderRadius - 1))),
      innerBorderPaint,
    );

    // ==================== 四角装饰 ====================
    _drawCornerDecorations(canvas, rrect);
  }

  /// 绘制四角装饰
  void _drawCornerDecorations(Canvas canvas, RRect rrect) {
    final cornerLength = 12.0;
    final cornerPaint = Paint()
      ..color = color.withOpacity(opacityValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = rrect.outerRect;

    // 左上角
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HighlightBorderPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.opacityValue != opacityValue ||
        oldDelegate.color != color ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.enableGlow != enableGlow;
  }
}
