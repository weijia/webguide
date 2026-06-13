import 'dart:async';
import 'dart:ui';

import '../../../core/constants/app_constants.dart';

/// JS Bridge 消息类型
enum JsMessageType {
  /// 扫描页面元素
  scanElements,

  /// 高亮指定元素
  highlightElement,

  /// 移除元素高亮
  removeHighlight,

  /// 元素被点击
  elementClicked,

  /// 页面加载完成
  onPageLoaded,

  /// 获取元素信息
  getElementInfo,

  /// 滚动到元素
  scrollToElement,

  /// 输入文本
  inputText,

  /// 点击元素
  clickElement,

  /// 自定义 JS 执行
  executeScript,

  /// 控制台日志
  consoleLog,

  /// 错误
  error,

  /// 页面 DOM 变化
  domChanged,

  /// URL 变化
  urlChanged,
}

/// JS Bridge 消息
class JsBridgeMessage {
  /// 消息类型
  final JsMessageType type;

  /// 消息数据
  final Map<String, dynamic>? data;

  /// 消息 ID（用于请求-响应匹配）
  final String? id;

  /// 时间戳
  final DateTime timestamp;

  JsBridgeMessage({
    required this.type,
    this.data,
    this.id,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 转换为 JSON 字符串（用于发送到 JS 端）
  String toJsonString() {
    final map = <String, dynamic>{
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
    if (data != null) map['data'] = data;
    if (id != null) map['id'] = id;
    return map.toString();
  }

  /// 从 JSON 字符串创建消息（从 JS 端接收）
  factory JsBridgeMessage.fromJsonString(String jsonString) {
    // 简易 JSON 解析
    final typeStr = _extractValue(jsonString, 'type');
    final dataStr = _extractValue(jsonString, 'data');
    final idStr = _extractValue(jsonString, 'id');

    JsMessageType? messageType;
    try {
      messageType = JsMessageType.values.firstWhere((e) => e.name == typeStr);
    } catch (_) {
      messageType = JsMessageType.error;
    }

    return JsBridgeMessage(
      type: messageType,
      id: idStr.isNotEmpty ? idStr : null,
      data: dataStr.isNotEmpty ? {'raw': dataStr} : null,
    );
  }

  /// 从字符串中提取 JSON 值
  static String _extractValue(String json, String key) {
    final pattern = '"$key"\\s*:\\s*"([^"]*)"';
    final regex = RegExp(pattern);
    final match = regex.firstMatch(json);
    return match?.group(1) ?? '';
  }
}

/// JS Bridge
/// 定义 Flutter 与 WebView 之间的双向通信协议
/// 负责：消息序列化/反序列化、请求-响应匹配、事件分发
class JsBridge {
  // ==================== 属性 ====================

  /// 消息发送回调（由 WebViewManager 注入）
  void Function(String message)? _sendMessage;

  /// 请求等待映射（ID -> Completer）
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  /// 事件监听器映射
  final Map<JsMessageType, List<void Function(JsBridgeMessage)>> _eventListeners = {};

  /// 请求 ID 计数器
  int _requestIdCounter = 0;

  /// 是否已连接
  bool _isConnected = false;

  // ==================== Getter ====================

  /// 是否已连接
  bool get isConnected => _isConnected;

  // ==================== 初始化 ====================

  /// 连接 JS Bridge
  /// [sendMessage] 消息发送函数（由 WebViewManager 提供）
  void connect(void Function(String message) sendMessage) {
    _sendMessage = sendMessage;
    _isConnected = true;
  }

  /// 断开连接
  void disconnect() {
    _sendMessage = null;
    _isConnected = false;

    // 取消所有等待中的请求
    for (final completer in _pendingRequests.values) {
      completer.completeError(Exception('JS Bridge 已断开'));
    }
    _pendingRequests.clear();
    _eventListeners.clear();
  }

  // ==================== 消息处理 ====================

  /// 处理从 JS 端接收到的消息
  void handleMessage(String messageString) {
    try {
      final message = JsBridgeMessage.fromJsonString(messageString);

      // 检查是否为请求的响应
      if (message.id != null && _pendingRequests.containsKey(message.id)) {
        final completer = _pendingRequests.remove(message.id);
        completer?.complete(message.data);
        return;
      }

      // 分发事件到监听器
      _dispatchEvent(message);
    } catch (e) {
      // 消息解析失败
    }
  }

  /// 分发事件到监听器
  void _dispatchEvent(JsBridgeMessage message) {
    final listeners = _eventListeners[message.type];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(message);
        } catch (e) {
          // 监听器执行出错
        }
      }
    }
  }

