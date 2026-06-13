import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// WebView 管理器
/// 封装 webview_flutter，提供统一的 WebView 控制接口
class WebViewManager {
  // ==================== 属性 ====================

  /// WebViewController 实例
  WebViewController? _controller;

  /// 当前页面 URL
  String? _currentUrl;

  /// 页面加载完成标志
  bool _isPageLoaded = false;

  /// 页面加载完成控制器
  Completer<void>? _pageLoadCompleter;

  /// JS Bridge 通道回调映射
  final Map<String, Function(dynamic)> _jsCallbacks = {};

  /// 元素点击回调
  void Function(String selector)? onElementClicked;

  /// 页面加载完成回调
  VoidCallback? onPageLoaded;

  /// URL 变化回调
  void Function(String url)? onUrlChanged;

  /// 控制台日志回调
  void Function(String message)? onConsoleLog;

  /// 页面标题变化回调
  void Function(String title)? onTitleChanged;

  /// JS 错误回调
  void Function(String error)? onJsError;

  /// 是否已初始化
  bool _isInitialized = false;

  // ==================== Getter ====================

  /// 获取 WebViewController
  WebViewController? get controller => _controller;

  /// 获取当前 URL
  String? get currentUrl => _currentUrl;

  /// 页面是否已加载完成
  bool get isPageLoaded => _isPageLoaded;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  // ==================== 初始化 ====================

  /// 初始化 WebView 控制器
  /// [context] BuildContext（用于获取屏幕尺寸等信息）
  WebViewController initWebView({BuildContext? context}) {
    // 创建 WebViewController
    _controller = WebViewController();

    // 配置 JavaScript
    _controller!.setJavaScriptMode(JavaScriptMode.unrestricted);

    // 设置导航委托
    _controller!.setNavigationDelegate(
      NavigationDelegate(
        // 页面开始加载
        onPageStarted: (String url) {
          _isPageLoaded = false;
          _currentUrl = url;
          debugPrint('[WebView] 页面开始加载: $url');
        },

        // 页面加载完成
        onPageFinished: (String url) {
          _isPageLoaded = true;
          _currentUrl = url;
          debugPrint('[WebView] 页面加载完成: $url');

          // 完成加载等待
          _pageLoadCompleter?.complete();
          _pageLoadCompleter = null;

          // 通知页面加载完成
          onPageLoaded?.call();
        },

        // 页面加载进度
        onProgress: (int progress) {
          debugPrint('[WebView] 加载进度: $progress%');
        },

        // URL 变化
        onUrlChange: (UrlChange change) {
          _currentUrl = change.url;
          onUrlChanged?.call(change.url ?? '');
        },

        // 请求错误
        onWebResourceError: (WebResourceError error) {
          debugPrint('[WebView] 资源加载错误: ${error.description}');
        },

        // HTTP 请求
        onHttpError: (HttpResponseError error) {
          debugPrint('[WebView] HTTP 错误: ${error.request?.uri.toString()}');
        },
      ),
    );

    // 设置背景色
    _controller!.setBackgroundColor(const Color(0xFF000000));

    // 设置用户代理
    _controller!.setUserAgent(AppConstants.webViewUserAgent);

    // 允许文件访问
    _controller!.enableZoom(false);

    // 添加 JS Bridge 通道
    _setupJsBridge();

    _isInitialized = true;
    return _controller!;
  }

  /// 设置 JS Bridge 通道
  void _setupJsBridge() {
    if (_controller == null) return;

    // 使用 addJavaScriptChannel 添加双向通信通道
    _controller!.addJavaScriptChannel(
      AppConstants.jsChannelName,
      onMessageReceived: (JavaScriptMessage message) {
        _handleJsMessage(message.message);
      },
    );
  }

