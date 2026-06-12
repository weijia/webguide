/// 应用全局常量定义
class AppConstants {
  // ==================== 应用信息 ====================

  /// 应用名称
  static const String appName = 'WebGuide';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 应用描述
  static const String appDescription = '网页引导助手 - 帮助用户逐步完成网页操作';

  // ==================== Hive Box 名称 ====================

  /// 任务数据 Box
  static const String hiveBoxTasks = 'tasks';

  /// 用户进度 Box
  static const String hiveBoxUserProgress = 'user_progress';

  /// 设置 Box
  static const String hiveBoxSettings = 'settings';

  /// 会话 Box
  static const String hiveBoxSession = 'session';

  // ==================== Hive Key ====================

  /// 缓存任务列表 Key
  static const String keyCachedTasks = 'cached_tasks';

  /// 缓存时间 Key
  static const String keyCacheTimestamp = 'cache_timestamp';

  /// 用户进度 Key 前缀
  static const String keyProgressPrefix = 'progress_';

  // ==================== 网络配置 ====================

  /// API 基础地址
  static const String apiBaseUrl = 'https://api.webguide.app/v1';

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 15000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 15000;

  /// 发送超时时间（毫秒）
  static const int sendTimeout = 15000;

  // ==================== 缓存配置 ====================

  /// 缓存过期时间（秒）- 默认 24 小时
  static const int cacheExpireSeconds = 86400;

  // ==================== 引导配置 ====================

  /// 元素扫描间隔（毫秒）
  static const int elementScanInterval = 500;

  /// 元素定位超时时间（毫秒）
  static const int elementLocateTimeout = 5000;

  /// 高亮框动画时长（毫秒）
  static const int highlightAnimationDuration = 300;

  /// 遮罩透明度
  static const double maskOpacity = 0.6;

  /// 高亮区域内边距
  static const double highlightPadding = 8.0;

  /// 引导卡片最小宽度
  static const double guideCardMinWidth = 280;

  /// 引导卡片最大宽度
  static const double guideCardMaxWidth = 360;

  // ==================== 任务分类 ====================

  /// 全部分类
  static const String categoryAll = 'all';

  /// 注册类任务
  static const String categorySignup = 'signup';

  /// 购物类任务
  static const String categoryShopping = 'shopping';

  /// 社交类任务
  static const String categorySocial = 'social';

  /// 工具类任务
  static const String categoryTools = 'tools';

  /// 开发类任务
  static const String categoryDevelopment = 'development';

  // ==================== 难度等级 ====================

  /// 简单
  static const String difficultyEasy = 'easy';

  /// 中等
  static const String difficultyMedium = 'medium';

  /// 困难
  static const String difficultyHard = 'hard';

  // ==================== WebView 配置 ====================

  /// WebView 用户代理
  static const String webViewUserAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 WebGuide/1.0';

  /// JS 通道名称
  static const String jsChannelName = 'WebGuideBridge';

  // ==================== 设置默认值 ====================

  /// 默认遮罩透明度
  static const double defaultMaskOpacity = 0.6;

  /// 默认动画速度
  static const double defaultAnimationSpeed = 1.0;

  /// 默认是否显示步骤序号
  static const bool defaultShowStepNumber = true;

  /// 默认是否自动推进步骤
  static const bool defaultAutoAdvance = false;

  /// 默认是否启用音效
  static const bool defaultSoundEnabled = true;

  // ==================== 路由路径 ====================

  /// 首页路由
  static const String routeHome = '/';

  /// 任务详情路由
  static const String routeTaskDetail = '/task/:taskId';

  /// 引导页面路由
  static const String routeGuide = '/guide/:taskId';

  /// 设置页面路由
  static const String routeSettings = '/settings';
}
