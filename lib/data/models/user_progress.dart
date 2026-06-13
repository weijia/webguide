/// 用户进度数据模型
/// 手写不可变数据类，记录用户对每个引导任务的完成进度
class UserProgress {
  /// 关联的任务 ID
  final String taskId;

  /// 当前步骤索引（从 0 开始）
  final int currentStepIndex;

  /// 已完成的步骤索引集合
  final List<int> completedSteps;

  /// 总步骤数
  final int totalSteps;

  /// 是否已完成全部步骤
  final bool isCompleted;

  /// 完成时间（ISO 8601 格式），null 表示未完成
  final String? completedAt;

  /// 开始时间（ISO 8601 格式）
  final String? startedAt;

  /// 最后更新时间（ISO 8601 格式）
  final String? updatedAt;

  /// 完成次数
  final int completionCount;

  /// 总耗时（毫秒）
  final int totalDurationMs;

  /// 每个步骤的耗时记录（毫秒），key 为步骤索引
  final Map<int, int> stepDurations;

  /// 用户备注
  final String notes;

  /// 是否跳过
  final bool isSkipped;

  const UserProgress({
    required this.taskId,
    this.currentStepIndex = 0,
    this.completedSteps = const [],
    this.totalSteps = 0,
    this.isCompleted = false,
    this.completedAt,
    this.startedAt,
    this.updatedAt,
    this.completionCount = 0,
    this.totalDurationMs = 0,
    this.stepDurations = const {},
    this.notes = '',
    this.isSkipped = false,
  });

  /// 从 JSON 创建 UserProgress 实例
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      taskId: json['taskId'] as String? ?? '',
      currentStepIndex: json['currentStepIndex'] as int? ?? 0,
      completedSteps: (json['completedSteps'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      totalSteps: json['totalSteps'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] as String?,
      startedAt: json['startedAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      completionCount: json['completionCount'] as int? ?? 0,
      totalDurationMs: json['totalDurationMs'] as int? ?? 0,
      stepDurations: (json['stepDurations'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
          {},
      notes: json['notes'] as String? ?? '',
      isSkipped: json['isSkipped'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'currentStepIndex': currentStepIndex,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'startedAt': startedAt,
      'updatedAt': updatedAt,
      'completionCount': completionCount,
      'totalDurationMs': totalDurationMs,
      'stepDurations': stepDurations.map((k, v) => MapEntry('$k', v)),
      'notes': notes,
      'isSkipped': isSkipped,
    };
  }

  /// 创建副本
  UserProgress copyWith({
    String? taskId,
    int? currentStepIndex,
    List<int>? completedSteps,
    int? totalSteps,
    bool? isCompleted,
    String? completedAt,
    String? startedAt,
    String? updatedAt,
    int? completionCount,
    int? totalDurationMs,
    Map<int, int>? stepDurations,
    String? notes,
    bool? isSkipped,
  }) {
    return UserProgress(
      taskId: taskId ?? this.taskId,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedSteps: completedSteps ?? this.completedSteps,
      totalSteps: totalSteps ?? this.totalSteps,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completionCount: completionCount ?? this.completionCount,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      stepDurations: stepDurations ?? this.stepDurations,
      notes: notes ?? this.notes,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }
}

/// UserProgress 扩展方法
extension UserProgressExtension on UserProgress {
  /// 获取完成百分比（0-100）
  int get completionPercentage {
    if (totalSteps == 0) return 0;
    return ((completedSteps.length / totalSteps) * 100).round();
  }

  /// 获取当前步骤序号（从 1 开始）
  int get currentStepNumber => currentStepIndex + 1;

  /// 获取进度显示文本
  String get progressText {
    if (isCompleted) return '已完成';
    return '$currentStepNumber / $totalSteps';
  }

  /// 判断指定步骤是否已完成
  bool isStepCompleted(int stepIndex) => completedSteps.contains(stepIndex);

  /// 标记步骤完成，返回新的进度实例
  UserProgress completeStep(int stepIndex, int durationMs) {
    final newCompletedSteps = List<int>.from(completedSteps);
    if (!newCompletedSteps.contains(stepIndex)) {
      newCompletedSteps.add(stepIndex);
    }

    final newStepDurations = Map<int, int>.from(stepDurations);
    newStepDurations[stepIndex] = durationMs;

    final newCurrentStep = stepIndex + 1;
    final now = DateTime.now().toIso8601String();
    final isAllDone = newCompletedSteps.length >= totalSteps;

    return copyWith(
      currentStepIndex: isAllDone ? currentStepIndex : newCurrentStep,
      completedSteps: newCompletedSteps,
      stepDurations: newStepDurations,
      totalDurationMs: totalDurationMs + durationMs,
      updatedAt: now,
      isCompleted: isAllDone,
      completedAt: isAllDone ? now : completedAt,
    );
  }

  /// 重置进度
  UserProgress reset() {
    return copyWith(
      currentStepIndex: 0,
      completedSteps: [],
      isCompleted: false,
      completedAt: null,
      startedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      stepDurations: {},
      totalDurationMs: 0,
      isSkipped: false,
    );
  }
}
