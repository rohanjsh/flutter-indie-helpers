import 'package:firebase_analytics/firebase_analytics.dart';

/// A utility class to simplify Firebase Analytics integration in Flutter apps.
/// 
/// This helper provides standardized event tracking methods and parameter formatting
/// to ensure consistent analytics data across your application.
class AnalyticsHelper {
  final FirebaseAnalytics _analytics;
  
  /// User properties that will be included with all events
  final Map<String, String> _userProperties = {};
  
  /// Singleton instance
  static AnalyticsHelper? _instance;
  
  /// Get the singleton instance of AnalyticsHelper
  static AnalyticsHelper get instance {
    if (_instance == null) {
      throw Exception('AnalyticsHelper not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the AnalyticsHelper with a FirebaseAnalytics instance
  static void initialize(FirebaseAnalytics analytics) {
    _instance = AnalyticsHelper._internal(analytics);
  }
  
  AnalyticsHelper._internal(this._analytics);
  
  /// Set a user property that will be included with all future events
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (value == null) {
      _userProperties.remove(name);
    } else {
      _userProperties[name] = value;
    }
    
    await _analytics.setUserProperty(name: name, value: value);
  }
  
  /// Set the user ID for analytics
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
  
  /// Log a screen view event
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
      parameters: params,
    );
  }
  
  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    
    await _analytics.logEvent(
      name: name,
      parameters: params,
    );
  }
  
  /// Log when a user starts a search
  Future<void> logSearch({
    required String searchTerm,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    params['search_term'] = searchTerm;
    
    await _analytics.logSearch(
      searchTerm: searchTerm,
      parameters: params,
    );
  }
  
  /// Log when a user selects content
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    
    await _analytics.logSelectContent(
      contentType: contentType,
      itemId: itemId,
      parameters: params,
    );
  }
  
  /// Log when a user shares content
  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    params['method'] = method;
    
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
      parameters: params,
    );
  }
  
  /// Log when a user signs up
  Future<void> logSignUp({
    required String method,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    params['method'] = method;
    
    await _analytics.logSignUp(
      method: method,
      parameters: params,
    );
  }
  
  /// Log when a user logs in
  Future<void> logLogin({
    required String method,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    params['method'] = method;
    
    await _analytics.logLogin(
      method: method,
      parameters: params,
    );
  }
  
  /// Log when a user completes a purchase
  Future<void> logPurchase({
    required double value,
    required String currency,
    List<AnalyticsEventItem>? items,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    params['value'] = value;
    params['currency'] = currency;
    
    await _analytics.logPurchase(
      currency: currency,
      value: value,
      items: items,
      parameters: params,
    );
  }
  
  /// Log when a user starts the checkout process
  Future<void> logBeginCheckout({
    double? value,
    String? currency,
    List<AnalyticsEventItem>? items,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    if (value != null) params['value'] = value;
    if (currency != null) params['currency'] = currency;
    
    await _analytics.logBeginCheckout(
      value: value,
      currency: currency,
      items: items,
      parameters: params,
    );
  }
  
  /// Log when a user views an item
  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required String itemCategory,
    double? price,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    params['item_id'] = itemId;
    params['item_name'] = itemName;
    params['item_category'] = itemCategory;
    if (price != null) params['price'] = price;
    
    final items = [
      AnalyticsEventItem(
        itemId: itemId,
        itemName: itemName,
        itemCategory: itemCategory,
        price: price,
      ),
    ];
    
    await _analytics.logViewItem(
      items: items,
      parameters: params,
    );
  }
  
  /// Log when a user encounters an error
  Future<void> logError({
    required String errorCode,
    required String errorMessage,
    Map<String, dynamic>? parameters,
  }) async {
    final params = _prepareParameters(parameters);
    params['error_code'] = errorCode;
    params['error_message'] = errorMessage;
    
    await _analytics.logEvent(
      name: 'app_error',
      parameters: params,
    );
  }
  
  /// Prepare parameters by adding standard properties
  Map<String, dynamic> _prepareParameters(Map<String, dynamic>? parameters) {
    final Map<String, dynamic> params = {};
    
    // Add user properties
    for (final entry in _userProperties.entries) {
      params['user_${entry.key}'] = entry.value;
    }
    
    // Add custom parameters
    if (parameters != null) {
      params.addAll(parameters);
    }
    
    // Add timestamp
    params['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    
    return params;
  }
}

/// Example usage:
///
/// ```dart
/// // Initialize in main.dart or app startup
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   
///   // Initialize analytics helper
///   AnalyticsHelper.initialize(FirebaseAnalytics.instance);
///   
///   runApp(MyApp());
/// }
///
/// // Use in your app
/// void trackUserAction() {
///   AnalyticsHelper.instance.logEvent(
///     name: 'button_click',
///     parameters: {
///       'button_id': 'submit_form',
///       'screen': 'checkout',
///     },
///   );
/// }
/// ```
