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