  /// 处理来自 JS 的消息
  void _handleJsMessage(String message) {
    try {
      // 解析消息格式: {type: "event_name", data: {...}}
      // 简单解析（实际使用中应使用 jsonDecode）
      if (message.contains('"type"')) {
        final type = _extractJsonValue(message, 'type');
        final data = _extractJsonValue(message, 'data');

        // 分发到对应的回调
        switch (type) {
          case 'elementClicked':
            onElementClicked?.call(data);
            break;
          case 'pageLoaded':
            onPageLoaded?.call();
            break;
          case 'consoleLog':
            onConsoleLog?.call(data);
            break;
          case 'jsError':
            onJsError?.call(data);
            break;
          default:
            // 查找注册的回调
            final callback = _jsCallbacks[type];
            if (callback != null) {
              callback(data);
            }
        }
      }
    } catch (e) {
      debugPrint('[WebView] 处理 JS 消息失败: $e');
    }
  }

  /// 从 JSON 字符串中提取指定 key 的值（简易实现）
  String _extractJsonValue(String json, String key) {
    final pattern = '"$key"\\s*:\\s*"([^"]*)"';
    final regex = RegExp(pattern);
    final match = regex.firstMatch(json);
    return match?.group(1) ?? '';
  }

  // ==================== 导航方法 ====================

  /// 加载 URL
  Future<void> loadUrl(String url) async {
    if (_controller == null) return;

    _isPageLoaded = false;
    await _controller!.loadRequest(Uri.parse(url));
  }

  /// 等待页面加载完成
  /// [timeout] 超时时间（毫秒），默认 30 秒
  Future<void> waitForPageLoad({int timeout = 30000}) async {
    if (_isPageLoaded) return;

    _pageLoadCompleter = Completer<void>();

    // 设置超时
    return _pageLoadCompleter!.future.timeout(
      Duration(milliseconds: timeout),
      onTimeout: () {
        _pageLoadCompleter = null;
        throw TimeoutException('页面加载超时');
      },
    );
  }

  /// 重新加载当前页面
  Future<void> reload() async {
    await _controller?.reload();
  }

  /// 返回上一页
  Future<void> goBack() async {
    if (await _controller?.canGoBack() ?? false) {
      await _controller?.goBack();
    }
  }

  /// 前进到下一页
  Future<void> goForward() async {
    if (await _controller?.canGoForward() ?? false) {
      await _controller?.goForward();
    }
  }

  // ==================== JavaScript 执行 ====================

  /// 执行 JavaScript 代码并返回结果
  Future<dynamic> evaluateJavascript(String script) async {
    if (_controller == null) return null;

    try {
      final result = await _controller!.runJavaScriptReturningResult(script);
      return result;
    } catch (e) {
      debugPrint('[WebView] JS 执行失败: $e');
      return null;
    }
  }

  /// 执行 JavaScript 代码（不返回结果）
  Future<void> runJavaScript(String script) async {
    if (_controller == null) return;

    try {
      await _controller!.runJavaScript(script);
    } catch (e) {
      debugPrint('[WebView] JS 执行失败: $e');
    }
  }

  /// 注入脚本文件
  /// [assetPath] 资源路径
  Future<void> injectScript(String assetPath) async {
    // 注意：实际使用中需要通过 rootBundle 加载资源文件内容
    // 这里使用直接注入 JS 代码的方式
    try {
      // 实际项目中应从 asset 加载 JS 文件内容
      // final script = await rootBundle.loadString(assetPath);
      // await runJavaScript(script);

      // 注入元素扫描器辅助函数
      await runJavaScript(_elementScannerHelperScript);
    } catch (e) {
      debugPrint('[WebView] 注入脚本失败: $e');
    }
  }

  /// 设置元素点击监听器
  Future<void> setupElementClickListener(dynamic element) async {
    if (_controller == null) return;

    // 通过 JS 为目标元素添加点击事件监听
    await runJavaScript('''
      (function() {
        try {
          // 移除之前的监听器
          if (window.__webguide_clickHandler) {
            document.removeEventListener('click', window.__webguide_clickHandler, true);
          }
          
          // 添加新的点击监听器（捕获阶段）
          window.__webguide_clickHandler = function(event) {
            var target = event.target;
            var selector = __webguide_getSelector(target);
            
            // 通知 Flutter
            if (window.${AppConstants.jsChannelName}) {
              window.${AppConstants.jsChannelName}.postMessage(JSON.stringify({
                type: 'elementClicked',
                data: selector
              }));
            }
          };
          
          document.addEventListener('click', window.__webguide_clickHandler, true);
        } catch(e) {
          console.error('设置点击监听器失败: ' + e.message);
        }
      })()
    ''');
  }

