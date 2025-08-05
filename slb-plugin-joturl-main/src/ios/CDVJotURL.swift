/************** CDVJotURL.swift Cordova Plugin ************/
/**** Created by André Grillo ****/

import Foundation

@objc(JotUrlPlugin)
class JotUrlPlugin: CDVPlugin {
    
    private var linkCallbackId: String?
    
    override func pluginInitialize() {
        // Listen for custom notification for runtime deep links
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUniversalLink(notification:)),
            name: NSNotification.Name("UniversalLinkReceived"),
            object: nil
        )
    }
    
    @objc
    func startListening(_ command: CDVInvokedUrlCommand) {
        // Store callback for future deep links
        self.linkCallbackId = command.callbackId
        
        // Check if we have an initial deep link from cold start
        if let url = JotURLBridge.getInitialDeepLinkURL(), !url.isEmpty {
            // Clear it immediately after reading
            JotURLBridge.clearInitialDeepLinkURL()
            
            print("JotUrlPlugin: Found initial deep link from cold start: \(url)")
            
            // Send the initial link immediately
            let pluginResult = CDVPluginResult(status: .ok, messageAs: url)
            pluginResult?.setKeepCallbackAs(true)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        } else {
            // No initial link, just keep callback active
            let pluginResult = CDVPluginResult(status: .ok)
            pluginResult?.setKeepCallbackAs(true)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc
    func handleUniversalLink(notification: Notification) {
        // Handle runtime deep links
        guard let userInfo = notification.userInfo,
              let urlString = userInfo["url"] as? String else {
            return
        }
        
        if let callbackId = self.linkCallbackId {
            let pluginResult = CDVPluginResult(status: .ok, messageAs: urlString)
            pluginResult?.setKeepCallbackAs(true)
            DispatchQueue.main.async {
                self.commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        }
    }
    
    @objc
    func getInitialLink(_ command: CDVInvokedUrlCommand) {
        // Get initial deep link
        if let url = JotURLBridge.getInitialDeepLinkURL(), !url.isEmpty {
            let pluginResult = CDVPluginResult(status: .ok, messageAs: url)
            DispatchQueue.main.async {
                // Clear it so future calls return noResult
                JotURLBridge.clearInitialDeepLinkURL()
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        } else {
            DispatchQueue.main.async {
                self.commandDelegate.send(CDVPluginResult(status: .noResult), callbackId: command.callbackId)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
