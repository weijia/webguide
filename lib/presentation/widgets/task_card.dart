import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/guide_task.dart';

/// 任务卡片组件
/// 在首页列表中展示单个引导任务的摘要信息
class TaskCard extends StatelessWidget {
  /// 任务数据
  final GuideTask task;

  /// 点击回调
  final VoidCallback? onTap;

  /// 收藏切换回调
  final VoidCallback? onFavoriteToggle;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== 任务图标 ====================
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        task.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ==================== 任务信息 ====================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 任务名称
                        Text(
                          task.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // 任务描述
                        Text(
                          task.description,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // 标签行
                        Row(
                          children: [
                            // 分类标签
                            _buildTag(
                              text: task.categoryText,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),

                            // 难度标签
                            _buildTag(
                              text: task.difficultyText,
                              color: Color(task.difficultyColor),
                            ),
                            const SizedBox(width: 6),

                            // 步骤数标签
                            _buildTag(
                              text: '${task.totalSteps} 步',
                              color: AppTheme.secondaryColor,
                            ),

                            const Spacer(),

                            // 预估时间
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  task.estimatedTimeText,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ==================== 收藏按钮 ====================
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          task.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: task.isFavorite ? AppTheme.errorColor : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标签组件
  Widget _buildTag({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
