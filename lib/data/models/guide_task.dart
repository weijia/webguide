import 'package:freezed_annotation/freezed_annotation.dart';
import 'guide_step.dart';

part 'guide_task.freezed.dart';
part 'guide_task.g.dart';

/// 引导任务数据模型
/// 使用 freezed 实现不可变数据类，支持 JSON 序列化
@freezed
class GuideTask with _$GuideTask {
  const factory GuideTask({
    /// 任务唯一标识
    required String id,

    /// 任务名称
    required String name,

    /// 任务描述
    required String description,

    /// 任务分类（signup, shopping, social, tools, development）
    required String category,

    /// 难度等级（easy, medium, hard）
    required String difficulty,

    /// 预估完成时间（分钟）
    required int estimatedTime,

    /// 目标网站 URL
    required String targetUrl,

    /// 引导步骤列表
    @Default([]) List<GuideStep> steps,

    /// 任务图标（emoji 或图标名称）
    @Default('📋') String icon,

    /// 任务标签
    @Default([]) List<String> tags,

    /// 任务版本号
    @Default('1.0.0') String version,

    /// 作者
    @Default('WebGuide') String author,

    /// 下载次数
    @Default(0) int downloadCount,

    /// 评分（1-5）
    @Default(0.0) double rating,

    /// 是否收藏
    @Default(false) bool isFavorite,

    /// 创建时间（ISO 8601 格式）
    @Default('') String createdAt,

    /// 更新时间（ISO 8601 格式）
    @Default('') String updatedAt,
  }) = _GuideTask;

  /// 从 JSON 创建 GuideTask 实例
  factory GuideTask.fromJson(Map<String, dynamic> json) => _$GuideTaskFromJson(json);
}

/// GuideTask 扩展方法
extension GuideTaskExtension on GuideTask {
  /// 获取步骤总数
  int get totalSteps => steps.length;

  /// 获取难度显示文本
  String get difficultyText {
    switch (difficulty) {
      case 'easy':
        return '简单';
      case 'medium':
        return '中等';
      case 'hard':
        return '困难';
      default:
        return '未知';
    }
  }

  /// 获取难度对应的颜色值（ARGB 整数）
  int get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return 0xFF22c55e; // 绿色
      case 'medium':
        return 0xFFf59e0b; // 黄色
      case 'hard':
        return 0xFFf43f5e; // 红色
      default:
        return 0xFF94a3b8; // 灰色
    }
  }

  /// 获取分类显示文本
  String get categoryText {
    switch (category) {
      case 'signup':
        return '注册';
      case 'shopping':
        return '购物';
      case 'social':
        return '社交';
      case 'tools':
        return '工具';
      case 'development':
        return '开发';
      default:
        return '其他';
    }
  }

  /// 获取预估时间显示文本
  String get estimatedTimeText {
    if (estimatedTime < 60) {
      return '$estimatedTime 分钟';
    } else {
      final hours = estimatedTime ~/ 60;
      final minutes = estimatedTime % 60;
      return minutes > 0 ? '$hours 小时 $minutes 分钟' : '$hours 小时';
    }
  }
}
