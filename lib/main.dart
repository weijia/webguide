import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';

/// 应用程序入口
void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive 本地数据库
  await _initHive();

  // 启动应用，包裹 ProviderScope 以支持 Riverpod 状态管理
  runApp(
    const ProviderScope(
      child: WebGuideApp(),
    ),
  );
}

/// 初始化 Hive 数据库
/// 打开所有需要的 Box 用于本地数据持久化
Future<void> _initHive() async {
  // 初始化 Hive Flutter 适配器
  await Hive.initFlutter();

  // 获取应用文档目录（用于 Hive 存储路径）
  final appDir = await getApplicationDocumentsDirectory();

  // 注册 Hive 类型适配器（如果需要自定义类型）
  // Hive.registerAdapter(UserProgressAdapter());

  // 打开任务数据 Box - 存储缓存的引导任务数据
  await Hive.openBox('tasks', path: appDir.path);

  // 打开用户进度 Box - 存储用户完成任务的进度
  await Hive.openBox('user_progress', path: appDir.path);

  // 打开设置 Box - 存储应用配置信息
  await Hive.openBox('settings', path: appDir.path);

  // 打开会话 Box - 存储当前引导会话的临时数据
  await Hive.openBox('session', path: appDir.path);

  debugPrint('Hive 初始化完成，存储路径: ${appDir.path}');
}
