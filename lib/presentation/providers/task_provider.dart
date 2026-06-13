import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/guide_task.dart';
import '../../data/models/user_progress.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/entities/guide_error.dart';
import '../../services/guide/guide_controller.dart';
import '../../services/webview/webview_manager.dart';
import '../../services/webview/js_bridge.dart';
import '../../core/constants/app_constants.dart';

// ==================== 基础 Provider ====================

/// 任务仓库 Provider
/// 提供全局唯一的 TaskRepository 实例
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final repository = TaskRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

/// WebView 管理器 Provider
final webViewManagerProvider = Provider<WebViewManager>((ref) {
  final manager = WebViewManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// JS Bridge Provider
final jsBridgeProvider = Provider<JsBridge>((ref) {
  final bridge = JsBridge();
  ref.onDispose(() => bridge.dispose());
  return bridge;
});

/// 引导控制器 Provider
final guideControllerProvider = Provider<GuideController>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final webViewManager = ref.watch(webViewManagerProvider);
  final controller = GuideController(
    repository: repository,
    webViewManager: webViewManager,
  );
  ref.onDispose(() => controller.dispose());
  return controller;
});

// ==================== 任务列表 Provider ====================

/// 任务列表状态
class TaskListState {
  /// 任务列表
  final List<GuideTask> tasks;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 当前搜索关键词
  final String searchQuery;

  /// 当前分类筛选
  final String categoryFilter;

  /// 当前难度筛选
  final String difficultyFilter;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categoryFilter = AppConstants.categoryAll,
    this.difficultyFilter = '',
  });

  TaskListState copyWith({
    List<GuideTask>? tasks,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? categoryFilter,
    String? difficultyFilter,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      difficultyFilter: difficultyFilter ?? this.difficultyFilter,
    );
  }
}

/// 任务列表 Provider（带状态管理）
final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repository);
});

/// 任务列表 Notifier
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repository;

  TaskListNotifier(this._repository) : super(const TaskListState());

  /// 加载任务列表
  Future<void> loadTasks({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tasks = await _repository.getTasks(
        forceRefresh: forceRefresh,
        category: state.categoryFilter != AppConstants.categoryAll ? state.categoryFilter : null,
        difficulty: state.difficultyFilter.isNotEmpty ? state.difficultyFilter : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 更新搜索关键词
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTasks();
  }

  /// 更新分类筛选
  void setCategoryFilter(String category) {
    state = state.copyWith(categoryFilter: category);
    loadTasks();
  }

  /// 更新难度筛选
  void setDifficultyFilter(String difficulty) {
    state = state.copyWith(difficultyFilter: difficulty);
    loadTasks();
  }

  /// 切换收藏
  Future<void> toggleFavorite(String taskId) async {
    await _repository.toggleFavorite(taskId);
    // 更新列表中的收藏状态
    final updatedTasks = state.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(isFavorite: !task.isFavorite);
      }
      return task;
    }).toList();
    state = state.copyWith(tasks: updatedTasks);
  }

  /// 刷新列表
  Future<void> refresh() async {
    await loadTasks(forceRefresh: true);
  }
}

// ==================== 引导会话 Provider ====================

/// 引导会话状态
class GuideSessionState {
  /// 引导控制器状态
  final GuideState guideState;

  /// 当前任务
  final GuideTask? task;

  /// 当前步骤索引
  final int currentStepIndex;

  /// 总步骤数
  final int totalSteps;

  /// 错误信息
  final String? error;

  /// 用户进度
  final UserProgress? progress;

  const GuideSessionState({
    this.guideState = GuideState.idle,
    this.task,
    this.currentStepIndex = 0,
    this.totalSteps = 0,
    this.error,
    this.progress,
  });

  GuideSessionState copyWith({
    GuideState? guideState,
    GuideTask? task,
    int? currentStepIndex,
    int? totalSteps,
    String? error,
    UserProgress? progress,
  }) {
    return GuideSessionState(
      guideState: guideState ?? this.guideState,
      task: task ?? this.task,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
      error: error,
      progress: progress ?? this.progress,
    );
  }
}

/// 引导会话 Provider
final guideSessionProvider = StateNotifierProvider<GuideSessionNotifier, GuideSessionState>((ref) {
  final controller = ref.watch(guideControllerProvider);
  return GuideSessionNotifier(controller);
});

/// 引导会话 Notifier
class GuideSessionNotifier extends StateNotifier<GuideSessionState> {
  final GuideController _controller;