  // ==================== API 方法 ====================

  /// 扫描页面元素
  /// 返回所有可见可交互元素的信息列表
  Future<List<Map<String, dynamic>>> scanElements() async {
    return await _sendRequest(JsMessageType.scanElements, data: {
      'selectors': 'button, a, input, select, textarea, [role="button"], [role="link"], [role="textbox"]',
    }).then((result) {
      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      }
      return <Map<String, dynamic>>[];
    });
  }

  /// 高亮指定元素
  /// [selector] CSS 选择器
  /// [color] 高亮颜色（默认 #38bdf8）
  /// [duration] 高亮持续时间（毫秒），0 表示持续高亮
  Future<void> highlightElement(
    String selector, {
    String color = '#38bdf8',
    int duration = 0,
  }) async {
    await _sendRequest(JsMessageType.highlightElement, data: {
      'selector': selector,
      'color': color,
      'duration': duration,
    });
  }

  /// 移除元素高亮
  Future<void> removeHighlight(String selector) async {
    await _sendRequest(JsMessageType.removeHighlight, data: {
      'selector': selector,
    });
  }

  /// 获取指定元素的信息
  /// [selector] CSS 选择器
  Future<Map<String, dynamic>?> getElementInfo(String selector) async {
    final result = await _sendRequest(JsMessageType.getElementInfo, data: {
      'selector': selector,
    });
    if (result is Map<String, dynamic>) return result;
    return null;
  }

  /// 滚动到指定元素
  /// [selector] CSS 选择器
  /// [behavior] 滚动行为（smooth, auto）
  /// [block] 垂直对齐方式（start, center, end, nearest）
  Future<void> scrollToElement(
    String selector, {
    String behavior = 'smooth',
    String block = 'center',
  }) async {
    await _sendRequest(JsMessageType.scrollToElement, data: {
      'selector': selector,
      'behavior': behavior,
      'block': block,
    });
  }

  /// 在指定元素中输入文本
  /// [selector] CSS 选择器
  /// [text] 要输入的文本
  /// [clearFirst] 是否先清空现有内容
  Future<void> inputText(
    String selector,
    String text, {
    bool clearFirst = true,
  }) async {
    await _sendRequest(JsMessageType.inputText, data: {
      'selector': selector,
      'text': text,
      'clearFirst': clearFirst,
    });
  }

  /// 点击指定元素
  /// [selector] CSS 选择器
  Future<void> clickElement(String selector) async {
    await _sendRequest(JsMessageType.clickElement, data: {
      'selector': selector,
    });
  }

  /// 执行自定义 JS 脚本
  /// [script] JS 代码字符串
  Future<dynamic> executeScript(String script) async {
    return await _sendRequest(JsMessageType.executeScript, data: {
      'script': script,
    });
  }

  // ==================== 事件监听 ====================

  /// 监听元素点击事件
  void onElementClicked(void Function(String selector) callback) {
    _addEventListener(JsMessageType.elementClicked, (message) {
      final selector = message.data?['selector'] as String? ?? '';
      callback(selector);
    });
  }

  /// 监听页面加载完成事件
  void onPageLoaded(VoidCallback callback) {
    _addEventListener(JsMessageType.onPageLoaded, (message) {
      callback();
    });
  }

  /// 监听 DOM 变化事件
  void onDomChanged(void Function(List<dynamic> addedNodes) callback) {
    _addEventListener(JsMessageType.domChanged, (message) {
      final addedNodes = message.data?['addedNodes'] as List<dynamic>? ?? [];
      callback(addedNodes);
    });
  }

  /// 监听 URL 变化事件
  void onUrlChanged(void Function(String url) callback) {
    _addEventListener(JsMessageType.urlChanged, (message) {
      final url = message.data?['url'] as String? ?? '';
      callback(url);
    });
  }

  /// 监听控制台日志
  void onConsoleLog(void Function(String message) callback) {
    _addEventListener(JsMessageType.consoleLog, (message) {
      final logMessage = message.data?['message'] as String? ?? '';
      callback(logMessage);
    });
  }

  /// 监听错误事件
  void onError(void Function(String error) callback) {
    _addEventListener(JsMessageType.error, (message) {
      final error = message.data?['message'] as String? ?? '未知错误';
      callback(error);
    });
  }

  /// 添加事件监听器
  void _addEventListener(
    JsMessageType type,
    void Function(JsBridgeMessage) callback,
  ) {
    _eventListeners.putIfAbsent(type, () => []);
    _eventListeners[type]!.add(callback);
  }

  /// 移除事件监听器
  void removeEventListener(JsMessageType type, [void Function(JsBridgeMessage)? callback]) {
    if (callback == null) {
      _eventListeners.remove(type);
    } else {
      _eventListeners[type]?.remove(callback);
    }
  }

  // ==================== 内部方法 ====================

  /// 发送请求并等待响应
  Future<dynamic> _sendRequest(
    JsMessageType type, {
    Map<String, dynamic>? data,
  }) async {
    if (!_isConnected || _sendMessage == null) {
      throw Exception('JS Bridge 未连接');
    }

    final requestId = 'req_${_requestIdCounter++}';
    final message = JsBridgeMessage(
      type: type,
      data: data,
      id: requestId,
    );

    // 创建等待器
    final completer = Completer<dynamic>();
    _pendingRequests[requestId] = completer;

    // 发送消息
    try {
      _sendMessage!(message.toJsonString());
    } catch (e) {
      _pendingRequests.remove(requestId);
      completer.completeError(e);
    }

    // 设置超时
    return completer.future.timeout(
      const Duration(milliseconds: AppConstants.elementLocateTimeout),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException('JS Bridge 请求超时');
      },
    );
  }

  /// 生成 JS 端处理代码
  /// 将所有 API 注册到 WebView 的 JS 环境中
  String generateJsHandlerCode() {
    return '''
      // WebGuide JS Bridge Handler
      (function() {
        if (window.__webguide_bridge) return;
        window.__webguide_bridge = true;
        
        // 请求处理器映射
        var handlers = {};
        
        // scanElements 处理器
        handlers['scanElements'] = function(data) {
          var selectors = data.selectors || 'button, a, input, select, textarea';
          var elements = document.querySelectorAll(selectors);
          var result = [];
          for (var i = 0; i < elements.length; i++) {
            if (window.__webguide_isVisible && window.__webguide_isVisible(elements[i])) {
              result.push(window.__webguide_getElementInfo(elements[i]));
            }
          }
          return result;
        };
        
        // highlightElement 处理器
        handlers['highlightElement'] = function(data) {
          var el = document.querySelector(data.selector);
          if (el) {
            el.style.outline = '3px solid ' + (data.color || '#38bdf8');
            el.style.outlineOffset = '2px';
            el.style.transition = 'outline 0.3s ease';
            el.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            if (data.duration > 0) {
              setTimeout(function() {
                el.style.outline = '';
                el.style.outlineOffset = '';
              }, data.duration);
            }
          }
          return { success: !!el };
        };
        
        // removeHighlight 处理器
        handlers['removeHighlight'] = function(data) {
          var el = document.querySelector(data.selector);
          if (el) {
            el.style.outline = '';
            el.style.outlineOffset = '';
          }
          return { success: !!el };
        };
        
        // getElementInfo 处理器
        handlers['getElementInfo'] = function(data) {
          var el = document.querySelector(data.selector);
          if (el && window.__webguide_getElementInfo) {
            return window.__webguide_getElementInfo(el);
          }
          return null;
        };
        
        // scrollToElement 处理器
        handlers['scrollToElement'] = function(data) {
          var el = document.querySelector(data.selector);
          if (el) {
            el.scrollIntoView({
              behavior: data.behavior || 'smooth',
              block: data.block || 'center'
            });
          }
          return { success: !!el };
        };
        
        // inputText 处理器
        handlers['inputText'] = function(data) {
          var el = document.querySelector(data.selector);
          if (el) {
            if (data.clearFirst) {
              el.value = '';
            }
            el.value = data.text;
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
          }
          return { success: !!el };
        };
        
        // clickElement 处理器
        handlers['clickElement'] = function(data) {
          var el = document.querySelector(data.selector);
          if (el) {
            el.click();
          }
          return { success: !!el };
        };
        
        // executeScript 处理器
        handlers['executeScript'] = function(data) {
          try {
            return eval(data.script);
          } catch(e) {
            return { error: e.message };
          }
        };
        
        // 消息接收处理器
        window.__webguide_handleMessage = function(messageStr) {
          try {
            var message = JSON.parse(messageStr);
            var handler = handlers[message.type];
            
            if (handler) {
              var result = handler(message.data || {});
              // 发送响应
              if (window.${AppConstants.jsChannelName}) {
                window.${AppConstants.jsChannelName}.postMessage(JSON.stringify({
                  type: message.type + 'Response',
                  id: message.id,
                  data: result
                }));
              }
            }
          } catch(e) {
            console.error('[WebGuide Bridge] 处理消息失败: ' + e.message);
          }
        };
        
        // 设置元素点击监听
        document.addEventListener('click', function(event) {
          var target = event.target;
          var selector = window.__webguide_getSelector ? window.__webguide_getSelector(target) : '';
          
          if (window.${AppConstants.jsChannelName}) {
            window.${AppConstants.jsChannelName}.postMessage(JSON.stringify({
              type: 'elementClicked',
              data: {
                selector: selector,
                tag: target.tagName,
                text: (target.textContent || '').trim().substring(0, 100)
              }
            }));
          }
        }, true);
        
        // 监听页面加载
        window.addEventListener('load', function() {
          if (window.${AppConstants.jsChannelName}) {
            window.${AppConstants.jsChannelName}.postMessage(JSON.stringify({
              type: 'onPageLoaded',
              data: { url: window.location.href }
            }));
          }
        });
        
        // 监听 URL 变化
        var _lastUrl = window.location.href;
        setInterval(function() {
          if (window.location.href !== _lastUrl) {
            _lastUrl = window.location.href;
            if (window.${AppConstants.jsChannelName}) {
              window.${AppConstants.jsChannelName}.postMessage(JSON.stringify({
                type: 'urlChanged',
                data: { url: _lastUrl }
              }));
            }
          }
        }, 500);
        
        // 拦截 console.log
        var _originalLog = console.log;
        console.log = function() {
          _originalLog.apply(console, arguments);
          if (window.${AppConstants.jsChannelName}) {
            window.${AppConstants.jsChannelName}.postMessage(JSON.stringify({
              type: 'consoleLog',
              data: { message: Array.prototype.join.call(arguments, ' ') }
            }));
          }
        };
        
        // 拦截 console.error
        var _originalError = console.error;
        console.error = function() {
          _originalError.apply(console, arguments);
          if (window.${AppConstants.jsChannelName}) {
            window.${AppConstants.jsChannelName}.postMessage(JSON.stringify({
              type: 'error',
              data: { message: Array.prototype.join.call(arguments, ' ') }
            }));
          }
        };
        
        console.log('[WebGuide Bridge] JS Bridge 处理器注入完成');
      })();
    ''';
  }

  /// 释放资源
  void dispose() {
    disconnect();
  }
}
