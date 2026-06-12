import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/guide_task.dart';

/// 远程任务数据源
/// 负责从服务器 API 获取引导任务数据
class TaskRemoteSource {
  /// Dio HTTP 客户端实例
  late final Dio _dio;

  /// 构造函数，初始化 Dio 配置
  TaskRemoteSource() {
    _dio = Dio(
      BaseOptions(
        // API 基础地址
        baseUrl: AppConstants.apiBaseUrl,

        // 连接超时
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),

        // 接收超时
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),

        // 发送超时
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),

        // 默认请求头
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Version': AppConstants.appVersion,
        },

        // 接收数据时自动转换 JSON
        responseType: ResponseType.json,
      ),
    );

    // 添加请求拦截器 - 用于日志和错误处理
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          // 开发模式下打印日志
          assert(() {
            print('[Dio] $obj');
            return true;
          }());
        },
      ),
    );
  }

  // ==================== 任务 API ====================

  /// 获取任务列表
  /// [page] 页码，从 1 开始
  /// [pageSize] 每页数量
  /// [category] 分类筛选，null 表示不筛选
  /// [difficulty] 难度筛选，null 表示不筛选
  /// [search] 搜索关键词，null 表示不搜索
  Future<List<GuideTask>> fetchTasks({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? difficulty,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/tasks',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (category != null && category != AppConstants.categoryAll) 'category': category,
          if (difficulty != null) 'difficulty': difficulty,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final data = response.data;
      if (data == null) return [];

      // 解析响应数据
      final List<dynamic> taskList;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        taskList = data['data'] as List<dynamic>;
      } else if (data is List) {
        taskList = data;
      } else {
        return [];
      }

      return taskList
          .map((item) => GuideTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw RemoteDataSourceException('获取任务列表失败: ${e.toString()}');
    }
  }

  /// 获取单个任务详情
  /// [taskId] 任务 ID
  Future<GuideTask> fetchTaskDetail(String taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId');

      final data = response.data;
      if (data == null) {
        throw RemoteDataSourceException('任务数据为空');
      }

      final Map<String, dynamic> taskMap;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        taskMap = data['data'] as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        taskMap = data;
      } else {
        throw RemoteDataSourceException('任务数据格式错误');
      }

      return GuideTask.fromJson(taskMap);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw RemoteDataSourceException('获取任务详情失败: ${e.toString()}');
    }
  }

  /// 获取热门任务
  /// [limit] 返回数量限制
  Future<List<GuideTask>> fetchPopularTasks({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/tasks/popular',
        queryParameters: {'limit': limit},
      );

      final data = response.data;
      if (data == null) return [];

      final List<dynamic> taskList;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        taskList = data['data'] as List<dynamic>;
      } else if (data is List) {
        taskList = data;
      } else {
        return [];
      }

      return taskList
          .map((item) => GuideTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw RemoteDataSourceException('获取热门任务失败: ${e.toString()}');
    }
  }

  /// 获取最新任务
  /// [limit] 返回数量限制
  Future<List<GuideTask>> fetchLatestTasks({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/tasks/latest',
        queryParameters: {'limit': limit},
      );

      final data = response.data;
      if (data == null) return [];

      final List<dynamic> taskList;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        taskList = data['data'] as List<dynamic>;
      } else if (data is List) {
        taskList = data;
      } else {
        return [];
      }

      return taskList
          .map((item) => GuideTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw RemoteDataSourceException('获取最新任务失败: ${e.toString()}');
    }
  }

  /// 上报用户进度到服务器
  /// [taskId] 任务 ID
  /// [progressData] 进度数据
  Future<void> reportProgress(String taskId, Map<String, dynamic> progressData) async {
    try {
      await _dio.post(
        '/tasks/$taskId/progress',
        data: progressData,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw RemoteDataSourceException('上报进度失败: ${e.toString()}');
    }
  }

  /// 上报任务完成
  /// [taskId] 任务 ID
  /// [durationMs] 完成耗时（毫秒）
  Future<void> reportCompletion(String taskId, int durationMs) async {
    try {
      await _dio.post(
        '/tasks/$taskId/complete',
        data: {
          'duration_ms': durationMs,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw RemoteDataSourceException('上报完成状态失败: ${e.toString()}');
    }
  }

  // ==================== 错误处理 ====================

  /// 处理 Dio 错误，转换为业务异常
  RemoteDataSourceException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return RemoteDataSourceException('连接超时，请检查网络');
      case DioExceptionType.sendTimeout:
        return RemoteDataSourceException('发送超时，请检查网络');
      case DioExceptionType.receiveTimeout:
        return RemoteDataSourceException('接收超时，请稍后重试');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return RemoteDataSourceException('请求参数错误');
          case 401:
            return RemoteDataSourceException('未授权，请登录');
          case 403:
            return RemoteDataSourceException('无权访问');
          case 404:
            return RemoteDataSourceException('资源不存在');
          case 500:
            return RemoteDataSourceException('服务器内部错误');
          default:
            return RemoteDataSourceException('请求失败 ($statusCode)');
        }
      case DioExceptionType.cancel:
        return RemoteDataSourceException('请求已取消');
      case DioExceptionType.connectionError:
        return RemoteDataSourceException('网络连接失败，请检查网络设置');
      default:
        return RemoteDataSourceException('网络请求异常: ${e.message}');
    }
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}

/// 远程数据源异常
class RemoteDataSourceException implements Exception {
  /// 错误消息
  final String message;

  RemoteDataSourceException(this.message);

  @override
  String toString() => message;
}
