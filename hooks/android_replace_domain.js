#!/usr/bin/env node
/**
 * Cordova hook: before_plugin_install
 * Replaces the placeholder domain in JotUrlPlugin.java with the value passed via --variable JOTURL_ASSOCIATED_DOMAIN
 */

const fs = require('fs');
const path = require('path');

module.exports = function (context) {
  const args = process.argv;
  let domain;

  // Extract the domain variable from plugin install arguments
  for (const arg of args) {
    if (arg.startsWith('JOTURL_ASSOCIATED_DOMAIN')) {
      var string = arg.split("=");
      domain = string.slice(-1).pop();
      break;
    }
  }

  if (!domain) {
    console.error('Error: JOTURL_ASSOCIATED_DOMAIN not provided.');
    return;
  }

  // Path to the Java source file
  const pluginDir = context.opts.plugin.dir;
  const javaPath = path.join(pluginDir, 'src', 'android', 'JotUrlPlugin.java');

  if (!fs.existsSync(javaPath)) {
    console.error('Error: JotUrlPlugin.java not found at', javaPath);
    return;
  }

  // Read, replace placeholder, and write back
  let content = fs.readFileSync(javaPath, 'utf8');
  const placeholder = 'JOTURL_ASSOCIATED_DOMAIN_PLACEHOLDER';
  const updated = content.replace(new RegExp(placeholder, 'g'), domain);

  fs.writeFileSync(javaPath, updated, 'utf8');
  console.log(`JotUrlPlugin: replaced placeholder with domain ${domain}`);
};
