# TradingView js library

iOS WKWebView does not support ES6, so we need convert ES6 script into ES5 by using Babel JS.

The guide can be found here: https://babeljs.io/setup#installation 

After that, combine all js file started from main.js into a single bundle.js file, by using **browserify** https://browserify.org/

The project has been set up so when there is update in `src` folder, please follow these steps

1. Convert to ES5 scripts: `./node_modules/.bin/babel src -d lib`
2. Bundle ES5 scripts: `browserify main.js -o bundle.js`
3. Push new code to remote repository

The output `bundle.js` file can be found in `dist` folder.