  // ==================== 元素操作 ====================

  /// 滚动到指定元素
  Future<void> scrollToElement(String selector) async {
    await runJavaScript('''
      (function() {
        var element = document.querySelector('$selector');
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      })()
    ''');
  }

  /// 高亮指定元素
  Future<void> highlightElement(String selector) async {
    await runJavaScript('''
      (function() {
        var element = document.querySelector('$selector');
        if (element) {
          element.style.outline = '3px solid #38bdf8';
          element.style.outlineOffset = '2px';
          element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      })()
    ''');
  }

  /// 移除元素高亮
  Future<void> removeHighlight(String selector) async {
    await runJavaScript('''
      (function() {
        var element = document.querySelector('$selector');
        if (element) {
          element.style.outline = '';
          element.style.outlineOffset = '';
        }
      })()
    ''');
  }

  /// 获取页面所有元素信息
  Future<String> scanElements() async {
    final result = await evaluateJavascript('''
      (function() {
        var elements = document.querySelectorAll('button, a, input, select, textarea, [role="button"], [role="link"], [role="textbox"], label');
        var result = [];
        for (var i = 0; i < elements.length; i++) {
          var el = elements[i];
          if (__webguide_isVisible(el)) {
            result.push(__webguide_getElementInfo(el));
          }
        }
        return JSON.stringify(result);
      })()
    ''');
    return result?.toString() ?? '[]';
  }

  // ==================== 清理方法 ====================

  /// 清除所有监听器
  Future<void> clearListeners() async {
    await runJavaScript('''
      (function() {
        if (window.__webguide_clickHandler) {
          document.removeEventListener('click', window.__webguide_clickHandler, true);
          window.__webguide_clickHandler = null;
        }
      })()
    ''');
    _jsCallbacks.clear();
  }

  /// 释放资源
  void dispose() {
    _controller = null;
    _jsCallbacks.clear();
    _isInitialized = false;
  }

  // ==================== 辅助脚本 ====================

