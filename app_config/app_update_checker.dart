import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

/// A utility class to check for app updates by comparing the current app version
/// with the latest version available on the app stores.
class AppUpdateChecker {
  /// App Store ID for iOS app
  final String appStoreId;
  
  /// Package name for Android app (com.example.app)
  final String androidPackageName;
  
  /// Minimum version that should force an update
  final String? minimumVersion;

  AppUpdateChecker({
    required this.appStoreId,
    required this.androidPackageName,
    this.minimumVersion,
  });

  /// Check if an update is available
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      if (Platform.isIOS) {
        return await _checkAppStoreVersion(currentVersion);
      } else if (Platform.isAndroid) {
        return await _checkPlayStoreVersion(currentVersion);
      }
      
      return null;
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }

  /// Check App Store for iOS updates
  Future<UpdateInfo?> _checkAppStoreVersion(String currentVersion) async {
    final response = await http.get(
      Uri.parse('https://itunes.apple.com/lookup?id=$appStoreId'),
    );
    
    if (response.statusCode == 200) {
      final jsonResult = json.decode(response.body);
      if (jsonResult['resultCount'] > 0) {
        final storeVersion = jsonResult['results'][0]['version'];
        final storeUrl = jsonResult['results'][0]['trackViewUrl'];
        
        final updateNeeded = _isUpdateNeeded(currentVersion, storeVersion);
        final forceUpdate = minimumVersion != null && 
            _isUpdateNeeded(currentVersion, minimumVersion!);
            
        if (updateNeeded) {
          return UpdateInfo(
            currentVersion: currentVersion,
            storeVersion: storeVersion,
            storeUrl: storeUrl,
            forceUpdate: forceUpdate,
          );
        }
      }
    }
    
    return null;
  }

  /// Check Play Store for Android updates
  Future<UpdateInfo?> _checkPlayStoreVersion(String currentVersion) async {
    // Note: Google Play doesn't have an official API for version checking
    // This is a workaround using the web page, which might break in the future
    final response = await http.get(
      Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageName'),
    );
    
    if (response.statusCode == 200) {
      // Extract version using regex (this is fragile and may break)
      final regex = RegExp(r'Current Version.*?>(.*?)<');
      final match = regex.firstMatch(response.body);
      
      if (match != null && match.groupCount >= 1) {
        final storeVersion = match.group(1)?.trim() ?? '';
        final storeUrl = 'https://play.google.com/store/apps/details?id=$androidPackageName';
        
        final updateNeeded = _isUpdateNeeded(currentVersion, storeVersion);
        final forceUpdate = minimumVersion != null && 
            _isUpdateNeeded(currentVersion, minimumVersion!);
            
        if (updateNeeded) {
          return UpdateInfo(
            currentVersion: currentVersion,
            storeVersion: storeVersion,
            storeUrl: storeUrl,
            forceUpdate: forceUpdate,
          );
        }
      }
    }
    
    return null;
  }

  /// Compare version strings to determine if an update is needed
  bool _isUpdateNeeded(String currentVersion, String storeVersion) {
    final current = currentVersion.split('.');
    final store = storeVersion.split('.');
    
    // Compare major, minor, and patch versions
    for (int i = 0; i < current.length && i < store.length; i++) {
      final currentPart = int.tryParse(current[i]) ?? 0;
      final storePart = int.tryParse(store[i]) ?? 0;
      
      if (currentPart < storePart) {
        return true;
      } else if (currentPart > storePart) {
        return false;
      }
    }
    
    // If we get here and store has more version parts, it's newer
    return store.length > current.length;
  }

  /// Show update dialog to the user
  static Future<void> showUpdateDialog(
    BuildContext context, 
    UpdateInfo updateInfo,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AlertDialog(
        title: Text('Update Available'),
        content: Text(
          'A new version (${updateInfo.storeVersion}) is available. '
          'You are currently using version ${updateInfo.currentVersion}.'
        ),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              child: Text('Later'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          TextButton(
            child: Text('Update Now'),
            onPressed: () async {
              final url = Uri.parse(updateInfo.storeUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              
              if (!updateInfo.forceUpdate) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Model class to hold update information
class UpdateInfo {
  final String currentVersion;
  final String storeVersion;
  final String storeUrl;
  final bool forceUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.storeVersion,
    required this.storeUrl,
    this.forceUpdate = false,
  });
}

/// Example usage:
///
/// ```dart
/// void checkForUpdates(BuildContext context) async {
///   final checker = AppUpdateChecker(
///     appStoreId: '123456789',
///     androidPackageName: 'com.example.app',
///     minimumVersion: '1.0.0', // Optional: version below which updates are mandatory
///   );
///   
///   final updateInfo = await checker.checkForUpdate();
///   
///   if (updateInfo != null) {
///     AppUpdateChecker.showUpdateDialog(context, updateInfo);
///   }
/// }
/// ```
