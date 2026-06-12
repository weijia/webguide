import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/guide_task.dart';
import '../providers/task_provider.dart';

/// 任务详情页
/// 展示任务的完整介绍信息，提供开始引导按钮
class TaskDetailPage extends ConsumerStatefulWidget {
  /// 任务 ID
  final String taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  /// 任务数据
  GuideTask? _task;

  /// 是否正在加载
  bool _isLoading = true;

  /// 错误信息
  String? _error;

  /// 用户进度
  int _completedSteps = 0;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  /// 加载任务详情
  Future<void> _loadTask() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(taskRepositoryProvider);
      final task = await repository.getTaskDetail(widget.taskId);

      if (task == null) {
        setState(() {
          _error = '任务不存在';
          _isLoading = false;
        });
        return;
      }

      // 加载用户进度
      final progress = repository.getUserProgress(widget.taskId);
      final completedSteps = progress?.completedSteps.length ?? 0;

      setState(() {
        _task = task;
        _completedSteps = completedSteps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          // 收藏按钮
          if (_task != null)
            IconButton(
              icon: Icon(
                _task!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _task!.isFavorite ? AppTheme.errorColor : null,
              ),
              onPressed: () async {
                await ref.read(taskRepositoryProvider).toggleFavorite(widget.taskId);
                setState(() {
                  _task = _task!.copyWith(isFavorite: !_task!.isFavorite);
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? _buildErrorView()
              : _task != null
                  ? _buildTaskDetail()
                  : const SizedBox.shrink(),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(_error!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTask,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建任务详情视图
  Widget _buildTaskDetail() {
    final task = _task!;
    final hasProgress = _completedSteps > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== 任务头部信息 ====================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 任务图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    task.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 任务名称和分类
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge(task.categoryText, AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        _buildBadge(task.difficultyText, Color(task.difficultyColor)),
                        const SizedBox(width: 8),
                        _buildBadge(task.estimatedTimeText, AppTheme.textSecondaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================== 任务描述 ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '任务描述',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==================== 进度信息 ====================
          if (hasProgress)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '上次进度',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.warningColor,
                            ),
                      ),
                      Text(
                        '$_completedSteps / ${task.totalSteps}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _completedSteps / task.totalSteps,
                      backgroundColor: AppTheme.surfaceHighlightColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.warningColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ==================== 步骤预览 ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '引导步骤 (${task.totalSteps} 步)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 12),
                ...task.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isCompleted = index < _completedSteps;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // 步骤序号
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppTheme.successColor
                                : AppTheme.surfaceHighlightColor,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : Text(
                                    '${index + 1}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 步骤标题
                        Expanded(
                          child: Text(
                            step.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isCompleted ? AppTheme.textSecondaryColor : null,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                          ),
                        ),
                        // 操作类型标签
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHighlightColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getActionText(step.action),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ==================== 任务统计 ====================
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.download,
                  label: '下载',
                  value: '${task.downloadCount}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  label: '评分',
                  value: task.rating > 0 ? '${task.rating}' : '暂无',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.update,
                  label: '版本',
                  value: task.version,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ==================== 开始按钮 ====================
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                context.push('/guide/${task.id}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: const Color(0xFF0f172a),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    hasProgress ? '继续引导' : '开始引导',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建标签
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  /// 获取操作类型文本
  String _getActionText(dynamic action) {
    switch (action.toString()) {
      case 'StepAction.click':
        return '点击';
      case 'StepAction.input':
        return '输入';
      case 'StepAction.select':
        return '选择';
      case 'StepAction.scroll':
        return '滚动';
      case 'StepAction.wait':
        return '等待';
      case 'StepAction.check':
        return '勾选';
      default:
        return '操作';
    }
  }
}
