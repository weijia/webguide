import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/guide_task.dart';
import '../models/user_progress.dart';
import '../sources/local/task_local_source.dart';
import '../sources/remote/task_remote_source.dart';

/// 任务仓库
/// 整合本地和远程数据源，提供统一的数据访问接口
/// 采用缓存优先策略：先读取本地缓存，缓存不存在或过期时从远程获取
class TaskRepository {
  /// 本地数据源
  final TaskLocalSource _localSource;

  /// 远程数据源
  final TaskRemoteSource _remoteSource;

  /// 构造函数，注入本地和远程数据源
  TaskRepository({
    TaskLocalSource? localSource,
    TaskRemoteSource? remoteSource,
  })  : _localSource = localSource ?? TaskLocalSource(),
        _remoteSource = remoteSource ?? TaskRemoteSource();

  // ==================== 任务 CRUD ====================

  /// 获取任务列表
  /// 优先从本地缓存读取，缓存不存在时从远程获取并缓存
  /// [forceRefresh] 是否强制刷新（忽略缓存）
  /// [category] 分类筛选
  /// [difficulty] 难度筛选
  /// [search] 搜索关键词
  Future<List<GuideTask>> getTasks({
    bool forceRefresh = false,
    String? category,
    String? difficulty,
    String? search,
  }) async {
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh) {
      final cached = _localSource.getCachedTasks();
      if (cached != null && cached.isNotEmpty) {
        // 对缓存数据进行筛选
        return _filterTasks(cached, category: category, difficulty: difficulty, search: search);
      }
    }

