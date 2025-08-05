#!/usr/bin/env node

/**
 * Hook to add JotURLBridge interface to the iOS Bridging Header
 * This runs after plugin installation to ensure Swift can access Objective-C bridge methods
 */

const fs = require('fs');
const path = require('path');

// Content to add to bridging header
const BRIDGE_INTERFACE = `
// Bridge class to access deep link methods from Swift
@interface JotURLBridge : NSObject
+ (NSString * _Nullable)getInitialDeepLinkURL;
+ (void)clearInitialDeepLinkURL;
+ (BOOL)hasInitialDeepLinkURL;
@end`;

// Marker to check if already added
const BRIDGE_MARKER = '@interface JotURLBridge';

module.exports = function(context) {
    console.log('JotURL Plugin: Updating iOS Bridging Header...');
    
    const projectRoot = context.opts.projectRoot;
    const platformRoot = path.join(projectRoot, 'platforms', 'ios');
    
    // Check if iOS platform exists
    if (!fs.existsSync(platformRoot)) {
        console.log('JotURL Plugin: iOS platform not found, skipping bridging header update');
        return;
    }
    
    // Find the bridging header file
    const bridgingHeaderPath = findBridgingHeader(platformRoot);
    
    if (!bridgingHeaderPath) {
        console.log('JotURL Plugin: Bridging header not found, skipping update');
        return;
    }
    
    console.log(`JotURL Plugin: Found bridging header at: ${bridgingHeaderPath}`);
    
    try {
        // Read current content
        let content = fs.readFileSync(bridgingHeaderPath, 'utf8');
        
        // Check if already added
        if (content.includes(BRIDGE_MARKER)) {
            console.log('JotURL Plugin: JotURLBridge interface already exists in bridging header');
            return;
        }
        
        // Add the bridge interface
        content += BRIDGE_INTERFACE;
        
        // Write back to file
        fs.writeFileSync(bridgingHeaderPath, content, 'utf8');
        
        console.log('JotURL Plugin: Successfully added JotURLBridge interface to bridging header');
        
    } catch (error) {
        console.error('JotURL Plugin: Error updating bridging header:', error.message);
    }
};

/**
 * Find the bridging header file in the iOS platform
 */
function findBridgingHeader(platformRoot) {
    const possiblePaths = [
        // Common bridging header patterns
        path.join(platformRoot, '*', 'Bridging-Header.h'),
        path.join(platformRoot, '*', '*-Bridging-Header.h'),
        path.join(platformRoot, '*', 'Classes', 'Bridging-Header.h'),
        path.join(platformRoot, '*', 'Classes', '*-Bridging-Header.h')
    ];
    
    // Get project name from config.xml or use wildcard
    let projectName = getProjectName(platformRoot);
    
    if (projectName) {
        // Try specific project name patterns first
        const specificPaths = [
            path.join(platformRoot, projectName, `${projectName}-Bridging-Header.h`),
            path.join(platformRoot, projectName, 'Bridging-Header.h'),
            path.join(platformRoot, projectName, 'Classes', `${projectName}-Bridging-Header.h`),
            path.join(platformRoot, projectName, 'Classes', 'Bridging-Header.h')
        ];
        
        for (const filePath of specificPaths) {
            if (fs.existsSync(filePath)) {
                return filePath;
            }
        }
    }
    
    // Fallback: search for any bridging header file
    try {
        const files = findFilesByPattern(platformRoot, /-?[Bb]ridging-[Hh]eader\.h$/);
        if (files.length > 0) {
            return files[0];
        }
    } catch (error) {
        console.log('JotURL Plugin: Error searching for bridging header:', error.message);
    }
    
    return null;
}

/**
 * Get project name from iOS platform
 */
function getProjectName(platformRoot) {
    try {
        // Look for .xcodeproj directory
        const items = fs.readdirSync(platformRoot);
        const xcodeproj = items.find(item => item.endsWith('.xcodeproj'));
        
        if (xcodeproj) {
            return xcodeproj.replace('.xcodeproj', '');
        }
    } catch (error) {
        console.log('JotURL Plugin: Could not determine project name');
    }
    
    return null;
}

/**
 * Recursively find files matching a pattern
 */
function findFilesByPattern(dir, pattern) {
    let results = [];
    
    try {
        const items = fs.readdirSync(dir);
        
        for (const item of items) {
            const fullPath = path.join(dir, item);
            const stat = fs.statSync(fullPath);
            
            if (stat.isDirectory()) {
                // Recursively search subdirectories
                results = results.concat(findFilesByPattern(fullPath, pattern));
            } else if (pattern.test(item)) {
                results.push(fullPath);
            }
        }
    } catch (error) {
        // Ignore permission errors, etc.
    }
    
    return results;
}