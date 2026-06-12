import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_provider.dart';

/// 设置页面
/// 提供应用配置选项，包括引导显示设置和关于信息
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==================== 引导设置 ====================
          _buildSectionTitle('引导设置'),

          // 遮罩透明度
          _buildSliderTile(
            title: '遮罩透明度',
            subtitle: '控制引导遮罩的透明程度',
            icon: Icons.opacity,
            value: settings.maskOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setMaskOpacity(value);
            },
          ),

          // 动画速度
          _buildSliderTile(
            title: '动画速度',
            subtitle: '控制引导动画的播放速度',
            icon: Icons.speed,
            value: settings.animationSpeed,
            min: 0.5,
            max: 2.0,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setAnimationSpeed(value);
            },
          ),

          const SizedBox(height: 8),

          // 显示步骤序号
          SwitchListTile(
            title: const Text('显示步骤序号'),
            subtitle: const Text('在引导卡片上显示当前步骤编号'),
            secondary: const Icon(Icons.format_list_numbered),
            value: settings.showStepNumber,
            activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onChanged: (_) {
              ref.read(settingsProvider.notifier).toggleStepNumber();
            },
          ),

          // 自动推进步骤
          SwitchListTile(
            title: const Text('自动推进步骤'),
            subtitle: const Text('完成操作后自动进入下一步'),
            secondary: const Icon(Icons.fast_forward),
            value: settings.autoAdvance,
            activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onChanged: (_) {
              ref.read(settingsProvider.notifier).toggleAutoAdvance();
            },
          ),

          // 音效开关
          SwitchListTile(
            title: const Text('音效'),
            subtitle: const Text('启用引导过程中的音效提示'),
            secondary: const Icon(Icons.volume_up),
            value: settings.soundEnabled,
            activeColor: AppTheme.primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onChanged: (_) {
              ref.read(settingsProvider.notifier).toggleSound();
            },
          ),

          const SizedBox(height: 24),

          // ==================== 数据管理 ====================
          _buildSectionTitle('数据管理'),

          // 清除缓存
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('清除缓存'),
            subtitle: const Text('清除本地缓存的任务数据'),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              _showConfirmDialog(
                context: context,
                title: '清除缓存',
                message: '确定要清除所有缓存数据吗？',
                onConfirm: () {
                  ref.read(taskRepositoryProvider).clearCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('缓存已清除'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              );
            },
          ),

          // 重置进度
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('重置所有进度'),
            subtitle: const Text('清除所有任务的完成进度'),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              _showConfirmDialog(
                context: context,
                title: '重置进度',
                message: '确定要重置所有任务的完成进度吗？此操作不可撤销。',
                onConfirm: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('进度已重置'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              );
            },
          ),

          // 重置设置
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复默认设置'),
            subtitle: const Text('将所有设置恢复为默认值'),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              ref.read(settingsProvider.notifier).resetToDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设置已恢复默认'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ==================== 关于 ====================
          _buildSectionTitle('关于'),

          // 应用信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                // 应用图标
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.explore,
                    color: Color(0xFF0f172a),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 构建滑块设置项
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.surfaceHighlightColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// 显示确认对话框
  void _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