  /// 元素扫描器辅助 JS 脚本
  /// 注入到 WebView 中，提供元素信息获取和可见性判断等功能
  String get _elementScannerHelperScript => '''
    // WebGuide 元素扫描器辅助函数
    (function() {
      // 防止重复注入
      if (window.__webguide_injected) return;
      window.__webguide_injected = true;
      
      /**
       * 判断元素是否可见
       */
      window.__webguide_isVisible = function(element) {
        if (!element) return false;
        
        // 检查 display
        var style = window.getComputedStyle(element);
        if (style.display === 'none') return false;
        if (style.visibility === 'hidden') return false;
        if (parseFloat(style.opacity) < 0.1) return false;
        
        // 检查尺寸
        var rect = element.getBoundingClientRect();
        if (rect.width < 1 || rect.height < 1) return false;
        
        // 检查是否在视口内（至少部分可见）
        if (rect.bottom < 0 || rect.top > window.innerHeight) return false;
        if (rect.right < 0 || rect.left > window.innerWidth) return false;
        
        // 检查是否被遮挡（简化版）
        var elementAtPoint = document.elementFromPoint(rect.left + rect.width/2, rect.top + rect.height/2);
        if (elementAtPoint && element !== elementAtPoint && !element.contains(elementAtPoint)) {
          // 被遮挡，但如果是透明元素覆盖则忽略
          var overlayStyle = window.getComputedStyle(elementAtPoint);
          if (parseFloat(overlayStyle.opacity) > 0.5 && overlayStyle.pointerEvents !== 'none') {
            return false;
          }
        }
        
        return true;
      };
      
      /**
       * 判断元素是否可交互
       */
      window.__webguide_isInteractive = function(element) {
        if (!element) return false;
        
        var tag = element.tagName.toLowerCase();
        var interactiveTags = ['a', 'button', 'input', 'select', 'textarea'];
        if (interactiveTags.indexOf(tag) !== -1) return true;
        
        if (element.getAttribute('role') === 'button') return true;
        if (element.getAttribute('role') === 'link') return true;
        if (element.getAttribute('role') === 'textbox') return true;
        if (element.getAttribute('tabindex') !== null) return true;
        if (element.onclick !== null) return true;
        if (element.style.cursor === 'pointer') return true;
        
        return false;
      };
      
      /**
       * 获取元素的完整选择器路径
       */
      window.__webguide_getSelector = function(element) {
        if (!element || element === document.body) return '';
        
        var parts = [];
        var current = element;
        
        while (current && current !== document.body) {
          var selector = current.tagName.toLowerCase();
          
          if (current.id) {
            selector += '#' + current.id;
            parts.unshift(selector);
            break;
          }
          
          if (current.className && typeof current.className === 'string') {
            var classes = current.className.trim().split(/\\s+/).filter(function(c) { return c.length > 0; });
            if (classes.length > 0) {
              selector += '.' + classes[0];
            }
          }
          
          // 添加 nth-child
          var parent = current.parentElement;
          if (parent) {
            var siblings = Array.prototype.filter.call(parent.children, function(child) {
              return child.tagName === current.tagName;
            });
            if (siblings.length > 1) {
              var index = Array.prototype.indexOf.call(siblings, current) + 1;
              selector += ':nth-child(' + index + ')';
            }
          }
          
          parts.unshift(selector);
          current = current.parentElement;
        }
        
        return parts.join(' > ');
      };
      
      /**
       * 获取元素信息对象
       */
      window.__webguide_getElementInfo = function(element) {
        if (!element) return null;
        
        var rect = element.getBoundingClientRect();
        var scrollX = window.scrollX || window.pageXOffset;
        var scrollY = window.scrollY || window.pageYOffset;
        
        return {
          rect: {
            left: rect.left,
            top: rect.top,
            right: rect.right,
            bottom: rect.bottom,
            scrollLeft: rect.left + scrollX,
            scrollTop: rect.top + scrollY,
            scrollRight: rect.right + scrollX,
            scrollBottom: rect.bottom + scrollY,
            width: rect.width,
            height: rect.height
          },
          selector: __webguide_getSelector(element),
          tag: element.tagName.toLowerCase(),
          text: (element.textContent || '').trim().substring(0, 200),
          id: element.id || '',
          classNames: element.className ? element.className.trim().split(/\\s+/) : [],
          type: element.type || '',
          href: element.href || '',
          placeholder: element.placeholder || '',
          value: element.value || '',
          ariaLabel: element.getAttribute('aria-label') || '',
          ariaRole: element.getAttribute('role') || '',
          isVisible: __webguide_isVisible(element),
          isInteractive: __webguide_isInteractive(element),
          tabIndex: element.tabIndex
        };
      };
      
      /**
       * 扫描页面所有可交互元素
       */
      window.__webguide_scanElements = function() {
        var selectors = 'button, a, input, select, textarea, [role="button"], [role="link"], [role="textbox"], [tabindex]:not([tabindex="-1"])';
        var elements = document.querySelectorAll(selectors);
        var result = [];
        
        for (var i = 0; i < elements.length; i++) {
          var el = elements[i];
          if (__webguide_isVisible(el)) {
            result.push(__webguide_getElementInfo(el));
          }
        }
        
        return result;
      };
      
      /**
       * 监听页面变化（MutationObserver）
       */
      window.__webguide_startObserver = function(callback) {
        if (window.__webguide_observer) return;
        
        window.__webguide_observer = new MutationObserver(function(mutations) {
          var hasRelevantChange = false;
          for (var i = 0; i < mutations.length; i++) {
            if (mutations[i].addedNodes.length > 0 || mutations[i].attributeName) {
              hasRelevantChange = true;
              break;
            }
          }
          if (hasRelevantChange && callback) {
            callback();
          }
        });
        
        window.__webguide_observer.observe(document.body, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ['class', 'style', 'hidden', 'disabled']
        });
      };
      
      /**
       * 停止页面变化监听
       */
      window.__webguide_stopObserver = function() {
        if (window.__webguide_observer) {
          window.__webguide_observer.disconnect();
          window.__webguide_observer = null;
        }
      };
      
      console.log('[WebGuide] 辅助函数注入完成');
    })();
  ''';
}