    // 缓存不存在或已过期，从远程获取
    try {
      final remoteTasks = await _remoteSource.fetchTasks(
        category: category,
        difficulty: difficulty,
        search: search,
      );

      // 缓存到本地
      if (remoteTasks.isNotEmpty) {
        await _localSource.cacheTasks(remoteTasks);
      }

      return remoteTasks;
    } catch (e) {
      // 远程获取失败，尝试返回缓存（即使可能过期）
      final cached = _localSource.getCachedTasks();
      if (cached != null && cached.isNotEmpty) {
        return _filterTasks(cached, category: category, difficulty: difficulty, search: search);
      }

      // 缓存也没有，尝试加载内置任务
      final builtinTasks = await _localSource.loadBuiltinTasks();
      if (builtinTasks.isNotEmpty) {
        await _localSource.cacheTasks(builtinTasks);
        return _filterTasks(builtinTasks, category: category, difficulty: difficulty, search: search);
      }

      // 所有来源都失败，返回空列表
      return [];
    }
  }

  /// 获取任务详情
  /// [taskId] 任务 ID
  /// [forceRefresh] 是否强制刷新
  Future<GuideTask?> getTaskDetail(String taskId, {bool forceRefresh = false}) async {
    // 先从缓存列表中查找
    if (!forceRefresh) {
      final cached = _localSource.getCachedTasks();
      if (cached != null) {
        final found = cached.where((t) => t.id == taskId).firstOrNull;
        if (found != null) return found;
      }
    }

    // 从远程获取
    try {
      final task = await _remoteSource.fetchTaskDetail(taskId);
      return task;
    } catch (e) {
      // 远程获取失败，从内置任务中查找
      final builtinTasks = await _localSource.loadBuiltinTasks();
      return builtinTasks.where((t) => t.id == taskId).firstOrNull;
    }
  }

  /// 获取内置任务列表
  Future<List<GuideTask>> getBuiltinTasks() async {
    return await _localSource.loadBuiltinTasks();
  }

  /// 获取热门任务
  Future<List<GuideTask>> getPopularTasks({int limit = 10}) async {
    try {
      return await _remoteSource.fetchPopularTasks(limit: limit);
    } catch (e) {
      // 远程获取失败，返回内置任务
      return await _localSource.loadBuiltinTasks();
    }
  }

  /// 获取最新任务
  Future<List<GuideTask>> getLatestTasks({int limit = 10}) async {
    try {
      return await _remoteSource.fetchLatestTasks(limit: limit);
    } catch (e) {
      return [];
    }
  }

  // ==================== 用户进度 ====================

  /// 获取用户进度
  UserProgress? getUserProgress(String taskId) {
    final data = _localSource.getProgress(taskId);
    if (data == null) return null;
    try {
      return UserProgress.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// 保存用户进度
  Future<void> saveUserProgress(UserProgress progress) async {
    await _localSource.saveProgress(progress.taskId, progress.toJson());

    // 同时上报到服务器（静默，不阻塞）
    _remoteSource.reportProgress(progress.taskId, progress.toJson()).catchError((_) {
      // 上报失败不影响本地保存
    });
  }

  /// 重置用户进度
  Future<void> resetUserProgress(String taskId) async {
    await _localSource.removeProgress(taskId);
  }

  // ==================== 收藏 ====================

  /// 获取收藏的任务 ID 列表
  List<String> getFavoriteIds() {
    return _localSource.getFavoriteTaskIds();
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(String taskId) async {
    return await _localSource.toggleFavorite(taskId);
  }

  /// 判断是否已收藏
  bool isFavorite(String taskId) {
    return _localSource.isFavorite(taskId);
  }

  // ==================== 缓存管理 ====================

  /// 清除所有缓存
  Future<void> clearCache() async {
    await _localSource.clearCache();
  }

  /// 刷新任务列表
  Future<List<GuideTask>> refreshTasks({
    String? category,
    String? difficulty,
    String? search,
  }) async {
    return await getTasks(
      forceRefresh: true,
      category: category,
      difficulty: difficulty,
      search: search,
    );
  }

  // ==================== 任务导入 ====================

  /// 从本地文件导入任务
  /// 打开文件选择器，让用户选择 JSON 文件
  Future<GuideTask?> importTaskFromFile() async {
    try {
      // 打开文件选择器
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null; // 用户取消了选择
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw TaskImportException('文件内容为空');
      }

      // 解析 JSON
      final jsonString = utf8.decode(bytes);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // 验证必要字段
      _validateTaskJson(jsonMap);

      final task = GuideTask.fromJson(jsonMap);

      // 保存到缓存
      await _saveImportedTask(task);

      return task;
    } on FormatException catch (e) {
      throw TaskImportException('JSON 格式错误: ${e.message}');
    } catch (e) {
      if (e is TaskImportException) rethrow;
      throw TaskImportException('导入失败: ${e.toString()}');
    }
  }

  /// 从 URL 导入任务
  /// [url] 任务 JSON 文件的 URL
  Future<GuideTask> importTaskFromUrl(String url) async {
    try {
      // 下载并解析任务
      final task = await _remoteSource.downloadTaskFromUrl(url);

      // 保存到缓存
      await _saveImportedTask(task);

      return task;
    } catch (e) {
      if (e is TaskImportException) rethrow;
      throw TaskImportException('从 URL 导入失败: ${e.toString()}');
    }
  }

  /// 从 JSON 字符串导入任务
  /// [jsonString] 任务 JSON 文本
  Future<GuideTask> importTaskFromJsonString(String jsonString) async {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // 验证必要字段
      _validateTaskJson(jsonMap);

      final task = GuideTask.fromJson(jsonMap);

      // 保存到缓存
      await _saveImportedTask(task);

      return task;
    } on FormatException catch (e) {
      throw TaskImportException('JSON 格式错误: ${e.message}');
    } catch (e) {
      if (e is TaskImportException) rethrow;
      throw TaskImportException('导入失败: ${e.toString()}');
    }
  }

  /// 保存导入的任务到本地缓存
  Future<void> _saveImportedTask(GuideTask task) async {
    // 获取现有缓存
    final cached = _localSource.getCachedTasks() ?? [];

    // 检查是否已存在相同 ID 的任务
    final existingIndex = cached.indexWhere((t) => t.id == task.id);
    if (existingIndex >= 0) {
      // 更新现有任务
      cached[existingIndex] = task;
    } else {
      // 添加新任务
      cached.add(task);
    }

    // 保存回缓存
    await _localSource.cacheTasks(cached);
  }

  /// 验证任务 JSON 的必要字段
  void _validateTaskJson(Map<String, dynamic> json) {
    final requiredFields = ['id', 'name', 'description', 'steps'];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw TaskImportException('任务 JSON 缺少必要字段: $field');
      }
    }
    if (json['steps'] is! List || (json['steps'] as List).isEmpty) {
      throw TaskImportException('任务步骤不能为空');
    }
  }

  // ==================== 私有方法 ====================

  /// 对任务列表进行筛选
  List<GuideTask> _filterTasks(
    List<GuideTask> tasks, {
    String? category,
    String? difficulty,
    String? search,
  }) {
    var filtered = tasks;

    // 分类筛选
    if (category != null && category.isNotEmpty && category != 'all') {
      filtered = filtered.where((t) => t.category == category).toList();
    }

    // 难度筛选
    if (difficulty != null && difficulty.isNotEmpty) {
      filtered = filtered.where((t) => t.difficulty == difficulty).toList();
    }

    // 搜索筛选（匹配名称、描述、标签）
    if (search != null && search.isNotEmpty) {
      final keyword = search.toLowerCase();
      filtered = filtered.where((t) {
        return t.name.toLowerCase().contains(keyword) ||
            t.description.toLowerCase().contains(keyword) ||
            t.tags.any((tag) => tag.toLowerCase().contains(keyword));
      }).toList();
    }

    return filtered;
  }

  /// 释放资源
  void dispose() {
    _localSource.dispose();
    _remoteSource.dispose();
  }
}

/// 任务导入异常
class TaskImportException implements Exception {
  /// 错误消息
  final String message;

  TaskImportException(this.message);

  @override
  String toString() => message;
}
