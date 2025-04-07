import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// A utility class to manage app configuration and feature flags.
/// 
/// This helper provides methods to load configuration from various sources,
/// manage feature flags, and handle environment-specific settings.
class AppConfigManager {
  /// The current configuration
  Map<String, dynamic> _config = {};
  
  /// The current environment
  String _environment = 'development';
  
  /// Shared preferences instance
  late SharedPreferences _prefs;
  
  /// Whether the config has been initialized
  bool _initialized = false;
  
  /// Singleton instance
  static final AppConfigManager _instance = AppConfigManager._internal();
  
  /// Get the singleton instance
  static AppConfigManager get instance => _instance;
  
  /// Private constructor
  AppConfigManager._internal();
  
  /// Initialize the config manager
  Future<void> initialize({
    String environment = 'development',
    String? configAssetPath,
    String? remoteConfigUrl,
    bool useSharedPreferences = true,
    Map<String, dynamic>? defaultConfig,
  }) async {
    if (_initialized) return;
    
    _environment = environment;
    
    // Initialize shared preferences
    if (useSharedPreferences) {
      _prefs = await SharedPreferences.getInstance();
    }
    
    // Start with default config if provided
    if (defaultConfig != null) {
      _config = Map<String, dynamic>.from(defaultConfig);
    }
    
    // Load config from asset if provided
    if (configAssetPath != null) {
      await loadConfigFromAsset(configAssetPath);
    }
    
    // Load config from shared preferences
    if (useSharedPreferences) {
      await loadConfigFromSharedPreferences();
    }
    
    // Load config from remote if provided
    if (remoteConfigUrl != null) {
      await loadConfigFromRemote(remoteConfigUrl);
    }
    
    _initialized = true;
  }
  
  /// Load configuration from an asset file
  Future<void> loadConfigFromAsset(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> assetConfig = json.decode(jsonString);
      
      // Merge with existing config
      _mergeConfig(assetConfig);
    } catch (e) {
      debugPrint('Error loading config from asset: $e');
    }
  }
  
  /// Load configuration from shared preferences
  Future<void> loadConfigFromSharedPreferences() async {
    try {
      final configString = _prefs.getString('app_config');
      if (configString != null) {
        final Map<String, dynamic> savedConfig = json.decode(configString);
        
        // Merge with existing config
        _mergeConfig(savedConfig);
      }
    } catch (e) {
      debugPrint('Error loading config from shared preferences: $e');
    }
  }
  
  /// Load configuration from a remote URL
  Future<void> loadConfigFromRemote(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteConfig = json.decode(response.body);
        
        // Merge with existing config
        _mergeConfig(remoteConfig);
        
        // Save to shared preferences
        await saveConfigToSharedPreferences();
      } else {
        debugPrint('Error loading remote config: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading config from remote: $e');
    }
  }
  
  /// Save the current configuration to shared preferences
  Future<void> saveConfigToSharedPreferences() async {
    try {
      final configString = json.encode(_config);
      await _prefs.setString('app_config', configString);
    } catch (e) {
      debugPrint('Error saving config to shared preferences: $e');
    }
  }
  
  /// Merge a new configuration with the existing one
  void _mergeConfig(Map<String, dynamic> newConfig) {
    // Merge environment-specific config if available
    if (newConfig.containsKey('environments') && 
        newConfig['environments'] is Map &&
        newConfig['environments'].containsKey(_environment)) {
      
      final envConfig = newConfig['environments'][_environment];
      if (envConfig is Map) {
        // Remove environments from the new config to avoid duplication
        final configWithoutEnv = Map<String, dynamic>.from(newConfig);
        configWithoutEnv.remove('environments');
        
        // Merge the base config and environment-specific config
        _config = {
          ..._config,
          ...configWithoutEnv,
          ...envConfig,
        };
        return;
      }
    }
    
    // If no environment-specific config, just merge the whole thing
    _config = {
      ..._config,
      ...newConfig,
    };
  }
  
  /// Update a specific configuration value
  Future<void> updateConfig(String key, dynamic value) async {
    _config[key] = value;
    await saveConfigToSharedPreferences();
  }
  
  /// Update multiple configuration values
  Future<void> updateMultipleConfig(Map<String, dynamic> updates) async {
    _config = {
      ..._config,
      ...updates,
    };
    await saveConfigToSharedPreferences();
  }
  
  /// Get a configuration value
  T? get<T>(String key, {T? defaultValue}) {
    if (!_config.containsKey(key)) {
      return defaultValue;
    }
    
    final value = _config[key];
    if (value is T) {
      return value;
    }
    
    return defaultValue;
  }
  
  /// Get a nested configuration value using dot notation
  T? getNested<T>(String path, {T? defaultValue}) {
    final keys = path.split('.');
    dynamic current = _config;
    
    for (final key in keys) {
      if (current is! Map) {
        return defaultValue;
      }
      
      if (!current.containsKey(key)) {
        return defaultValue;
      }
      
      current = current[key];
    }
    
    if (current is T) {
      return current;
    }
    
    return defaultValue;
  }
  
  /// Check if a feature flag is enabled
  bool isFeatureEnabled(String featureKey, {bool defaultValue = false}) {
    return get<bool>('features.$featureKey', defaultValue: defaultValue) ?? defaultValue;
  }
  
  /// Enable or disable a feature flag
  Future<void> setFeatureEnabled(String featureKey, bool enabled) async {
    // Ensure the features map exists
    if (!_config.containsKey('features')) {
      _config['features'] = {};
    }
    
    // Update the feature flag
    _config['features'][featureKey] = enabled;
    await saveConfigToSharedPreferences();
  }
  
  /// Get the current environment
  String get environment => _environment;
  
  /// Set the current environment
  Future<void> setEnvironment(String environment) async {
    _environment = environment;
    
    // Reload configuration
    final configString = _prefs.getString('app_config');
    if (configString != null) {
      final Map<String, dynamic> savedConfig = json.decode(configString);
      
      // Reset config and merge again to apply new environment
      _config = {};
      _mergeConfig(savedConfig);
      await saveConfigToSharedPreferences();
    }
  }
  
  /// Get the entire configuration
  Map<String, dynamic> get allConfig => Map<String, dynamic>.from(_config);
  
  /// Reset the configuration to default
  Future<void> resetConfig() async {
    _config = {};
    await _prefs.remove('app_config');
  }
}

