import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A utility class to manage theme switching in Flutter apps.
/// 
/// This helper provides methods to switch between light and dark themes,
/// save the theme preference, and load the saved theme on app startup.
class ThemeSwitcher extends ChangeNotifier {
  /// The current theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  /// The light theme data
  final ThemeData _lightTheme;
  
  /// The dark theme data
  final ThemeData _darkTheme;
  
  /// Whether to use the system theme
  bool _useSystemTheme = true;
  
  /// Shared preferences instance
  late SharedPreferences _prefs;
  
  /// Whether the theme switcher has been initialized
  bool _initialized = false;
  
  /// Singleton instance
  static ThemeSwitcher? _instance;
  
  /// Get the singleton instance
  static ThemeSwitcher get instance {
    if (_instance == null) {
      throw Exception('ThemeSwitcher not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the theme switcher
  static Future<ThemeSwitcher> initialize({
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    bool useSystemTheme = true,
  }) async {
    if (_instance != null) return _instance!;
    
    final prefs = await SharedPreferences.getInstance();
    
    _instance = ThemeSwitcher._internal(
      lightTheme: lightTheme ?? _defaultLightTheme,
      darkTheme: darkTheme ?? _defaultDarkTheme,
      useSystemTheme: useSystemTheme,
      prefs: prefs,
    );
    
    await _instance!._loadSavedTheme();
    
    return _instance!;
  }
  
  /// Private constructor
  ThemeSwitcher._internal({
    required ThemeData lightTheme,
    required ThemeData darkTheme,
    required bool useSystemTheme,
    required SharedPreferences prefs,
  })  : _lightTheme = lightTheme,
        _darkTheme = darkTheme,
        _useSystemTheme = useSystemTheme,
        _prefs = prefs;
  
  /// Load the saved theme
  Future<void> _loadSavedTheme() async {
    if (_initialized) return;
    
    final savedThemeMode = _prefs.getString('theme_mode');
    
    if (savedThemeMode != null) {
      switch (savedThemeMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          _useSystemTheme = false;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          _useSystemTheme = false;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          _useSystemTheme = true;
          break;
      }
    }
    
    _initialized = true;
  }
  
  /// Save the theme mode
  Future<void> _saveThemeMode(ThemeMode mode) async {
    String themeModeString;
    
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    
    await _prefs.setString('theme_mode', themeModeString);
  }
  
  /// Get the current theme mode
  ThemeMode get themeMode => _themeMode;
  
  /// Get the light theme data
  ThemeData get lightTheme => _lightTheme;
  
  /// Get the dark theme data
  ThemeData get darkTheme => _darkTheme;
  
  /// Check if the current theme is dark
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  /// Check if the current theme is light
  bool get isLightMode => !isDarkMode;
  
  /// Check if the system theme is being used
  bool get useSystemTheme => _useSystemTheme;
  
  /// Set whether to use the system theme
  Future<void> setUseSystemTheme(bool value) async {
    if (_useSystemTheme == value) return;
    
    _useSystemTheme = value;
    _themeMode = value ? ThemeMode.system : (isDarkMode ? ThemeMode.dark : ThemeMode.light);
    
    await _saveThemeMode(_themeMode);
    notifyListeners();
  }
  
  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    _useSystemTheme = mode == ThemeMode.system;
    
    await _saveThemeMode(mode);
    notifyListeners();
  }
  
  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      // If using system theme, switch to the opposite of the current system theme
      final isDark = WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
    }
  }
  
  /// Get the current theme data
  ThemeData get currentTheme => isDarkMode ? _darkTheme : _lightTheme;
  
  /// Default light theme
  static final ThemeData _defaultLightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
  
  /// Default dark theme
  static final ThemeData _defaultDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

/// A widget that provides the theme switcher to its descendants
class ThemeSwitcherProvider extends InheritedNotifier<ThemeSwitcher> {
  const ThemeSwitcherProvider({
    Key? key,
    required ThemeSwitcher notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);
  
  static ThemeSwitcher of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeSwitcherProvider>();
    if (provider == null) {
      throw Exception('No ThemeSwitcherProvider found in the widget tree');
    }
    return provider.notifier!;
  }
}

/// A widget that builds a theme toggle button
class ThemeToggleButton extends StatelessWidget {
  final IconData lightIcon;
  final IconData darkIcon;
  final IconData systemIcon;
  final Color? color;
  final double size;
  final VoidCallback? onPressed;
  
