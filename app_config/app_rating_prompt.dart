import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

/// A utility class to prompt users to rate your app at appropriate times.
/// 
/// This helper provides methods to show rating prompts based on app usage,
/// track user interactions, and avoid annoying users with too many prompts.
class AppRatingPrompt {
  /// Shared preferences instance
  late SharedPreferences _prefs;
  
  /// In-app review instance
  final InAppReview _inAppReview = InAppReview.instance;
  
  /// Minimum number of app launches before showing the prompt
  final int _minLaunches;
  
  /// Minimum number of days since first launch before showing the prompt
  final int _minDaysSinceFirstLaunch;
  
  /// Minimum number of days between prompts
  final int _minDaysBetweenPrompts;
  
  /// Whether to use the native in-app review flow
  final bool _useNativeFlow;
  
  /// Whether the prompt has been initialized
  bool _initialized = false;
  
  /// Singleton instance
  static AppRatingPrompt? _instance;
  
  /// Get the singleton instance
  static AppRatingPrompt get instance {
    if (_instance == null) {
      throw Exception('AppRatingPrompt not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the rating prompt
  static Future<void> initialize({
    int minLaunches = 5,
    int minDaysSinceFirstLaunch = 7,
    int minDaysBetweenPrompts = 90,
    bool useNativeFlow = true,
  }) async {
    _instance = AppRatingPrompt._internal(
      minLaunches: minLaunches,
      minDaysSinceFirstLaunch: minDaysSinceFirstLaunch,
      minDaysBetweenPrompts: minDaysBetweenPrompts,
      useNativeFlow: useNativeFlow,
    );
    
    await _instance!._initialize();
  }
  
  /// Private constructor
  AppRatingPrompt._internal({
    required int minLaunches,
    required int minDaysSinceFirstLaunch,
    required int minDaysBetweenPrompts,
    required bool useNativeFlow,
  })  : _minLaunches = minLaunches,
        _minDaysSinceFirstLaunch = minDaysSinceFirstLaunch,
        _minDaysBetweenPrompts = minDaysBetweenPrompts,
        _useNativeFlow = useNativeFlow;
  
  /// Initialize the rating prompt
  Future<void> _initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize first launch date if not set
    if (!_prefs.containsKey('app_rating_first_launch')) {
      await _prefs.setString('app_rating_first_launch', DateTime.now().toIso8601String());
    }
    
    // Increment launch count
    final launchCount = _prefs.getInt('app_rating_launch_count') ?? 0;
    await _prefs.setInt('app_rating_launch_count', launchCount + 1);
    
    _initialized = true;
  }
  
  /// Check if the app should show a rating prompt
  Future<bool> shouldShowRatingPrompt() async {
    if (!_initialized) return false;
    
    // Check if the user has opted out of rating prompts
    if (_prefs.getBool('app_rating_opted_out') == true) {
      return false;
    }
    
    // Check if the user has already rated the app
    if (_prefs.getBool('app_rating_already_rated') == true) {
      return false;
    }
    
    // Check launch count
    final launchCount = _prefs.getInt('app_rating_launch_count') ?? 0;
    if (launchCount < _minLaunches) {
      return false;
    }
    
    // Check days since first launch
    final firstLaunchStr = _prefs.getString('app_rating_first_launch');
    if (firstLaunchStr == null) {
      return false;
    }
    
    final firstLaunch = DateTime.parse(firstLaunchStr);
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
    
    if (daysSinceFirstLaunch < _minDaysSinceFirstLaunch) {
      return false;
    }
    
    // Check days since last prompt
    final lastPromptStr = _prefs.getString('app_rating_last_prompt');
    if (lastPromptStr != null) {
      final lastPrompt = DateTime.parse(lastPromptStr);
      final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
      
      if (daysSinceLastPrompt < _minDaysBetweenPrompts) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Show the rating prompt
  Future<void> showRatingPrompt(BuildContext context) async {
    if (!_initialized) return;
    
    // Update last prompt date
    await _prefs.setString('app_rating_last_prompt', DateTime.now().toIso8601String());
    
    if (_useNativeFlow) {
      await _showNativeRatingPrompt();
    } else {
      await _showCustomRatingPrompt(context);
    }
  }
  
  /// Show the native rating prompt
  Future<void> _showNativeRatingPrompt() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
      
      // We can't know if the user rated, so we just assume they did
      // This prevents showing the prompt too often
      await _prefs.setBool('app_rating_already_rated', true);
    } else {
      // Fall back to store URL if in-app review is not available
      await _openStoreUrl();
    }
  }
  
  /// Show a custom rating prompt
  Future<void> _showCustomRatingPrompt(BuildContext context) async {
    final result = await showDialog<RatingPromptResult>(
      context: context,
      builder: (context) => const RatingPromptDialog(),
    );
    
    switch (result) {
      case RatingPromptResult.rate:
        await _openStoreUrl();
        await _prefs.setBool('app_rating_already_rated', true);
        break;
      case RatingPromptResult.later:
        // Do nothing, will show again after the minimum days between prompts
        break;
      case RatingPromptResult.never:
        await _prefs.setBool('app_rating_opted_out', true);
        break;
      case null:
        // Dialog dismissed
        break;
    }
  }
  
  /// Open the app store URL
  Future<void> _openStoreUrl() async {
    try {
      if (Platform.isIOS) {
        final appId = await _getAppId();
        if (appId != null) {
          await _inAppReview.openStoreListing(appStoreId: appId);
        }
      } else if (Platform.isAndroid) {
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint('Error opening store URL: $e');
    }
  }
  
  /// Get the App Store ID
  Future<String?> _getAppId() async {
    // Try to get from shared preferences
    return _prefs.getString('app_rating_app_store_id');
  }
  
  /// Set the App Store ID (for iOS)
  Future<void> setAppStoreId(String appStoreId) async {
    await _prefs.setString('app_rating_app_store_id', appStoreId);
  }
  
  /// Reset all rating prompt data
  Future<void> reset() async {
    await _prefs.remove('app_rating_first_launch');
    await _prefs.remove('app_rating_launch_count');
    await _prefs.remove('app_rating_last_prompt');
    await _prefs.remove('app_rating_already_rated');
    await _prefs.remove('app_rating_opted_out');
    
    // Re-initialize
    await _initialize();
  }
  
  /// Mark a significant event that might be a good time to show a rating prompt
  Future<void> logSignificantEvent() async {
    if (!_initialized) return;
    
    final eventCount = _prefs.getInt('app_rating_significant_events') ?? 0;
    await _prefs.setInt('app_rating_significant_events', eventCount + 1);
  }
  
  /// Check if the app should show a rating prompt based on significant events
  Future<bool> shouldShowRatingPromptAfterEvents(int eventThreshold) async {
    if (!_initialized) return false;
    
    // First check the basic conditions
    if (!await shouldShowRatingPrompt()) {
      return false;
    }
    
    // Then check event count
    final eventCount = _prefs.getInt('app_rating_significant_events') ?? 0;
    return eventCount >= eventThreshold;
  }
}

/// Rating prompt result enum
enum RatingPromptResult {
  rate,
  later,
  never,
}

/// A custom rating prompt dialog
class RatingPromptDialog extends StatelessWidget {
  const RatingPromptDialog({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enjoying the App?'),
      content: const Text(
        'If you enjoy using this app, would you mind taking a moment to rate it? '
        'It really helps us and only takes a minute.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(RatingPromptResult.never),
          child: const Text('No, Thanks'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(RatingPromptResult.later),
          child: const Text('Maybe Later'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(RatingPromptResult.rate),
          child: const Text('Rate Now'),
        ),
      ],
    );
  }
}

/// A widget that checks if a rating prompt should be shown
class RatingPromptCheck extends StatefulWidget {
  final Widget child;
  
  const RatingPromptCheck({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  _RatingPromptCheckState createState() => _RatingPromptCheckState();
}

class _RatingPromptCheckState extends State<RatingPromptCheck> {
  @override
  void initState() {
    super.initState();
    
    // Check if we should show the rating prompt after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkRatingPrompt();
    });
  }
  
  Future<void> _checkRatingPrompt() async {
    if (await AppRatingPrompt.instance.shouldShowRatingPrompt()) {
      if (mounted) {
        await AppRatingPrompt.instance.showRatingPrompt(context);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Example usage:
///
/// ```dart
/// // In your main.dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize app rating prompt
///   await AppRatingPrompt.initialize(
///     minLaunches: 5,
///     minDaysSinceFirstLaunch: 7,
///     minDaysBetweenPrompts: 90,
///     useNativeFlow: true,
///   );
///   
///   // Set App Store ID for iOS
///   if (Platform.isIOS) {
///     await AppRatingPrompt.instance.setAppStoreId('123456789');
///   }
///   
///   runApp(MyApp());
/// }
///
/// // In your app
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: RatingPromptCheck(
///         child: HomeScreen(),
///       ),
///     );
///   }
/// }
///
/// // Or check manually at appropriate times
/// void onCompletePurchase() async {
///   // Log a significant event
///   await AppRatingPrompt.instance.logSignificantEvent();
///   
///   // Check if we should show the rating prompt after 3 significant events
///   if (await AppRatingPrompt.instance.shouldShowRatingPromptAfterEvents(3)) {
///     await AppRatingPrompt.instance.showRatingPrompt(context);
///   }
/// }
/// ```
