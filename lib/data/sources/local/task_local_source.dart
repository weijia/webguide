import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/guide_task.dart';

/// 本地任务数据源
/// 负责从 Hive 缓存和本地 JSON 资源中读取引导任务数据
class TaskLocalSource {
  /// 任务数据 Box
  final Box _taskBox;

  /// 构造函数，注入 Hive Box
  TaskLocalSource({Box? taskBox})
      : _taskBox = taskBox ?? Hive.box(AppConstants.hiveBoxTasks);

  // ==================== 缓存操作 ====================

  /// 获取缓存的任务列表
  /// 返回 null 表示没有缓存或缓存已过期
  List<GuideTask>? getCachedTasks() {
    try {
      // 检查缓存是否存在
      if (!_taskBox.containsKey(AppConstants.keyCachedTasks)) {
        return null;
      }

      // 检查缓存是否过期
      final cacheTime = _taskBox.get(AppConstants.keyCacheTimestamp) as int?;
      if (cacheTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = (now - cacheTime) ~/ 1000;
        if (elapsed > AppConstants.cacheExpireSeconds) {
          // 缓存已过期，清除旧缓存
          clearCache();
          return null;
        }
      }

      // 读取并解析缓存数据
      final cachedJson = _taskBox.get(AppConstants.keyCachedTasks) as String;
      final List<dynamic> jsonList = jsonDecode(cachedJson);
      return jsonList.map((json) => GuideTask.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // 缓存数据损坏，清除并返回 null
      clearCache();
      return null;
    }
  }

  /// 缓存任务列表到本地
  Future<void> cacheTasks(List<GuideTask> tasks) async {
    try {
      final jsonList = tasks.map((task) => task.toJson()).toList();
      await _taskBox.put(AppConstants.keyCachedTasks, jsonEncode(jsonList));
      await _taskBox.put(
        AppConstants.keyCacheTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // 缓存写入失败，静默处理
    }
  }

  /// 清除任务缓存
  Future<void> clearCache() async {
    try {
      await _taskBox.delete(AppConstants.keyCachedTasks);
      await _taskBox.delete(AppConstants.keyCacheTimestamp);
    } catch (e) {
      // 静默处理
    }
  }

  // ==================== 本地资源加载 ====================

  /// 从本地 JSON 资源加载任务定义
  /// [assetPath] 资源路径，如 'assets/tasks/github_signup.json'
  Future<GuideTask?> loadTaskFromAsset(String assetPath) async {
    try {
      // 加载 JSON 字符串
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return GuideTask.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// 加载所有内置任务
  /// 从 assets/tasks/ 目录加载所有 JSON 任务定义
  Future<List<GuideTask>> loadBuiltinTasks() async {
    final tasks = <GuideTask>[];

    // 内置任务资源路径列表
    final builtinAssets = [
      'assets/tasks/github_signup.json',
      'assets/tasks/gitee_signup.json',
    ];

    for (final assetPath in builtinAssets) {
      try {
        final task = await loadTaskFromAsset(assetPath);
        if (task != null) {
          tasks.add(task);
        }
      } catch (e) {
        // 单个任务加载失败不影响其他任务
        continue;
      }
    }

    return tasks;
  }

  // ==================== 收藏操作 ====================

  /// 获取收藏的任务 ID 列表
  List<String> getFavoriteTaskIds() {
    try {
      final favorites = _taskBox.get('favorite_ids') as List?;
      return favorites?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// 切换任务收藏状态
  Future<bool> toggleFavorite(String taskId) async {
    try {
      final favorites = getFavoriteTaskIds();
      if (favorites.contains(taskId)) {
        favorites.remove(taskId);
      } else {
        favorites.add(taskId);
      }
      await _taskBox.put('favorite_ids', favorites);
      return favorites.contains(taskId);
    } catch (e) {
      return false;
    }
  }

  /// 判断任务是否已收藏
  bool isFavorite(String taskId) {
    return getFavoriteTaskIds().contains(taskId);
  }

  // ==================== 用户进度操作 ====================

  /// 保存用户进度
  Future<void> saveProgress(String taskId, Map<String, dynamic> progressData) async {
    try {
      final key = '${AppConstants.keyProgressPrefix}$taskId';
      await _taskBox.put(key, jsonEncode(progressData));
    } catch (e) {
      // 静默处理
    }
  }

  /// 获取用户进度
  Map<String, dynamic>? getProgress(String taskId) {
    try {
      final key = '${AppConstants.keyProgressPrefix}$taskId';
      final data = _taskBox.get(key) as String?;
      if (data == null) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 删除用户进度
  Future<void> removeProgress(String taskId) async {
    try {
      final key = '${AppConstants.keyProgressPrefix}$taskId';
      await _taskBox.delete(key);
    } catch (e) {
      // 静默处理
    }
  }

  /// 释放资源
  void dispose() {
    // Hive Box 不需要手动关闭，由 Hive 管理生命周期
  }
}