  const ThemeToggleButton({
    Key? key,
    this.lightIcon = Icons.wb_sunny,
    this.darkIcon = Icons.nightlight_round,
    this.systemIcon = Icons.settings_brightness,
    this.color,
    this.size = 24.0,
    this.onPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeSwitcher = ThemeSwitcherProvider.of(context);
    
    IconData icon;
    if (themeSwitcher.useSystemTheme) {
      icon = systemIcon;
    } else {
      icon = themeSwitcher.isDarkMode ? darkIcon : lightIcon;
    }
    
    return IconButton(
      icon: Icon(icon),
      color: color,
      iconSize: size,
      onPressed: onPressed ?? () => themeSwitcher.toggleTheme(),
    );
  }
}

/// A widget that builds a theme mode selector
class ThemeModeSelector extends StatelessWidget {
  final String lightModeText;
  final String darkModeText;
  final String systemModeText;
  
  const ThemeModeSelector({
    Key? key,
    this.lightModeText = 'Light',
    this.darkModeText = 'Dark',
    this.systemModeText = 'System',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeSwitcher = ThemeSwitcherProvider.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioListTile<ThemeMode>(
          title: Text(lightModeText),
          value: ThemeMode.light,
          groupValue: themeSwitcher.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeSwitcher.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: Text(darkModeText),
          value: ThemeMode.dark,
          groupValue: themeSwitcher.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeSwitcher.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: Text(systemModeText),
          value: ThemeMode.system,
          groupValue: themeSwitcher.themeMode,
          onChanged: (value) {
            if (value != null) {
              themeSwitcher.setThemeMode(value);
            }
          },
        ),
      ],
    );
  }
}

/// A widget that adapts its appearance based on the current theme
class ThemeAwareWidget extends StatelessWidget {
  final Widget Function(BuildContext, bool) builder;
  
  const ThemeAwareWidget({
    Key? key,
    required this.builder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeSwitcher = ThemeSwitcherProvider.of(context);
    return builder(context, themeSwitcher.isDarkMode);
  }
}

/// Example usage:
///
/// ```dart
/// // In your main.dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize theme switcher
///   final themeSwitcher = await ThemeSwitcher.initialize(
///     lightTheme: ThemeData(
///       brightness: Brightness.light,
///       primarySwatch: Colors.blue,
///       // ...
///     ),
///     darkTheme: ThemeData(
///       brightness: Brightness.dark,
///       primarySwatch: Colors.indigo,
///       // ...
///     ),
///     useSystemTheme: true,
///   );
///   
///   runApp(
///     ThemeSwitcherProvider(
///       notifier: themeSwitcher,
///       child: MyApp(),
///     ),
///   );
/// }
///
/// // In your app
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final themeSwitcher = ThemeSwitcherProvider.of(context);
///     
///     return MaterialApp(
///       title: 'My App',
///       theme: themeSwitcher.lightTheme,
///       darkTheme: themeSwitcher.darkTheme,
///       themeMode: themeSwitcher.themeMode,
///       home: HomeScreen(),
///     );
///   }
/// }
///
/// // In your home screen
/// class HomeScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text('Home'),
///         actions: [
///           ThemeToggleButton(),
///         ],
///       ),
///       body: Center(
///         child: Column(
///           mainAxisAlignment: MainAxisAlignment.center,
///           children: [
///             Text('Welcome to the app!'),
///             ElevatedButton(
///               onPressed: () {
///                 showDialog(
///                   context: context,
///                   builder: (context) => AlertDialog(
///                     title: Text('Theme Settings'),
///                     content: ThemeModeSelector(),
///                     actions: [
///                       TextButton(
///                         onPressed: () => Navigator.of(context).pop(),
///                         child: Text('Close'),
///                       ),
///                     ],
///                   ),
///                 );
///               },
///               child: Text('Theme Settings'),
///             ),
///             ThemeAwareWidget(
///               builder: (context, isDarkMode) {
///                 return Text(
///                   isDarkMode ? 'Dark Mode' : 'Light Mode',
///                   style: TextStyle(
///                     color: isDarkMode ? Colors.white : Colors.black,
///                   ),
///                 );
///               },
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
