"use strict";

var _datafeed = _interopRequireDefault(require("./datafeed.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

// Datafeed implementation, will be added later
var params = new Proxy(new URLSearchParams(window.location.search), {
  get: function get(searchParams, prop) {
    return searchParams.get(prop);
  }
});
var value = params.symbol;
var interval = params.interval;
var fullscreen = params.fullscreen;

function initOnReady() {
  var widget = window.tvWidget = new TradingView.widget({
    symbol: value,
    // default symbol
    interval: interval,
    // default interval
    fullscreen: true,
    // displays the chart in the fullscreen mode
    allow_symbol_change: false,
    container: 'tv_chart_container',
    datafeed: _datafeed["default"],
    theme: 'Dark',
    disabled_features: ['header_compare', 'header_symbol_search', 'left_toolbar', 'header_undo_redo', 'pane_context_menu', 'main_series_scale_menu', 'items_favoriting', 'header_fullscreen_button', 'header_screenshot'],
    library_path: 'charting_library/charting_library/',
    overrides: {
      'paneProperties.legendProperties.showSeriesTitle': false
    }
  });
  widget.headerReady().then(function () {
    function addFullscreenButton() {
      var image = window.document.createElement('img');
      image.src = fullscreen == 'true' ? '../../images/close.png' : '../../images/fullscreen.png';
      image.width = 18;
      image.height = 18;
      var button = widget.createButton({
        align: 'right'
      });
      button.setAttribute('title', '');
      button.textContent = '';
      button.addEventListener('click', function () {
        window.webkit.messageHandlers.tradingView.postMessage({
          'action': 'toggleFullscreen',
          'data': {
            'fullscreen': fullscreen
          }
        });
      });
      button.appendChild(image);
    }

    addFullscreenButton();
  });
}

window.addEventListener('DOMContentLoaded', initOnReady, false);