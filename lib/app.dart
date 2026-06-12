import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/router/app_router.dart';

/// 应用根组件
/// 配置 MaterialApp.router，使用 GoRouter 进行声明式路由管理
class WebGuideApp extends ConsumerWidget {
  const WebGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取路由配置
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      // 应用标题
      title: 'WebGuide - 网页引导助手',

      // 路由配置
      routerConfig: router,

      // 主题配置 - 深色科技风
      theme: AppTheme.darkTheme,

      // 调试横幅（发布模式自动关闭）
      debugShowCheckedModeBanner: false,

      // 构建器 - 可用于全局拦截器、加载指示器等
      builder: (context, child) {
        return MediaQuery(
          // 强制文本缩放比例为 1.0，避免用户系统设置影响 UI 布局
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
