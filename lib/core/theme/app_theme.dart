import 'package:flutter/material.dart';

/// 应用主题定义
/// 采用深色科技风格，主色调为 cyan (#38bdf8)，次色调为 indigo (#818cf8)
class AppTheme {
  // ==================== 颜色常量 ====================

  /// 主色调 - 天蓝色
  static const Color primaryColor = Color(0xFF38bdf8);

  /// 次色调 - 靛蓝色
  static const Color secondaryColor = Color(0xFF818cf8);

  /// 背景色 - 深色
  static const Color backgroundColor = Color(0xFF0f172a);

  /// 表面色 - 卡片背景
  static const Color surfaceColor = Color(0xFF1e293b);

  /// 表面高亮色
  static const Color surfaceHighlightColor = Color(0xFF334155);

  /// 错误色
  static const Color errorColor = Color(0xFFf43f5e);

  /// 成功色
  static const Color successColor = Color(0xFF22c55e);

  /// 警告色
  static const Color warningColor = Color(0xFFf59e0b);

  /// 文字主色
  static const Color textPrimaryColor = Color(0xFFf1f5f9);

  /// 文字次色
  static const Color textSecondaryColor = Color(0xFF94a3b8);

  /// 文字禁用色
  static const Color textDisabledColor = Color(0xFF475569);

  /// 分割线颜色
  static const Color dividerColor = Color(0xFF334155);

  // ==================== 深色主题 ====================

  /// 深色主题配置
  static ThemeData get darkTheme {
    return ThemeData(
      // 使用 Material 3 设计规范
      useMaterial3: true,

      // 亮度模式
      brightness: Brightness.dark,

      // 颜色方案
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Color(0xFF0f172a),
        onSecondary: Color(0xFF0f172a),
        onSurface: textPrimaryColor,
        onError: Color(0xFFFFFFFF),
      ),

      // 脚手架背景色
      scaffoldBackgroundColor: backgroundColor,

      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dividerColor, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHighlightColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondaryColor),
        prefixIconColor: textSecondaryColor,
        suffixIconColor: textSecondaryColor,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Color(0xFF0f172a),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 文字按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 轮廓按钮主题
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // 浮动操作按钮主题
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Color(0xFF0f172a),
        elevation: 4,
        shape: CircleBorder(),
      ),

      // 文字主题
      textTheme: const TextTheme(
        // 大标题
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        // 中标题
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        // 小标题
        headlineSmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        // 标题
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        // 正文大
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        // 正文中
        bodyMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        // 正文小
        bodySmall: TextStyle(
          color: textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        // 标签
        labelLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: textSecondaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ==================== 辅助方法 ====================

  /// 创建渐变色
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// 创建发光阴影
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: secondaryColor.withOpacity(0.2),
          blurRadius: 40,
          spreadRadius: 4,
        ),
      ];

  /// 创建卡片阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}
