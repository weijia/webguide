import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../pages/home_page.dart';
import '../pages/task_detail_page.dart';
import '../pages/guide_page.dart';
import '../pages/settings_page.dart';

/// GoRouter 路由配置 Provider
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // 初始路由
    initialLocation: AppConstants.routeHome,

    // 路由重定向
    redirect: (context, state) {
      // 可以在这里添加登录验证等重定向逻辑
      return null;
    },

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '页面不存在',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '路径: ${state.uri.path}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeHome),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),

    // 路由表
    routes: [
      // 首页路由
      GoRoute(
        path: AppConstants.routeHome,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // 任务详情路由
      GoRoute(
        path: AppConstants.routeTaskDetail,
        name: 'taskDetail',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return TaskDetailPage(taskId: taskId);
        },
      ),

      // 引导页面路由
      GoRoute(
        path: AppConstants.routeGuide,
        name: 'guide',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return GuidePage(taskId: taskId);
        },
      ),

      // 设置页面路由
      GoRoute(
        path: AppConstants.routeSettings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
