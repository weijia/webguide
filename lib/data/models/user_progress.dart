import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_progress.freezed.dart';
part 'user_progress.g.dart';

/// 用户进度数据模型
/// 记录用户对每个引导任务的完成进度
@freezed
class UserProgress with _$UserProgress {
  const factory UserProgress({
    /// 关联的任务 ID
    required String taskId,

    /// 当前步骤索引（从 0 开始）
    @Default(0) int currentStepIndex,

    /// 已完成的步骤索引集合
    @Default([]) List<int> completedSteps,

    /// 总步骤数
    @Default(0) int totalSteps,

    /// 是否已完成全部步骤
    @Default(false) bool isCompleted,

    /// 完成时间（ISO 8601 格式），null 表示未完成
    String? completedAt,

    /// 开始时间（ISO 8601 格式）
    String? startedAt,

    /// 最后更新时间（ISO 8601 格式）
    String? updatedAt,

    /// 完成次数
    @Default(0) int completionCount,

    /// 总耗时（毫秒）
    @Default(0) int totalDurationMs,

    /// 每个步骤的耗时记录（毫秒），key 为步骤索引
    @Default({}) Map<int, int> stepDurations,

    /// 用户备注
    @Default('') String notes,

    /// 是否跳过
    @Default(false) bool isSkipped,
  }) = _UserProgress;

  /// 从 JSON 创建 UserProgress 实例
  factory UserProgress.fromJson(Map<String, dynamic> json) => _$UserProgressFromJson(json);
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
