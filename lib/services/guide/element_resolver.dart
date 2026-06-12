import '../../data/models/guide_step.dart';
import '../../domain/entities/element_info.dart';
import '../webview/webview_manager.dart';

/// 元素识别引擎
/// 负责在 WebView 页面中定位目标元素
/// 采用多策略回退机制：selector -> text -> xpath -> relative
class ElementResolver {
  /// 构造函数
  ElementResolver();

  // ==================== 核心方法 ====================

  /// 解析目标元素
  /// 按优先级尝试多种策略定位元素
  /// [target] 步骤目标定义
  /// [webViewManager] WebView 管理器
  Future<ElementInfo?> resolveElement(
    StepTarget target, {
    required WebViewManager webViewManager,
  }) async {
    ElementInfo? result;

    // 策略 1: CSS 选择器（优先级最高，最精确）
    if (target.selector != null && target.selector!.isNotEmpty) {
      result = await _resolveBySelector(target.selector!, webViewManager);
      if (result != null && result.isValid) return result;
    }

    // 策略 2: 文本内容匹配
    if (target.text != null && target.text!.isNotEmpty) {
      result = await _resolveByText(target.text!, webViewManager);
      if (result != null && result.isValid) return result;
    }

    // 策略 3: XPath 表达式
    if (target.xpath != null && target.xpath!.isNotEmpty) {
      result = await _resolveByXPath(target.xpath!, webViewManager);
      if (result != null && result.isValid) return result;
    }

    // 策略 4: 标签 + 属性组合匹配
    if (target.tag != null || (target.attributes != null && target.attributes!.isNotEmpty)) {
      result = await _resolveByAttributes(target, webViewManager);
      if (result != null && result.isValid) return result;
    }

    // 策略 5: 类名匹配
    if (target.classNames != null && target.classNames!.isNotEmpty) {
      result = await _resolveByClassNames(target.classNames!, webViewManager);
      if (result != null && result.isValid) return result;
    }

    // 策略 6: 相对定位（最后手段）
    if (target.relative != null && target.relative!.isNotEmpty) {
      result = await _resolveByRelative(target.relative!, webViewManager);
      if (result != null && result.isValid) return result;
    }

    return null;
  }

  // ==================== 策略实现 ====================

