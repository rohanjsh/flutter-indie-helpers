import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';

/// A utility class to handle deep links and app links in Flutter apps.
/// 
/// This helper provides methods to handle incoming links, parse parameters,
/// and navigate to the appropriate screens based on the link structure.
class DeepLinkHandler {
  /// Stream subscription for link changes
  StreamSubscription? _linkSubscription;
  
  /// Initial link that opened the app
  String? _initialLink;
  
  /// Whether the initial link has been processed
  bool _initialLinkProcessed = false;
  
  /// Global navigator key to access navigation from anywhere
  final GlobalKey<NavigatorState> navigatorKey;
  
  /// Map of registered link handlers
  final Map<String, LinkHandler> _handlers = {};
  
  /// Singleton instance
  static DeepLinkHandler? _instance;
  
  /// Get the singleton instance
  static DeepLinkHandler get instance {
    if (_instance == null) {
      throw Exception('DeepLinkHandler not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the deep link handler
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _instance = DeepLinkHandler._internal(navigatorKey);
  }
  
  /// Private constructor
  DeepLinkHandler._internal(this.navigatorKey) {
    _initUniLinks();
  }
  
  /// Initialize uni_links
  Future<void> _initUniLinks() async {
    // Handle initial link
    try {
      _initialLink = await getInitialLink();
      _initialLinkProcessed = false;
    } on PlatformException {
      _initialLink = null;
    }
    
    // Handle incoming links when app is already running
    _linkSubscription = linkStream.listen((String? link) {
      if (link != null) {
        _handleLink(link);
      }
    }, onError: (error) {
      debugPrint('Error handling deep link: $error');
    });
  }
  
  /// Process the initial link if it exists and hasn't been processed
  Future<bool> processInitialLink() async {
    if (_initialLink != null && !_initialLinkProcessed) {
      _initialLinkProcessed = true;
      return _handleLink(_initialLink!);
    }
    return false;
  }
  
  /// Register a link handler for a specific path pattern
  void registerHandler(String pathPattern, LinkHandler handler) {
    _handlers[pathPattern] = handler;
  }
  
  /// Unregister a link handler
  void unregisterHandler(String pathPattern) {
    _handlers.remove(pathPattern);
  }
  
  /// Handle a link by finding and executing the appropriate handler
  bool _handleLink(String link) {
    try {
      final uri = Uri.parse(link);
      final path = uri.path;
      
      // Find matching handler
      for (final entry in _handlers.entries) {
        final pattern = entry.key;
        final handler = entry.value;
        
        if (_isPathMatch(path, pattern)) {
          return handler(uri, navigatorKey);
        }
      }
      
      // No handler found
      debugPrint('No handler found for path: $path');
      return false;
    } catch (e) {
      debugPrint('Error parsing deep link: $e');
      return false;
    }
  }
  
  /// Check if a path matches a pattern
  bool _isPathMatch(String path, String pattern) {
    // Simple pattern matching
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return path == prefix || path.startsWith('$prefix/');
    }
    
    return path == pattern;
  }
  
  /// Dispose of resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}

/// Type definition for link handlers
typedef LinkHandler = bool Function(Uri uri, GlobalKey<NavigatorState> navigatorKey);

/// A mixin to add deep link handling to a StatefulWidget
mixin DeepLinkMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    
    // Process initial link after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.instance.processInitialLink();
    });
  }
}

/// A widget that handles deep links
class DeepLinkHandlerWidget extends StatefulWidget {
  final Widget child;
  
  const DeepLinkHandlerWidget({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  _DeepLinkHandlerWidgetState createState() => _DeepLinkHandlerWidgetState();
}

class _DeepLinkHandlerWidgetState extends State<DeepLinkHandlerWidget> with DeepLinkMixin {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Example usage:
///
/// ```dart
/// // In your main.dart
/// final navigatorKey = GlobalKey<NavigatorState>();
///
/// void main() {
///   // Initialize deep link handler
///   DeepLinkHandler.initialize(navigatorKey);
///   
///   // Register handlers
///   DeepLinkHandler.instance.registerHandler('/product/*', handleProductLink);
///   DeepLinkHandler.instance.registerHandler('/profile', handleProfileLink);
///   DeepLinkHandler.instance.registerHandler('/settings', handleSettingsLink);
///   
///   runApp(MyApp());
/// }
///
/// // Define link handlers
/// bool handleProductLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
///   final productId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
///   
///   if (productId != null) {
///     navigatorKey.currentState?.push(
///       MaterialPageRoute(
///         builder: (context) => ProductDetailScreen(productId: productId),
///       ),
///     );
///     return true;
///   }
///   
///   return false;
/// }
///
/// bool handleProfileLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
///   navigatorKey.currentState?.push(
///     MaterialPageRoute(
///       builder: (context) => ProfileScreen(),
///     ),
///   );
///   return true;
/// }
///
/// bool handleSettingsLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
///   navigatorKey.currentState?.push(
///     MaterialPageRoute(
///       builder: (context) => SettingsScreen(),
///     ),
///   );
///   return true;
/// }
///
/// // In your app
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       navigatorKey: navigatorKey,
///       home: DeepLinkHandlerWidget(
///         child: HomeScreen(),
///       ),
///     );
///   }
/// }
/// ```
