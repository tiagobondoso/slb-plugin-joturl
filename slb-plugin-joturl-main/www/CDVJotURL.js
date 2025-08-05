var exec = require('cordova/exec');

module.exports = {
  startListening: function (success, error) {
    exec(success, error, "JotUrlPlugin", "startListening", []);
  },
  getInitialLink: function (success, error) {
    exec(success, error, "JotUrlPlugin", "getInitialLink", []);
  }
};