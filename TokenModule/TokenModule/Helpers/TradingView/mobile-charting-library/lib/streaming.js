"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.subscribeOnStream = subscribeOnStream;
exports.unsubscribeFromStream = unsubscribeFromStream;

var _helpers = require("./helpers.js");

function _createForOfIteratorHelper(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (!it) { if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e2) { throw _e2; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = it.call(o); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e3) { didErr = true; err = _e3; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var socket = io('wss://streamer.cryptocompare.com');
var channelToSubscription = new Map();
socket.on('connect', function () {
  console.log('[socket] Connected');
});
socket.on('disconnect', function (reason) {
  console.log('[socket] Disconnected:', reason);
});
socket.on('error', function (error) {
  console.log('[socket] Error:', error);
});
socket.on('m', function (data) {
  console.log('[socket] Message:', data);

  var _data$split = data.split('~'),
      _data$split2 = _slicedToArray(_data$split, 9),
      eventTypeStr = _data$split2[0],
      exchange = _data$split2[1],
      fromSymbol = _data$split2[2],
      toSymbol = _data$split2[3],
      tradeTimeStr = _data$split2[6],
      tradePriceStr = _data$split2[8];

  if (parseInt(eventTypeStr) !== 0) {
    // skip all non-TRADE events
    return;
  }

  var tradePrice = parseFloat(tradePriceStr);
  var tradeTime = parseInt(tradeTimeStr);
  var channelString = "0~".concat(exchange, "~").concat(fromSymbol, "~").concat(toSymbol);
  var subscriptionItem = channelToSubscription.get(channelString);

  if (subscriptionItem === undefined) {
    return;
  }

  var lastDailyBar = subscriptionItem.lastDailyBar;
  var nextDailyBarTime = getNextDailyBarTime(lastDailyBar.time);
  var bar;

  if (tradeTime >= nextDailyBarTime) {
    bar = {
      time: nextDailyBarTime,
      open: tradePrice,
      high: tradePrice,
      low: tradePrice,
      close: tradePrice
    };
    console.log('[socket] Generate new bar', bar);
  } else {
    bar = _objectSpread(_objectSpread({}, lastDailyBar), {}, {
      high: Math.max(lastDailyBar.high, tradePrice),
      low: Math.min(lastDailyBar.low, tradePrice),
      close: tradePrice
    });
    console.log('[socket] Update the latest bar by price', tradePrice);
  }

  subscriptionItem.lastDailyBar = bar; // send data to every subscriber of that symbol

  subscriptionItem.handlers.forEach(function (handler) {
    return handler.callback(bar);
  });
});

function getNextDailyBarTime(barTime) {
  var date = new Date(barTime * 1000);
  date.setDate(date.getDate() + 1);
  return date.getTime() / 1000;
}

function subscribeOnStream(symbolInfo, resolution, onRealtimeCallback, subscribeUID, onResetCacheNeededCallback, lastDailyBar) {
  var parsedSymbol = (0, _helpers.parseFullSymbol)(symbolInfo.full_name);
  var channelString = "0~".concat(parsedSymbol.exchange, "~").concat(parsedSymbol.fromSymbol, "~").concat(parsedSymbol.toSymbol);
  var handler = {
    id: subscribeUID,
    callback: onRealtimeCallback
  };
  var subscriptionItem = channelToSubscription.get(channelString);

  if (subscriptionItem) {
    // already subscribed to the channel, use the existing subscription
    subscriptionItem.handlers.push(handler);
    return;
  }

  subscriptionItem = {
    subscribeUID: subscribeUID,
    resolution: resolution,
    lastDailyBar: lastDailyBar,
    handlers: [handler]
  };
  channelToSubscription.set(channelString, subscriptionItem);
  console.log('[subscribeBars]: Subscribe to streaming. Channel:', channelString);
  socket.emit('SubAdd', {
    subs: [channelString]
  });
}

function unsubscribeFromStream(subscriberUID) {
  // find a subscription with id === subscriberUID
  var _iterator = _createForOfIteratorHelper(channelToSubscription.keys()),
      _step;

  try {
    for (_iterator.s(); !(_step = _iterator.n()).done;) {
      var channelString = _step.value;
      var subscriptionItem = channelToSubscription.get(channelString);
      var handlerIndex = subscriptionItem.handlers.findIndex(function (handler) {
        return handler.id === subscriberUID;
      });

      if (handlerIndex !== -1) {
        // remove from handlers
        subscriptionItem.handlers.splice(handlerIndex, 1);

        if (subscriptionItem.handlers.length === 0) {
          // unsubscribe from the channel, if it was the last handler
          console.log('[unsubscribeBars]: Unsubscribe from streaming. Channel:', channelString);
          socket.emit('SubRemove', {
            subs: [channelString]
          });
          channelToSubscription["delete"](channelString);
          break;
        }
      }
    }
  } catch (err) {
    _iterator.e(err);
  } finally {
    _iterator.f();
  }
}