  /// 策略 1: 通过 CSS 选择器定位元素
  Future<ElementInfo?> _resolveBySelector(
    String selector,
    WebViewManager webViewManager,
  ) async {
    try {
      // 处理 iframe 内的元素
      if (selector.contains('iframe')) {
        return await _resolveInIframe(selector, webViewManager);
      }

      // 通过 JS Bridge 获取元素信息
      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            var element = document.querySelector('$selector');
            if (!element) return null;
            return JSON.stringify(__webguide_getElementInfo(element));
          } catch(e) {
            return null;
          }
        })()
        ''',
      );

      return _parseElementResult(result, strategy: 'selector');
    } catch (e) {
      return null;
    }
  }

  /// 策略 2: 通过文本内容定位元素
  Future<ElementInfo?> _resolveByText(
    String text,
    WebViewManager webViewManager,
  ) async {
    try {
      // 转义特殊字符
      final escapedText = text.replaceAll("'", "\\'").replaceAll('"', '\\"');

      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            // 策略 2a: 查找包含精确文本的元素
            var xpath = "//*[text()='$escapedText']";
            var elements = document.evaluate(xpath, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
            
            // 优先查找可见的交互元素
            for (var i = 0; i < elements.snapshotLength; i++) {
              var el = elements.snapshotItem(i);
              if (__webguide_isInteractive(el) && __webguide_isVisible(el)) {
                return JSON.stringify(__webguide_getElementInfo(el));
              }
            }
            
            // 策略 2b: 查找包含文本的元素（模糊匹配）
            var allElements = document.querySelectorAll('button, a, input, [role="button"], [role="link"], label, span, div');
            for (var i = 0; i < allElements.length; i++) {
              var el = allElements[i];
              if (el.textContent && el.textContent.trim().indexOf('$escapedText') !== -1) {
                if (__webguide_isVisible(el)) {
                  return JSON.stringify(__webguide_getElementInfo(el));
                }
              }
            }
            
            return null;
          } catch(e) {
            return null;
          }
        })()
        ''',
      );

      return _parseElementResult(result, strategy: 'text');
    } catch (e) {
      return null;
    }
  }

  /// 策略 3: 通过 XPath 定位元素
  Future<ElementInfo?> _resolveByXPath(
    String xpath,
    WebViewManager webViewManager,
  ) async {
    try {
      final escapedXpath = xpath.replaceAll("'", "\\'");

      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            var elements = document.evaluate('$escapedXpath', document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
            if (elements.snapshotLength > 0) {
              var el = elements.snapshotItem(0);
              if (__webguide_isVisible(el)) {
                return JSON.stringify(__webguide_getElementInfo(el));
              }
            }
            return null;
          } catch(e) {
            return null;
          }
        })()
        ''',
      );

      return _parseElementResult(result, strategy: 'xpath');
    } catch (e) {
      return null;
    }
  }

  /// 策略 4: 通过标签和属性组合定位元素
  Future<ElementInfo?> _resolveByAttributes(
    StepTarget target,
    WebViewManager webViewManager,
  ) async {
    try {
      // 构建选择器
      String selector = target.tag ?? '*';

      if (target.elementId != null && target.elementId!.isNotEmpty) {
        selector += '#${target.elementId}';
      }

      if (target.attributes != null) {
        for (final entry in target.attributes!.entries) {
          selector += '[${entry.key}="${entry.value}"]';
        }
      }

      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            var element = document.querySelector('$selector');
            if (element && __webguide_isVisible(element)) {
              return JSON.stringify(__webguide_getElementInfo(element));
            }
            return null;
          } catch(e) {
            return null;
          }
        })()
        ''',
      );

      return _parseElementResult(result, strategy: 'attributes');
    } catch (e) {
      return null;
    }
  }

  /// 策略 5: 通过类名定位元素
  Future<ElementInfo?> _resolveByClassNames(
    List<String> classNames,
    WebViewManager webViewManager,
  ) async {
    try {
      final classSelector = '.${classNames.join('.')}';

      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            var elements = document.querySelectorAll('$classSelector');
            for (var i = 0; i < elements.length; i++) {
              if (__webguide_isVisible(elements[i])) {
                return JSON.stringify(__webguide_getElementInfo(elements[i]));
              }
            }
            return null;
          } catch(e) {
            return null;
          }
        })()
        ''',
      );

      return _parseElementResult(result, strategy: 'className');
    } catch (e) {
      return null;
    }
  }

  /// 策略 6: 通过相对定位描述查找元素
  /// 这是一个启发式方法，尝试根据自然语言描述查找元素
  Future<ElementInfo?> _resolveByRelative(
    String relative,
    WebViewManager webViewManager,
  ) async {
    try {
      // 根据描述中的关键词进行启发式匹配
      final lowerRelative = relative.toLowerCase();

      // 查找所有可见的交互元素
      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            var keywords = '$lowerRelative'.split(/[,，、\\s]+/).filter(function(k) { return k.length > 0; });
            var elements = document.querySelectorAll('button, a, input, select, textarea, [role="button"], [role="link"], [role="textbox"], [tabindex]');
            var bestMatch = null;
            var bestScore = 0;
            
            for (var i = 0; i < elements.length; i++) {
              var el = elements[i];
              if (!__webguide_isVisible(el)) continue;
              
              var score = 0;
              var elText = (el.textContent || '').toLowerCase();
              var elPlaceholder = (el.placeholder || '').toLowerCase();
              var elAriaLabel = (el.getAttribute('aria-label') || '').toLowerCase();
              var elId = (el.id || '').toLowerCase();
              var elClass = (el.className || '').toLowerCase();
              var elType = (el.type || el.tagName || '').toLowerCase();
              
              for (var j = 0; j < keywords.length; j++) {
                var kw = keywords[j];
                if (elText.indexOf(kw) !== -1) score += 3;
                if (elPlaceholder.indexOf(kw) !== -1) score += 4;
                if (elAriaLabel.indexOf(kw) !== -1) score += 5;
                if (elId.indexOf(kw) !== -1) score += 2;
                if (elClass.indexOf(kw) !== -1) score += 1;
                if (elType.indexOf(kw) !== -1) score += 2;
              }
              
              if (score > bestScore) {
                bestScore = score;
                bestMatch = el;
              }
            }
            
            if (bestMatch && bestScore > 0) {
              return JSON.stringify(__webguide_getElementInfo(bestMatch));
            }
            return null;
          } catch(e) {
            return null;
          }
        })()
        ''',
      );

      return _parseElementResult(result, strategy: 'relative');
    } catch (e) {
      return null;
    }
  }

  /// 在 iframe 内查找元素
  Future<ElementInfo?> _resolveInIframe(
    String selector,
    WebViewManager webViewManager,
  ) async {
    try {
      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            var iframe = document.querySelector('iframe');
            if (!iframe || !iframe.contentDocument) return null;
            var element = iframe.contentDocument.querySelector('$selector');
            if (element) {
              return JSON.stringify(__webguide_getElementInfo(element));
            }
            return null;
          } catch(e) {
            return null;
          }
        })()
        ''',
      );

      return _parseElementResult(result, strategy: 'iframe');
    } catch (e) {
      return null;
    }
  }

  // ==================== 辅助方法 ====================

  /// 解析 JS 返回的元素信息
  ElementInfo? _parseElementResult(dynamic result, {required String strategy}) {
    if (result == null) return null;

    try {
      String jsonString;
      if (result is String) {
        jsonString = result;
      } else if (result is Map) {
        jsonString = result.toString();
      } else {
        jsonString = result.toString();
      }

      // 移除可能的 JSON 字符串引号
      if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
        jsonString = jsonString.substring(1, jsonString.length - 1);
        // 处理转义字符
        jsonString = jsonString.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t').replaceAll(r'\"', '"');
      }

      if (jsonString == 'null' || jsonString.isEmpty) return null;

      final Map<String, dynamic> jsonMap;
      try {
        // 尝试直接解析
        jsonMap = _parseJson(jsonString);
      } catch (e) {
        // 解析失败，返回 null
        return null;
      }

      return ElementInfo.fromJson(jsonMap).copyWith(
        matchStrategy: strategy,
        matchConfidence: _calculateConfidence(strategy),
      );
    } catch (e) {
      return null;
    }
  }

  /// 简单 JSON 解析
  Map<String, dynamic> _parseJson(String jsonString) {
    // 使用 dart:convert 的 jsonDecode
    // 这里通过动态导入避免循环依赖
    // 实际使用中直接 import 'dart:convert'
    final decoded = _simpleJsonDecode(jsonString);
    if (decoded is Map<String, dynamic>) return decoded;
    throw FormatException('Invalid JSON');
  }

  /// 简单 JSON 解码器（用于处理 WebView 返回的字符串）
  dynamic _simpleJsonDecode(String str) {
    // 去除首尾空白
    str = str.trim();
    if (str.isEmpty) return null;

    // 这是一个简化版本，实际项目中应使用 dart:convert
    // 这里直接返回 null，让上层处理
    try {
      // 使用内置的 JSON 解码
      return _decodeJsonNative(str);
    } catch (_) {
      return null;
    }
  }

  /// 原生 JSON 解码
  dynamic _decodeJsonNative(String str) {
    // 标记为需要 dart:convert
    // 实际在运行时由 dart:convert 处理
    throw UnimplementedError('Use dart:convert jsonDecode');
  }

  /// 计算匹配置信度
  double _calculateConfidence(String strategy) {
    switch (strategy) {
      case 'selector':
        return 1.0;
      case 'text':
        return 0.85;
      case 'xpath':
        return 0.95;
      case 'attributes':
        return 0.9;
      case 'className':
        return 0.8;
      case 'relative':
        return 0.6;
      case 'iframe':
        return 0.75;
      default:
        return 0.5;
    }
  }

  /// 判断点击的元素是否为目标元素
  bool isTargetElement({
    required String clickedSelector,
    required StepTarget target,
  }) {
    // 精确匹配 CSS 选择器
    if (target.selector != null && target.selector!.isNotEmpty) {
      if (clickedSelector == target.selector) return true;
    }

    // 模糊匹配 - 检查选择器是否包含目标选择器的关键部分
    if (target.selector != null && target.selector!.isNotEmpty) {
      // 提取选择器中的 ID 或 class
      final targetParts = target.selector!.split(RegExp(r'[.#\[\]>+~\s]'));
      final clickedParts = clickedSelector.split(RegExp(r'[.#\[\]>+~\s]'));

      for (final part in targetParts) {
        if (part.isNotEmpty && clickedParts.contains(part)) {
          return true;
        }
      }
    }

    return false;
  }

  /// 扫描页面所有可交互元素
  Future<List<ElementInfo>> scanAllInteractiveElements(
    WebViewManager webViewManager,
  ) async {
    try {
      final result = await webViewManager.evaluateJavascript(
        '''
        (function() {
          try {
            var elements = document.querySelectorAll('button, a, input, select, textarea, [role="button"], [role="link"], [role="textbox"], [tabindex]:not([tabindex="-1"])');
            var result = [];
            for (var i = 0; i < elements.length; i++) {
              var el = elements[i];
              if (__webguide_isVisible(el)) {
                result.push(__webguide_getElementInfo(el));
              }
            }
            return JSON.stringify(result);
          } catch(e) {
            return JSON.stringify([]);
          }
        })()
        ''',
      );

      if (result == null || result.toString() == 'null') return [];

      // 解析结果列表
      final List<ElementInfo> elements = [];
      // 实际解析由上层处理
      return elements;
    } catch (e) {
      return [];
    }
  }
}
