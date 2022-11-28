export default {
    onReady: (callback) => {
        console.log('[onReady]: Method call');
    },
    searchSymbols: (userInput, exchange, symbolType, onResultReadyCallback) => {
        console.log('[searchSymbols]: Method call');
    },
    resolveSymbol: (symbolName, onSymbolResolvedCallback, onResolveErrorCallback) => {
        console.log('[resolveSymbol]: Method call', symbolName);
    },
    getBars: (symbolInfo, resolution, periodParams, onHistoryCallback, onErrorCallback) => {
        console.log('[getBars]: Method call', symbolInfo);
    },
    subscribeBars: (symbolInfo, resolution, onRealtimeCallback, subscribeUID, onResetCacheNeededCallback) => {
        console.log('[subscribeBars]: Method call with subscribeUID:', subscribeUID);
    },
    unsubscribeBars: (subscriberUID) => {
        console.log('[unsubscribeBars]: Method call with subscriberUID:', subscriberUID);
    },
};