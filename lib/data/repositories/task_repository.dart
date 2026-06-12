import '../../models/guide_task.dart';
import '../../models/user_progress.dart';
import '../local/task_local_source.dart';
import '../remote/task_remote_source.dart';

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
