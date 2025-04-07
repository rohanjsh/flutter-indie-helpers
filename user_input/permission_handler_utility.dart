import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// A utility class to handle permissions in Flutter apps.
/// 
/// This helper provides methods to request permissions, check permission status,
/// and show permission dialogs with explanations.
class PermissionHandlerUtility {
  /// Singleton instance
  static final PermissionHandlerUtility _instance = PermissionHandlerUtility._internal();
  
  /// Get the singleton instance
  static PermissionHandlerUtility get instance => _instance;
  
  /// Private constructor
  PermissionHandlerUtility._internal();
  
  /// Request a single permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return status;
    }
    
    if (status.isPermanentlyDenied) {
      return status;
    }
    
    return await permission.request();
  }
  
  /// Request multiple permissions
  Future<Map<Permission, PermissionStatus>> requestPermissions(List<Permission> permissions) async {
    final Map<Permission, PermissionStatus> statuses = {};
    
    for (final permission in permissions) {
      statuses[permission] = await requestPermission(permission);
    }
    
    return statuses;
  }
  
  /// Check if a permission is granted
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }
  
  /// Check if a permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
  
  /// Check if a permission is denied
  Future<bool> isPermissionDenied(Permission permission) async {
    final status = await permission.status;
    return status.isDenied;
  }
  
  /// Check if a permission is restricted (iOS only)
  Future<bool> isPermissionRestricted(Permission permission) async {
    final status = await permission.status;
    return status.isRestricted;
  }
  
  /// Check if a permission is limited (iOS only)
  Future<bool> isPermissionLimited(Permission permission) async {
    final status = await permission.status;
    return status.isLimited;
  }
  
  /// Open app settings
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
  
  /// Get a human-readable name for a permission
  String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.photos:
        return 'Photos';
      case Permission.storage:
        return 'Storage';
      case Permission.location:
        return 'Location';
      case Permission.locationAlways:
        return 'Location Always';
      case Permission.locationWhenInUse:
        return 'Location When In Use';
      case Permission.mediaLibrary:
        return 'Media Library';
      case Permission.microphone:
        return 'Microphone';
      case Permission.contacts:
        return 'Contacts';
      case Permission.calendar:
        return 'Calendar';
      case Permission.reminders:
        return 'Reminders';
      case Permission.speech:
        return 'Speech Recognition';
      case Permission.notification:
        return 'Notifications';
      case Permission.bluetooth:
        return 'Bluetooth';
      case Permission.appTrackingTransparency:
        return 'App Tracking';
      default:
        return permission.toString().split('.').last;
    }
  }
  
  /// Get a description for a permission
  String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'This allows the app to use your camera to take photos and videos.';
      case Permission.photos:
        return 'This allows the app to access your photo library.';
      case Permission.storage:
        return 'This allows the app to read and write files on your device.';
      case Permission.location:
        return 'This allows the app to access your location.';
      case Permission.locationAlways:
        return 'This allows the app to access your location even when the app is not in use.';
      case Permission.locationWhenInUse:
        return 'This allows the app to access your location only when the app is in use.';
      case Permission.mediaLibrary:
        return 'This allows the app to access your media library.';
      case Permission.microphone:
        return 'This allows the app to record audio using your microphone.';
      case Permission.contacts:
        return 'This allows the app to access your contacts.';
      case Permission.calendar:
        return 'This allows the app to access your calendar.';
      case Permission.reminders:
        return 'This allows the app to access your reminders.';
      case Permission.speech:
        return 'This allows the app to use speech recognition.';
      case Permission.notification:
        return 'This allows the app to send you notifications.';
      case Permission.bluetooth:
        return 'This allows the app to connect to Bluetooth devices.';
      case Permission.appTrackingTransparency:
        return 'This allows the app to track your activity across other companies\' apps and websites.';
      default:
        return 'This permission is required for the app to function properly.';
    }
  }
  
  /// Show a permission dialog with an explanation
  Future<bool> showPermissionDialog(
    BuildContext context,
    Permission permission, {
    String? title,
    String? description,
    String? grantButtonText,
    String? denyButtonText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Permission Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description ?? getPermissionDescription(permission)),
            const SizedBox(height: 16),
            Text(
              'This app needs ${getPermissionName(permission)} permission to provide this feature.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(denyButtonText ?? 'Deny'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(grantButtonText ?? 'Grant'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Show a settings dialog when permission is permanently denied
  Future<bool> showSettingsDialog(
    BuildContext context,
    Permission permission, {
    String? title,
    String? description,
    String? settingsButtonText,
    String? cancelButtonText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Permission Denied'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description ??
                  'The ${getPermissionName(permission)} permission is required for this feature. '
                  'Please enable it in the app settings.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelButtonText ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(settingsButtonText ?? 'Open Settings'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      return await openAppSettings();
    }
    
    return false;
  }
  
  /// Request permission with explanation
  Future<PermissionStatus> requestPermissionWithExplanation(
    BuildContext context,
    Permission permission, {
    String? dialogTitle,
    String? dialogDescription,
    String? grantButtonText,
    String? denyButtonText,
    String? settingsTitle,
    String? settingsDescription,
    String? settingsButtonText,
    String? cancelButtonText,
  }) async {
    // Check current status
    final status = await permission.status;
    
    if (status.isGranted) {
      return status;
    }
    
    if (status.isPermanentlyDenied) {
      final openedSettings = await showSettingsDialog(
        context,
        permission,
        title: settingsTitle,
        description: settingsDescription,
        settingsButtonText: settingsButtonText,
        cancelButtonText: cancelButtonText,
      );
      
      if (openedSettings) {
        // Wait a bit for the user to change the setting
        await Future.delayed(const Duration(seconds: 2));
        return await permission.status;
      }
      
      return status;
    }
    
    // Show explanation dialog
    final shouldRequest = await showPermissionDialog(
      context,
      permission,
      title: dialogTitle,
      description: dialogDescription,
      grantButtonText: grantButtonText,
      denyButtonText: denyButtonText,
    );
    
    if (shouldRequest) {
      return await permission.request();
    }
    
    return status;
  }
}

/// A widget that requests permissions when built
class PermissionRequester extends StatefulWidget {
  final List<Permission> permissions;
  final Widget child;
  final Widget Function(BuildContext, List<Permission>)? permissionDeniedBuilder;
  final bool requestOnInit;
  
  const PermissionRequester({
    Key? key,
    required this.permissions,
    required this.child,
    this.permissionDeniedBuilder,
    this.requestOnInit = true,
  }) : super(key: key);
  
  @override
  _PermissionRequesterState createState() => _PermissionRequesterState();
}

class _PermissionRequesterState extends State<PermissionRequester> {
  late List<Permission> _deniedPermissions;
  
  @override
  void initState() {
    super.initState();
    _deniedPermissions = [];
    
    if (widget.requestOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestPermissions();
      });
    }
  }
  
  Future<void> _requestPermissions() async {
    final statuses = await PermissionHandlerUtility.instance.requestPermissions(widget.permissions);
    
    final denied = <Permission>[];
    for (final entry in statuses.entries) {
      if (!entry.value.isGranted) {
        denied.add(entry.key);
      }
    }
    
    setState(() {
      _deniedPermissions = denied;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_deniedPermissions.isNotEmpty && widget.permissionDeniedBuilder != null) {
      return widget.permissionDeniedBuilder!(context, _deniedPermissions);
    }
    
    return widget.child;
  }
}

