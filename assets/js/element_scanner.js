/**
 * WebGuide 元素扫描器
 * 注入到 WebView 中的 JavaScript 脚本
 * 负责扫描页面元素、获取位置信息、监听点击事件
 *
 * 功能：
 * 1. 扫描页面中所有可见可交互的元素
 * 2. 获取元素的精确位置、尺寸信息
 * 3. 生成元素的 CSS 选择器路径
 * 4. 监听用户点击事件并上报
 * 5. 监听页面 DOM 变化并通知
 * 6. 提供元素高亮和滚动功能
 */

(function () {
  'use strict';

  // ==================== 防止重复注入 ====================
  if (window.__webguide_scanner_injected) {
    console.log('[WebGuide Scanner] 已注入，跳过重复注入');
    return;
  }
  window.__webguide_scanner_injected = true;

  // ==================== 配置常量 ====================
  var CONFIG = {
    // 可交互元素选择器
    INTERACTIVE_SELECTORS: [
      'a[href]',
      'button',
      'input:not([type="hidden"])',
      'select',
      'textarea',
      '[role="button"]',
      '[role="link"]',
      '[role="textbox"]',
      '[role="checkbox"]',
      '[role="radio"]',
      '[role="combobox"]',
      '[role="switch"]',
      '[tabindex]:not([tabindex="-1"])',
      '[contenteditable="true"]',
      'summary',
      'label[for]'
    ].join(', '),

    // 所有可扫描元素选择器
    ALL_SELECTORS: [
      'a',
      'button',
      'input',
      'select',
      'textarea',
      '[role="button"]',
      '[role="link"]',
      '[role="textbox"]',
      '[role="checkbox"]',
      '[role="radio"]',
      '[role="combobox"]',
      '[role="switch"]',
      '[role="menuitem"]',
      '[role="tab"]',
      '[tabindex]:not([tabindex="-1"])',
      '[contenteditable="true"]',
      'label',
      'summary',
      'details',
      '[data-testid]',
      '[data-action]',
      '[class*="btn"]',
      '[class*="button"]',
      '[class*="link"]',
      '[class*="input"]',
      '[class*="submit"]',
      '[class*="signup"]',
      '[class*="register"]',
      '[class*="login"]',
      '[class*="sign-in"]',
      '[class*="next"]',
      '[class*="continue"]',
      '[class*="verify"]',
      '[class*="confirm"]'
    ].join(', '),

    // 元素可见性阈值
    VISIBILITY_THRESHOLD: 0.1,

    // 最小可见尺寸（像素）
    MIN_VISIBLE_SIZE: 4,

    // 扫描节流间隔（毫秒）
    SCAN_THROTTLE: 200,

    // DOM 变化防抖时间（毫秒）
    DOM_CHANGE_DEBOUNCE: 300,

    // 选择器路径最大深度
    MAX_SELECTOR_DEPTH: 8
  };

  // ==================== 工具函数 ====================

  /**
   * 判断元素是否在视口内可见
   * @param {Element} element - 目标元素
   * @returns {boolean} 是否可见
   */
  function isVisible(element) {
    if (!element || !element.getBoundingClientRect) return false;

    // 检查元素是否在 DOM 中
    if (!document.body.contains(element)) return false;

    // 检查 display 和 visibility
    var style = window.getComputedStyle(element);
    if (style.display === 'none') return false;
    if (style.visibility === 'hidden') return false;
    if (style.visibility === 'collapse') return false;

    // 检查 opacity
    var opacity = parseFloat(style.opacity);
    if (isNaN(opacity) || opacity < CONFIG.VISIBILITY_THRESHOLD) return false;

    // 检查尺寸
    var rect = element.getBoundingClientRect();
    if (rect.width < CONFIG.MIN_VISIBLE_SIZE || rect.height < CONFIG.MIN_VISIBLE_SIZE) return false;

    // 检查是否在视口内（至少部分可见）
    var viewportWidth = window.innerWidth || document.documentElement.clientWidth;
    var viewportHeight = window.innerHeight || document.documentElement.clientHeight;

    if (rect.right < 0 || rect.left > viewportWidth) return false;
    if (rect.bottom < 0 || rect.top > viewportHeight) return false;

    // 检查是否被其他元素遮挡
    var centerX = rect.left + rect.width / 2;
    var centerY = rect.top + rect.height / 2;
    var topElement = document.elementFromPoint(centerX, centerY);

    if (topElement && topElement !== element) {
      // 检查遮挡元素是否允许穿透
      if (!element.contains(topElement)) {
        var topStyle = window.getComputedStyle(topElement);
        var topOpacity = parseFloat(topStyle.opacity);
        var pointerEvents = topStyle.pointerEvents;

        // 如果遮挡元素是半透明或允许穿透，则不算遮挡
        if (topOpacity >= 0.5 && pointerEvents !== 'none') {
          return false;
        }
      }
    }

    return true;
  }

  /**
   * 判断元素是否可交互
   * @param {Element} element - 目标元素
   * @returns {boolean} 是否可交互
   */
  function isInteractive(element) {
    if (!element) return false;

    var tag = (element.tagName || '').toLowerCase();
    var interactiveTags = ['a', 'button', 'input', 'select', 'textarea', 'summary', 'details'];

    if (interactiveTags.indexOf(tag) !== -1) return true;

    var role = element.getAttribute('role');
    var interactiveRoles = [
      'button', 'link', 'textbox', 'checkbox', 'radio',
      'combobox', 'switch', 'menuitem', 'tab', 'option'
    ];
    if (role && interactiveRoles.indexOf(role) !== -1) return true;

    if (element.getAttribute('tabindex') !== null) return true;
    if (element.getAttribute('contenteditable') === 'true') return true;
    if (element.getAttribute('data-action')) return true;

    // 检查是否有点击事件
    if (element.onclick !== null) return true;
    if (element.style && element.style.cursor === 'pointer') return true;

    // 检查 class 中是否包含交互相关关键词
    var className = (element.className || '').toLowerCase();
    var interactiveClassPatterns = ['btn', 'button', 'click', 'link', 'submit', 'action'];
    for (var i = 0; i < interactiveClassPatterns.length; i++) {
      if (className.indexOf(interactiveClassPatterns[i]) !== -1) return true;
    }

    return false;
  }

  /**
   * 生成元素的唯一 CSS 选择器路径
   * @param {Element} element - 目标元素
   * @returns {string} CSS 选择器路径
   */
  function getSelectorPath(element) {
    if (!element || element === document.documentElement || element === document.body) {
      return '';
    }

    var parts = [];
    var current = element;
    var depth = 0;

    while (current && current !== document.documentElement && current !== document.body && depth < CONFIG.MAX_SELECTOR_DEPTH) {
      var selector = current.tagName.toLowerCase();

      // 优先使用 ID
      if (current.id) {
        selector = '#' + CSS.escape(current.id);
        parts.unshift(selector);
        break;
      }

      // 使用 class（取第一个有意义的 class）
      if (current.className && typeof current.className === 'string') {
        var classes = current.className.trim().split(/\s+/).filter(function (c) {
          return c.length > 0 && !c.startsWith('_') && !c.startsWith('ng-') && c !== 'active' && c !== 'selected';
        });
        if (classes.length > 0) {
          selector += '.' + CSS.escape(classes[0]);
        }
      }

      // 添加 nth-child 以确保唯一性
      var parent = current.parentElement;
      if (parent) {
        var siblings = Array.prototype.filter.call(parent.children, function (child) {
          return child.tagName === current.tagName;
        });
        if (siblings.length > 1) {
          var index = Array.prototype.indexOf.call(siblings, current) + 1;
          selector += ':nth-of-type(' + index + ')';
        }
      }

      parts.unshift(selector);
      current = current.parentElement;
      depth++;
    }

    return parts.join(' > ');
  }

  /**
   * 生成元素的简短选择器（用于快速匹配）
   * @param {Element} element - 目标元素
   * @returns {string} 简短选择器
   */
  function getShortSelector(element) {
    if (!element) return '';

    if (element.id) return '#' + CSS.escape(element.id);

    var tag = element.tagName.toLowerCase();
    var classes = (element.className || '').toString().trim().split(/\s+/).filter(function (c) {
      return c.length > 0 && c.length < 30;
    });

    if (classes.length > 0) {
      return tag + '.' + CSS.escape(classes[0]);
    }

    var name = element.getAttribute('name');
    if (name) return tag + '[name="' + name + '"]';

    var testId = element.getAttribute('data-testid');
    if (testId) return '[data-testid="' + testId + '"]';

    var role = element.getAttribute('role');
    if (role) return '[role="' + role + '"]';

    return tag;
  }

  /**
   * 获取元素的完整信息对象
   * @param {Element} element - 目标元素
   * @returns {Object} 元素信息
   */
  function getElementInfo(element) {
    if (!element) return null;

    var rect = element.getBoundingClientRect();
    var scrollX = window.scrollX || window.pageXOffset || 0;
    var scrollY = window.scrollY || window.pageYOffset || 0;

    return {
      // 位置和尺寸
      rect: {
        left: Math.round(rect.left * 100) / 100,
        top: Math.round(rect.top * 100) / 100,
        right: Math.round(rect.right * 100) / 100,
        bottom: Math.round(rect.bottom * 100) / 100,
        width: Math.round(rect.width * 100) / 100,
        height: Math.round(rect.height * 100) / 100,
        scrollLeft: Math.round((rect.left + scrollX) * 100) / 100,
        scrollTop: Math.round((rect.top + scrollY) * 100) / 100,
        scrollRight: Math.round((rect.right + scrollX) * 100) / 100,
        scrollBottom: Math.round((rect.bottom + scrollY) * 100) / 100
      },

      // 选择器信息
      selector: getSelectorPath(element),
      shortSelector: getShortSelector(element),

      // 元素属性
      tag: element.tagName.toLowerCase(),
      id: element.id || '',
      classNames: element.className && typeof element.className === 'string'
        ? element.className.trim().split(/\s+/).filter(function (c) { return c.length > 0; })
        : [],
      type: element.type || '',
      name: element.getAttribute('name') || '',
      href: element.href || '',
      src: element.src || '',
      alt: element.alt || '',
      placeholder: element.placeholder || '',
      value: element.value || '',
      for_: element.getAttribute('for') || '',
      action: element.getAttribute('action') || '',
      method: element.getAttribute('method') || '',

      // ARIA 属性
      ariaLabel: element.getAttribute('aria-label') || '',
      ariaRole: element.getAttribute('role') || '',
      ariaDescribedBy: element.getAttribute('aria-describedby') || '',
      ariaExpanded: element.getAttribute('aria-expanded') || '',
      ariaDisabled: element.getAttribute('aria-disabled') || '',

      // 测试属性
      testId: element.getAttribute('data-testid') || '',
      dataAction: element.getAttribute('data-action') || '',

      // 文本内容
      text: (element.textContent || '').trim().substring(0, 500),
      innerHTML: element.innerHTML ? element.innerHTML.substring(0, 200) : '',

      // 状态信息
      isVisible: isVisible(element),
      isInteractive: isInteractive(element),
      isDisabled: element.disabled || element.getAttribute('aria-disabled') === 'true',
      isChecked: element.checked || element.getAttribute('aria-checked') === 'true',
      tabIndex: element.tabIndex,

      // 表单相关
      tagName: element.tagName,

      // 样式信息
      display: window.getComputedStyle(element).display,
      cursor: window.getComputedStyle(element).cursor
    };
  }

  // ==================== 核心功能 ====================

  /**
   * 扫描页面中所有可见可交互的元素
   * @returns {Array} 元素信息数组
   */
  function scanElements() {
    var elements = document.querySelectorAll(CONFIG.ALL_SELECTORS);
    var result = [];
    var seen = new Set();

    for (var i = 0; i < elements.length; i++) {
      var el = elements[i];

      // 跳过不可见元素
      if (!isVisible(el)) continue;

      // 跳过重复元素（通过选择器去重）
      var selector = getShortSelector(el);
      if (seen.has(selector)) continue;
      seen.add(selector);

      var info = getElementInfo(el);
      if (info) {
        result.push(info);
      }
    }

    return result;
  }

  /**
   * 扫描可交互元素（精简版）
   * @returns {Array} 可交互元素信息数组
   */
  function scanInteractiveElements() {
    var elements = document.querySelectorAll(CONFIG.INTERACTIVE_SELECTORS);
    var result = [];

    for (var i = 0; i < elements.length; i++) {
      var el = elements[i];
      if (isVisible(el) && isInteractive(el)) {
        var info = getElementInfo(el);
        if (info) {
          result.push(info);
        }
      }
    }

    return result;
  }

  /**
   * 通过选择器查找元素并返回信息
   * @param {string} selector - CSS 选择器
   * @returns {Object|null} 元素信息
   */
  function findElement(selector) {
    try {
      var element = document.querySelector(selector);
      if (element && isVisible(element)) {
        return getElementInfo(element);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /**
   * 通过文本内容查找元素
   * @param {string} text - 要匹配的文本
   * @param {boolean} exact - 是否精确匹配
   * @returns {Object|null} 元素信息
   */
  function findElementByText(text, exact) {
    var allElements = document.querySelectorAll(CONFIG.ALL_SELECTORS);

    for (var i = 0; i < allElements.length; i++) {
      var el = allElements[i];
      if (!isVisible(el)) continue;

      var elText = (el.textContent || '').trim();

      if (exact) {
        if (elText === text) {
          return getElementInfo(el);
        }
      } else {
        if (elText.indexOf(text) !== -1) {
          return getElementInfo(el);
        }
      }
    }

    return null;
  }

  /**
   * 高亮指定元素
   * @param {string} selector - CSS 选择器
   * @param {Object} options - 高亮选项
   */
  function highlightElement(selector, options) {
    options = options || {};
    var color = options.color || '#38bdf8';
    var duration = options.duration || 0;
    var borderWidth = options.borderWidth || 3;

    var element = document.querySelector(selector);
    if (!element) return { success: false, error: 'Element not found' };

    element.style.outline = borderWidth + 'px solid ' + color;
    element.style.outlineOffset = '2px';
    element.style.transition = 'outline 0.3s ease';
    element.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });

    if (duration > 0) {
      setTimeout(function () {
        element.style.outline = '';
        element.style.outlineOffset = '';
      }, duration);
    }

    return { success: true };
  }

  /**
   * 移除元素高亮
   * @param {string} selector - CSS 选择器
   */
  function removeHighlight(selector) {
    var element = document.querySelector(selector);
    if (!element) return { success: false };

    element.style.outline = '';
    element.style.outlineOffset = '';
    element.style.boxShadow = '';

    return { success: true };
  }

  /**
   * 移除所有高亮
   */
  function removeAllHighlights() {
    var highlighted = document.querySelectorAll('[style*="outline"]');
    for (var i = 0; i < highlighted.length; i++) {
      highlighted[i].style.outline = '';
      highlighted[i].style.outlineOffset = '';
      highlighted[i].style.boxShadow = '';
    }
  }

  /**
   * 滚动到指定元素
   * @param {string} selector - CSS 选择器
   * @param {string} behavior - 滚动行为
   * @param {string} block - 垂直对齐方式
   */
  function scrollToElement(selector, behavior, block) {
    var element = document.querySelector(selector);
    if (!element) return { success: false };

    element.scrollIntoView({
      behavior: behavior || 'smooth',
      block: block || 'center',
      inline: 'center'
    });

    return { success: true };
  }

  /**
   * 在指定元素中输入文本
   * @param {string} selector - CSS 选择器
   * @param {string} text - 要输入的文本
   * @param {boolean} clearFirst - 是否先清空
   */
  function inputText(selector, text, clearFirst) {
    var element = document.querySelector(selector);
    if (!element) return { success: false, error: 'Element not found' };

    // 聚焦元素
    element.focus();

    // 清空现有内容
    if (clearFirst !== false) {
      element.value = '';
    }

    // 设置值
    var nativeInputValueSetter = Object.getOwnPropertyDescriptor(
      window.HTMLInputElement.prototype, 'value'
    ) || Object.getOwnPropertyDescriptor(
      window.HTMLTextAreaElement.prototype, 'value'
    );

    if (nativeInputValueSetter) {
      nativeInputValueSetter.set.call(element, text);
    } else {
      element.value = text;
    }

    // 触发事件
    element.dispatchEvent(new Event('focus', { bubbles: true }));
    element.dispatchEvent(new Event('input', { bubbles: true }));
    element.dispatchEvent(new Event('change', { bubbles: true }));
    element.dispatchEvent(new KeyboardEvent('keydown', { bubbles: true }));
    element.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true }));

    return { success: true };
  }

  /**
   * 点击指定元素
   * @param {string} selector - CSS 选择器
   */
  function clickElement(selector) {
    var element = document.querySelector(selector);
    if (!element) return { success: false, error: 'Element not found' };

    element.scrollIntoView({ behavior: 'smooth', block: 'center' });
    element.click();

    return { success: true };
  }

  // ==================== 事件监听 ====================

  /**
   * 全局点击事件监听器
   * 捕获所有点击事件并上报到 Flutter
   */
  var clickHandler = function (event) {
    var target = event.target;

    // 查找最近的交互元素
    var interactiveTarget = target;
    while (interactiveTarget && interactiveTarget !== document.body) {
      if (isInteractive(interactiveTarget)) break;
      interactiveTarget = interactiveTarget.parentElement;
    }

    var selector = interactiveTarget !== document.body
      ? getSelectorPath(interactiveTarget)
      : getSelectorPath(target);

    var info = getElementInfo(interactiveTarget !== document.body ? interactiveTarget : target);

    // 通过 JS Bridge 发送点击事件
    if (window.WebGuideBridge) {
      window.WebGuideBridge.postMessage(JSON.stringify({
        type: 'elementClicked',
        data: {
          selector: selector,
          shortSelector: info ? info.shortSelector : '',
          tag: info ? info.tag : '',
          text: info ? info.text.substring(0, 100) : '',
          rect: info ? info.rect : null,
          isInteractive: info ? info.isInteractive : false
        },
        timestamp: Date.now()
      }));
    }
  };

  // 注册全局点击监听（捕获阶段）
  document.addEventListener('click', clickHandler, true);

  // ==================== DOM 变化监听 ====================

  var domChangeTimer = null;

  var mutationObserver = new MutationObserver(function (mutations) {
    var hasRelevantChange = false;

    for (var i = 0; i < mutations.length; i++) {
      if (mutations[i].addedNodes.length > 0) {
        hasRelevantChange = true;
        break;
      }
      if (mutations[i].attributeName) {
        var attr = mutations[i].attributeName;
        if (attr === 'class' || attr === 'style' || attr === 'hidden' || attr === 'disabled') {
          hasRelevantChange = true;
          break;
        }
      }
    }

    if (hasRelevantChange) {
      // 防抖处理
      if (domChangeTimer) clearTimeout(domChangeTimer);
      domChangeTimer = setTimeout(function () {
        if (window.WebGuideBridge) {
          window.WebGuideBridge.postMessage(JSON.stringify({
            type: 'domChanged',
            data: {
              addedNodes: mutations[0].addedNodes.length,
              type: mutations[0].type
            },
            timestamp: Date.now()
          }));
        }
      }, CONFIG.DOM_CHANGE_DEBOUNCE);
    }
  });

  // 开始监听 DOM 变化
  mutationObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['class', 'style', 'hidden', 'disabled', 'aria-hidden']
  });

  // ==================== URL 变化监听 ====================

  var lastUrl = location.href;
  var urlCheckInterval = setInterval(function () {
    if (location.href !== lastUrl) {
      var oldUrl = lastUrl;
      lastUrl = location.href;

      if (window.WebGuideBridge) {
        window.WebGuideBridge.postMessage(JSON.stringify({
          type: 'urlChanged',
          data: {
            oldUrl: oldUrl,
            newUrl: lastUrl
          },
          timestamp: Date.now()
        }));
      }
    }
  }, 500);

  // ==================== 页面加载完成通知 ====================

  function notifyPageLoaded() {
    if (window.WebGuideBridge) {
      window.WebGuideBridge.postMessage(JSON.stringify({
        type: 'onPageLoaded',
        data: {
          url: window.location.href,
          title: document.title,
          referrer: document.referrer
        },
        timestamp: Date.now()
      }));
    }
  }

  // 页面加载完成时通知
  if (document.readyState === 'complete') {
    notifyPageLoaded();
  } else {
    window.addEventListener('load', notifyPageLoaded);
  }

  // ==================== 暴露全局 API ====================

  window.__webguide = {
    // 扫描功能
    scanElements: scanElements,
    scanInteractiveElements: scanInteractiveElements,
    findElement: findElement,
    findElementByText: findElementByText,

    // 元素操作
    highlightElement: highlightElement,
    removeHighlight: removeHighlight,
    removeAllHighlights: removeAllHighlights,
    scrollToElement: scrollToElement,
    inputText: inputText,
    clickElement: clickElement,

    // 工具函数
    isVisible: isVisible,
    isInteractive: isInteractive,
    getSelectorPath: getSelectorPath,
    getShortSelector: getShortSelector,
    getElementInfo: getElementInfo,

    // 配置
    config: CONFIG,

    // 清理
    destroy: function () {
      document.removeEventListener('click', clickHandler, true);
      mutationObserver.disconnect();
      clearInterval(urlCheckInterval);
      if (domChangeTimer) clearTimeout(domChangeTimer);
      window.__webguide_scanner_injected = false;
      delete window.__webguide;
    }
  };

  // 兼容旧版 API 名称
  window.__webguide_isVisible = isVisible;
  window.__webguide_isInteractive = isInteractive;
  window.__webguide_getSelector = getSelectorPath;
  window.__webguide_getElementInfo = getElementInfo;
  window.__webguide_scanElements = scanElements;

  console.log('[WebGuide Scanner] 元素扫描器注入完成 v1.0.0');
})();