/// A widget that provides app configuration to its descendants
class AppConfigProvider extends InheritedWidget {
  final AppConfigManager config;
  
  const AppConfigProvider({
    Key? key,
    required this.config,
    required Widget child,
  }) : super(key: key, child: child);
  
  static AppConfigProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppConfigProvider>();
    if (provider == null) {
      throw Exception('No AppConfigProvider found in the widget tree');
    }
    return provider;
  }
  
  @override
  bool updateShouldNotify(AppConfigProvider oldWidget) {
    return config != oldWidget.config;
  }
}

/// A widget that conditionally shows a child based on a feature flag
class FeatureFlag extends StatelessWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;
  
  const FeatureFlag({
    Key? key,
    required this.featureKey,
    required this.child,
    this.fallback,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final config = AppConfigProvider.of(context).config;
    final isEnabled = config.isFeatureEnabled(featureKey);
    
    return isEnabled ? child : (fallback ?? Container());
  }
}

/// Example usage:
///
/// ```dart
/// // In your main.dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize app config
///   await AppConfigManager.instance.initialize(
///     environment: 'development', // or 'production', 'staging', etc.
///     configAssetPath: 'assets/config.json',
///     remoteConfigUrl: 'https://example.com/api/config',
///     defaultConfig: {
///       'api_url': 'https://api.example.com',
///       'timeout_seconds': 30,
///       'features': {
///         'dark_mode': true,
///         'premium_features': false,
///       },
///     },
///   );
///   
///   runApp(
///     AppConfigProvider(
///       config: AppConfigManager.instance,
///       child: MyApp(),
///     ),
///   );
/// }
///
/// // In your app
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final config = AppConfigProvider.of(context).config;
///     final apiUrl = config.get<String>('api_url');
///     
///     return MaterialApp(
///       title: 'My App',
///       theme: ThemeData(
///         primarySwatch: Colors.blue,
///       ),
///       home: HomeScreen(),
///     );
///   }
/// }
///
/// // Use feature flags
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Column(
///       children: [
///         Text('Welcome to the app!'),
///         
///         // Only show this widget if the feature is enabled
///         FeatureFlag(
///           featureKey: 'premium_features',
///           child: PremiumFeatureWidget(),
///           fallback: UpgradePromptWidget(),
///         ),
///       ],
///     ),
///   );
/// }
///
/// // Or check feature flags directly
/// void someFunction() {
///   if (AppConfigManager.instance.isFeatureEnabled('dark_mode')) {
///     // Enable dark mode
///   }
/// }
/// ```
