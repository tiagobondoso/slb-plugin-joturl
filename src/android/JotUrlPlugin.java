package com.outsystems.plugins.joturl;

import android.content.Intent;
import android.net.Uri;
import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

public class JotUrlPlugin extends CordovaPlugin {
    
    private static String initialDeepLinkURL = null;
    private static boolean hasBeenConsumed = false;
    
    private CallbackContext linkCallback;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        
        // Reset consumed flag for new plugin instance
        hasBeenConsumed = false;
        
        // Clear any previous deep link data from memory
        clearInitialDeepLink();
        
        // Check if app was launched via intent (cold start)
        Intent intent = cordova.getActivity().getIntent();
        Uri uri = intent.getData();
        
        // Only process if this is actually a deep link intent
        if (uri != null && Intent.ACTION_VIEW.equals(intent.getAction())) {
            String url = uri.toString();
            
            // Validate that this is actually your domain
            String host = uri.getHost();
            if (host != null && host.equals("JOTURL_ASSOCIATED_DOMAIN_PLACEHOLDER")) {
                setInitialDeepLink(url);
                
                System.out.println("JotUrlPlugin: App launched with deep link: " + url);
            } else {
                System.out.println("JotUrlPlugin: URI found but not matching domain: " + url);
            }
        } else {
            System.out.println("JotUrlPlugin: App launched normally (no deep link)");
        }
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if ("startListening".equals(action)) {
            // Store callback for future onNewIntent events
            this.linkCallback = callbackContext;
            
            // Check if we have an initial link and it hasn't been consumed
            if (hasInitialDeepLink() && !hasBeenConsumed) {
                String url = getInitialDeepLink();
                
                if (url != null && !url.isEmpty()) {
                    // Mark as consumed
                    hasBeenConsumed = true;
                    
                    System.out.println("JotUrlPlugin: Sending initial deep link: " + url);
                    
                    // Send the initial link
                    PluginResult result = new PluginResult(PluginResult.Status.OK, url);
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                    return true;
                }
            }
            
            // If no initial link, just set up the callback for future links
            PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);
            return true;
        }
        else if ("getInitialLink".equals(action)) {
            if (hasInitialDeepLink() && !hasBeenConsumed) {
                String url = getInitialDeepLink();
                
                if (url != null && !url.isEmpty()) {
                    // Mark as consumed and clear
                    hasBeenConsumed = true;
                    clearInitialDeepLink();
                    
                    System.out.println("JotUrlPlugin: Returning initial deep link: " + url);
                    
                    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, url));
                    return true;
                }
            }
            
            System.out.println("JotUrlPlugin: No initial deep link available");
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.NO_RESULT));
            return true;
        }
        return false;
    }

    @Override
    public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        Uri uri = intent.getData();
        
        // Only process if this is actually a deep link intent
        if (uri != null && Intent.ACTION_VIEW.equals(intent.getAction()) && linkCallback != null) {
            String host = uri.getHost();
            
            // Validate domain
            if (host != null && host.equals("JOTURL_ASSOCIATED_DOMAIN_PLACEHOLDER")) {
                final String url = uri.toString();
                
                System.out.println("JotUrlPlugin: New deep link received: " + url);
                
                PluginResult result = new PluginResult(PluginResult.Status.OK, url);
                result.setKeepCallback(true);
                
                // Send on UI thread
                cordova.getActivity().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        linkCallback.sendPluginResult(result);
                    }
                });
            } else {
                System.out.println("JotUrlPlugin: Intent received but not matching domain: " + uri.toString());
            }
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        linkCallback = null;
        // Optionally clear the static variable when plugin is destroyed
        // clearInitialDeepLink();
        // hasBeenConsumed = false;
    }

    // MARK: - Static methods for managing the initial deep link (like iOS)
    
    /**
     * Set the initial deep link URL in memory
     */
    private static void setInitialDeepLink(String url) {
        System.out.println("JotUrlPlugin: Storing initial deep link: " + url);
        initialDeepLinkURL = url;
        hasBeenConsumed = false;
    }
    
    /**
     * Get the stored initial deep link URL
     */
    private static String getInitialDeepLink() {
        return initialDeepLinkURL;
    }
    
    /**
     * Clear the initial deep link URL from memory
     */
    private static void clearInitialDeepLink() {
        System.out.println("JotUrlPlugin: Clearing initial deep link");
        initialDeepLinkURL = null;
        hasBeenConsumed = false;
    }
    
    /**
     * Check if we have an initial deep link stored
     */
    private static boolean hasInitialDeepLink() {
        return (initialDeepLinkURL != null && initialDeepLinkURL.length() > 0);
    }
}