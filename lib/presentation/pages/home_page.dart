import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';

/// 首页
/// 展示任务列表，支持搜索和分类筛选
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  /// 搜索控制器
  final _searchController = TextEditingController();

  /// 分类列表
  final _categories = [
    _CategoryItem(name: '全部', value: AppConstants.categoryAll, icon: Icons.apps),
    _CategoryItem(name: '注册', value: AppConstants.categorySignup, icon: Icons.person_add),
    _CategoryItem(name: '购物', value: AppConstants.categoryShopping, icon: Icons.shopping_cart),
    _CategoryItem(name: '社交', value: AppConstants.categorySocial, icon: Icons.people),
    _CategoryItem(name: '工具', value: AppConstants.categoryTools, icon: Icons.build),
    _CategoryItem(name: '开发', value: AppConstants.categoryDevelopment, icon: Icons.code),
  ];

  /// 当前选中的分类索引
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // 初始加载任务列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 显示导入对话框
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ImportTaskDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ==================== 顶部标题栏 ====================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    // 应用 Logo 和标题
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.explore,
                        color: Color(0xFF0f172a),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WebGuide',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          Text(
                            '网页引导助手',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // 导入按钮
                    IconButton(
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () => _showImportDialog(context),
                    ),
                    // 设置按钮
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => context.push(AppConstants.routeSettings),
                    ),
                  ],
                ),
              ),
            ),

            // ==================== 搜索栏 ====================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '搜索引导任务...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(taskListProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    ref.read(taskListProvider.notifier).setSearchQuery(value);
                  },
                ),
              ),
            ),

            // ==================== 分类标签 ====================
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = index == _selectedCategoryIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(category.icon, size: 16, color: isSelected ? Color(0xFF0f172a) : null),
                            const SizedBox(width: 4),
                            Text(category.name),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: const Color(0xFF0f172a),
                        backgroundColor: AppTheme.surfaceHighlightColor,
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF0f172a) : AppTheme.textSecondaryColor,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                            ref.read(taskListProvider.notifier).setCategoryFilter(category.value);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ==================== 任务列表 ====================
            if (taskState.isLoading && taskState.tasks.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              )
            else if (taskState.error != null && taskState.tasks.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        taskState.error!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(taskListProvider.notifier).refresh(),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            else if (taskState.tasks.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondaryColor),
                      const SizedBox(height: 16),
                      Text(
                        '暂无引导任务',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '下拉刷新或稍后再试',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = taskState.tasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () => context.push('/task/${task.id}'),
                        onFavoriteToggle: () {
                          ref.read(taskListProvider.notifier).toggleFavorite(task.id);
                        },
                      );
                    },
                    childCount: taskState.tasks.length,
                  ),
                ),
              ),

            // 底部间距
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

/// 分类项数据
class _CategoryItem {
  final String name;
  final String value;
  final IconData icon;

  const _CategoryItem({
    required this.name,
    required this.value,
    required this.icon,
  });
}

/// 导入任务对话框
class _ImportTaskDialog extends ConsumerStatefulWidget {
  const _ImportTaskDialog();

  @override
  ConsumerState<_ImportTaskDialog> createState() => _ImportTaskDialogState();
}

class _ImportTaskDialogState extends ConsumerState<_ImportTaskDialog> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.download, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          const Text('导入引导任务'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择导入方式：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // 从本地文件导入
            _buildImportOption(
              icon: Icons.folder_open,
              title: '从本地文件导入',
              subtitle: '选择 .json 格式的任务文件',
              onTap: _isLoading ? null : _importFromFile,
            ),

            const SizedBox(height: 12),

            // 从 URL 导入
            _buildImportOption(
              icon: Icons.link,
              title: '从 URL 导入',
              subtitle: '输入任务 JSON 文件的下载链接',
              onTap: null, // 点击展开 URL 输入
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/task.json',
                      hintStyle: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.http, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _importFromUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: const Color(0xFF0f172a),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('导入'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlightColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondaryColor),
              ],
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  /// 从本地文件导入
  Future<void> _importFromFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(taskListProvider.notifier).importFromFile();

    setState(() {
      _isLoading = false;
    });

    if (result == null) {
      // 用户取消，不关闭对话框
      return;
    }

    if (result.startsWith('导入失败')) {
      setState(() {
        _error = result;
      });
      return;
    }

    // 导入成功
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功导入任务: $result'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  /// 从 URL 导入
  Future<void> _importFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _error = '请输入 URL';
      });
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _error = 'URL 必须以 http:// 或 https:// 开头';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(taskListProvider.notifier).importFromUrl(url);

    setState(() {
      _isLoading = false;
    });

    if (result.startsWith('导入失败')) {
      setState(() {
        _error = result;
      });
      return;
    }

    // 导入成功
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功导入任务: $result'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
