import 'guide_step.dart';

/// 引导任务数据模型
/// 手写不可变数据类，支持 JSON 序列化和 copyWith
class GuideTask {
  /// 任务唯一标识
  final String id;

  /// 任务名称
  final String name;

  /// 任务描述
  final String description;

  /// 任务分类（signup, shopping, social, tools, development）
  final String category;

  /// 难度等级（easy, medium, hard）
  final String difficulty;

  /// 预估完成时间（分钟）
  final int estimatedTime;

  /// 目标网站 URL
  final String targetUrl;

  /// 引导步骤列表
  final List<GuideStep> steps;

  /// 任务图标（emoji 或图标名称）
  final String icon;

  /// 任务标签
  final List<String> tags;

  /// 任务版本号
  final String version;

  /// 作者
  final String author;

  /// 下载次数
  final int downloadCount;

  /// 评分（1-5）
  final double rating;

  /// 是否收藏
  final bool isFavorite;

  /// 创建时间（ISO 8601 格式）
  final String createdAt;

  /// 更新时间（ISO 8601 格式）
  final String updatedAt;

  const GuideTask({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedTime,
    required this.targetUrl,
    this.steps = const [],
    this.icon = '\u{1F4CB}',
    this.tags = const [],
    this.version = '1.0.0',
    this.author = 'WebGuide',
    this.downloadCount = 0,
    this.rating = 0.0,
    this.isFavorite = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  /// 从 JSON 创建 GuideTask 实例
  factory GuideTask.fromJson(Map<String, dynamic> json) {
    return GuideTask(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      estimatedTime: json['estimatedTime'] as int? ?? 0,
      targetUrl: json['targetUrl'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => GuideStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      icon: json['icon'] as String? ?? '\u{1F4CB}',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? 'WebGuide',
      downloadCount: json['downloadCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
      'targetUrl': targetUrl,
      'steps': steps.map((s) => s.toJson()).toList(),
      'icon': icon,
      'tags': tags,
      'version': version,
      'author': author,
      'downloadCount': downloadCount,
      'rating': rating,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 创建副本
  GuideTask copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? difficulty,
    int? estimatedTime,
    String? targetUrl,
    List<GuideStep>? steps,
    String? icon,
    List<String>? tags,
    String? version,
    String? author,
    int? downloadCount,
    double? rating,
    bool? isFavorite,
    String? createdAt,
    String? updatedAt,
  }) {
    return GuideTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      targetUrl: targetUrl ?? this.targetUrl,
      steps: steps ?? this.steps,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      author: author ?? this.author,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
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
