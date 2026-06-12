import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 遮罩组件
/// 在引导过程中覆盖整个 WebView，除高亮区域外为半透明黑色
/// 使用 Canvas 路径裁剪实现高亮区域的"镂空"效果
class GuideMask extends StatelessWidget {
  /// 高亮区域矩形（屏幕坐标）
  final Rect? highlightRect;

  /// 遮罩透明度（0.0 - 1.0）
  final double opacity;

  /// 高亮区域内边距
  final double padding;

  /// 高亮区域圆角
  final double borderRadius;

  /// 遮罩颜色
  final Color maskColor;

  /// 点击遮罩时的回调（通常用于取消引导）
  final VoidCallback? onTap;

  const GuideMask({
    super.key,
    this.highlightRect,
    this.opacity = 0.6,
    this.padding = 8.0,
    this.borderRadius = 8.0,
    this.maskColor = Colors.black,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _MaskPainter(
          highlightRect: highlightRect,
          opacity: opacity,
          padding: padding,
          borderRadius: borderRadius,
          maskColor: maskColor,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// 遮罩绘制器
class _MaskPainter extends CustomPainter {
  /// 高亮区域
  final Rect? highlightRect;

  /// 透明度
  final double opacity;

  /// 内边距
  final double padding;

  /// 圆角
  final double borderRadius;

  /// 遮罩颜色
  final Color maskColor;

  _MaskPainter({
    required this.highlightRect,
    required this.opacity,
    required this.padding,
    required this.borderRadius,
    required this.maskColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 创建遮罩层
    final maskPaint = Paint()
      ..color = maskColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // 创建高亮区域的路径（用于镂空）
    final highlightPath = Path();

    if (highlightRect != null) {
      // 带内边距的高亮区域
      final paddedRect = Rect.fromLTRB(
        (highlightRect!.left - padding).clamp(0.0, size.width),
        (highlightRect!.top - padding).clamp(0.0, size.height),
        (highlightRect!.right + padding).clamp(0.0, size.width),
        (highlightRect!.bottom + padding).clamp(0.0, size.height),
      );

      // 绘制圆角矩形路径
      final rrect = RRect.fromRectAndRadius(paddedRect, Radius.circular(borderRadius));
      highlightPath.addRRect(rrect);
    }

    // 绘制整个画布的遮罩
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fullPath = Path()..addRect(fullRect);

    // 使用 PathOperation.difference 镂空高亮区域
    if (highlightRect != null) {
      final maskPath = Path.combine(PathOperation.difference, fullPath, highlightPath);
      canvas.drawPath(maskPath, maskPaint);
    } else {
      // 没有高亮区域，绘制完整遮罩
      canvas.drawRect(fullRect, maskPaint);
    }

    // 绘制高亮区域边框发光效果
    if (highlightRect != null) {
      final paddedRect = Rect.fromLTRB(
        (highlightRect!.left - padding).clamp(0.0, size.width),
        (highlightRect!.top - padding).clamp(0.0, size.height),
        (highlightRect!.right + padding).clamp(0.0, size.width),
        (highlightRect!.bottom + padding).clamp(0.0, size.height),
      );

      // 外发光
      final glowPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = padding * 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(paddedRect, Radius.circular(borderRadius)),
        glowPaint,
      );

      // 内边框
      final borderPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(paddedRect, Radius.circular(borderRadius)),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect ||
        oldDelegate.opacity != opacity ||
        oldDelegate.padding != padding ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.maskColor != maskColor;
  }
}