/// Example usage:
///
/// ```dart
/// // Basic usage
/// Future<void> takePicture() async {
///   final status = await PermissionHandlerUtility.instance.requestPermission(Permission.camera);
///   
///   if (status.isGranted) {
///     // Take picture
///   } else {
///     // Show error
///   }
/// }
///
/// // With explanation dialog
/// Future<void> takePictureWithExplanation(BuildContext context) async {
///   final status = await PermissionHandlerUtility.instance.requestPermissionWithExplanation(
///     context,
///     Permission.camera,
///     dialogTitle: 'Camera Access',
///     dialogDescription: 'We need camera access to take pictures.',
///   );
///   
///   if (status.isGranted) {
///     // Take picture
///   } else {
///     // Show error
///   }
/// }
///
/// // Using PermissionRequester widget
/// Widget build(BuildContext context) {
///   return PermissionRequester(
///     permissions: [Permission.camera, Permission.microphone],
///     permissionDeniedBuilder: (context, deniedPermissions) {
///       return Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: [
///             Text('The following permissions are required:'),
///             for (final permission in deniedPermissions)
///               Text(PermissionHandlerUtility.instance.getPermissionName(permission)),
///             ElevatedButton(
///               onPressed: () => openAppSettings(),
///               child: Text('Open Settings'),
///             ),
///           ],
///         ),
///       );
///     },
///     child: YourApp(),
///   );
/// }
/// ```