  GuideSessionNotifier(this._controller) : super(const GuideSessionState()) {
    // 监听引导控制器状态变化
    _controller.onStateChanged = _onStateChanged;
    _controller.onError = _onError;
    _controller.onCompleted = _onCompleted;
    _controller.onProgressUpdated = _onProgressUpdated;
  }

  /// 开始引导会话
  Future<void> startSession(String taskId) async {
    state = const GuideSessionState();
    await _controller.startSession(taskId);
  }

  /// 下一步
  Future<void> nextStep() async {
    await _controller.nextStep();
  }

  /// 上一步
  Future<void> previousStep() async {
    await _controller.previousStep();
  }

  /// 跳过当前步骤
  Future<void> skipStep() async {
    await _controller.skipStep();
  }

  /// 暂停
  void pause() {
    _controller.pause();
  }

  /// 恢复
  Future<void> resume() async {
    await _controller.resume();
  }

  /// 重试
  Future<void> retry() async {
    await _controller.retry();
  }

  /// 停止
  Future<void> stop() async {
    await _controller.stop();
  }

  /// 重新开始
  Future<void> restart() async {
    await _controller.restart();
  }

  /// 状态变化回调
  void _onStateChanged(GuideState guideState) {
    state = state.copyWith(
      guideState: guideState,
      currentStepIndex: _controller.currentStepIndex,
      totalSteps: _controller.totalSteps,
      task: _controller.task,
    );
  }

  /// 错误回调
  void _onError(GuideError error) {
    state = state.copyWith(
      error: error.userFriendlyMessage,
      guideState: GuideState.error,
    );
  }

  /// 完成回调
  void _onCompleted(UserProgress progress) {
    state = state.copyWith(
      guideState: GuideState.completed,
      progress: progress,
    );
  }

  /// 进度更新回调
  void _onProgressUpdated(UserProgress progress) {
    state = state.copyWith(progress: progress);
  }

  @override
  void dispose() {
    _controller.onStateChanged = null;
    _controller.onError = null;
    _controller.onCompleted = null;
    _controller.onProgressUpdated = null;
    super.dispose();
  }
}

// ==================== 用户进度 Provider ====================

/// 用户进度 Provider
/// 获取指定任务的进度
final userProgressProvider = FutureProvider.family<UserProgress?, String>((ref, taskId) async {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.getUserProgress(taskId);
});

// ==================== 设置 Provider ====================

/// 应用设置状态
class SettingsState {
  /// 遮罩透明度
  final double maskOpacity;

  /// 动画速度
  final double animationSpeed;

  /// 是否显示步骤序号
  final bool showStepNumber;

  /// 是否自动推进步骤
  final bool autoAdvance;

  /// 是否启用音效
  final bool soundEnabled;

  /// 是否深色模式（始终为 true）
  final bool isDarkMode;

  const SettingsState({
    this.maskOpacity = 0.6,
    this.animationSpeed = 1.0,
    this.showStepNumber = true,
    this.autoAdvance = false,
    this.soundEnabled = true,
    this.isDarkMode = true,
  });

  SettingsState copyWith({
    double? maskOpacity,
    double? animationSpeed,
    bool? showStepNumber,
    bool? autoAdvance,
    bool? soundEnabled,
    bool? isDarkMode,
  }) {
    return SettingsState(
      maskOpacity: maskOpacity ?? this.maskOpacity,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      showStepNumber: showStepNumber ?? this.showStepNumber,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// 设置 Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// 设置 Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  /// 设置遮罩透明度
  void setMaskOpacity(double opacity) {
    state = state.copyWith(maskOpacity: opacity.clamp(0.0, 1.0));
  }

  /// 设置动画速度
  void setAnimationSpeed(double speed) {
    state = state.copyWith(animationSpeed: speed.clamp(0.5, 2.0));
  }

  /// 切换步骤序号显示
  void toggleStepNumber() {
    state = state.copyWith(showStepNumber: !state.showStepNumber);
  }

  /// 切换自动推进
  void toggleAutoAdvance() {
    state = state.copyWith(autoAdvance: !state.autoAdvance);
  }

  /// 切换音效
  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
  }

  /// 重置为默认设置
  void resetToDefault() {
    state = const SettingsState();
  }
}

// ==================== 搜索 Provider ====================

/// 搜索关键词 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 分类筛选 Provider
final categoryFilterProvider = StateProvider<String>((ref) => AppConstants.categoryAll);

/// 难度筛选 Provider
final difficultyFilterProvider = StateProvider<String>((ref) => '');
