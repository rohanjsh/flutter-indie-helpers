import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

/// A utility class to handle biometric authentication in Flutter apps.
/// 
/// This helper provides methods to check biometric availability,
/// authenticate users with biometrics, and manage biometric settings.
class BiometricAuthHelper {
  /// Local authentication instance
  final LocalAuthentication _localAuth;
  
  /// Shared preferences instance
  late SharedPreferences _prefs;
  
  /// Whether biometric authentication is enabled
  bool _biometricsEnabled = false;
  
  /// Whether the helper has been initialized
  bool _initialized = false;
  
  /// Singleton instance
  static final BiometricAuthHelper _instance = BiometricAuthHelper._internal();
  
  /// Get the singleton instance
  static BiometricAuthHelper get instance => _instance;
  
  /// Private constructor
  BiometricAuthHelper._internal() : _localAuth = LocalAuthentication();
  
  /// Initialize the biometric authentication helper
  Future<void> initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _biometricsEnabled = _prefs.getBool('biometrics_enabled') ?? false;
    
    _initialized = true;
  }
  
  /// Check if biometric authentication is available
  Future<BiometricAvailability> checkBiometricAvailability() async {
    if (!_initialized) await initialize();
    
    try {
      // Check if device supports biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return BiometricAvailability.notAvailable;
      }
      
      // Check which biometrics are available
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return BiometricAvailability.notAvailable;
      }
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricAvailability.faceAvailable;
      }
      
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricAvailability.fingerprintAvailable;
      }
      
      if (availableBiometrics.contains(BiometricType.iris)) {
        return BiometricAvailability.irisAvailable;
      }
      
      return BiometricAvailability.otherBiometricAvailable;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return BiometricAvailability.error;
    }
  }
  
  /// Authenticate the user with biometrics
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool sensitiveTransaction = true,
  }) async {
    if (!_initialized) await initialize();
    
    try {
      // Check if biometrics are enabled
      if (!_biometricsEnabled) {
        return BiometricAuthResult.disabled;
      }
      
      // Check if biometrics are available
      final availability = await checkBiometricAvailability();
      if (availability == BiometricAvailability.notAvailable ||
          availability == BiometricAvailability.error) {
        return BiometricAuthResult.notAvailable;
      }
      
      // Authenticate
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
        ),
      );
      
      return authenticated
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } catch (e) {
      debugPrint('Error authenticating: $e');
      
      if (e is PlatformException) {
        switch (e.code) {
          case auth_error.notAvailable:
            return BiometricAuthResult.notAvailable;
          case auth_error.notEnrolled:
            return BiometricAuthResult.notEnrolled;
          case auth_error.lockedOut:
            return BiometricAuthResult.lockedOut;
          case auth_error.permanentlyLockedOut:
            return BiometricAuthResult.permanentlyLockedOut;
          default:
            return BiometricAuthResult.error;
        }
      }
      
      return BiometricAuthResult.error;
    }
  }
  
  /// Enable biometric authentication
  Future<void> enableBiometrics() async {
    if (!_initialized) await initialize();
    
    _biometricsEnabled = true;
    await _prefs.setBool('biometrics_enabled', true);
  }
  
  /// Disable biometric authentication
  Future<void> disableBiometrics() async {
    if (!_initialized) await initialize();
    
    _biometricsEnabled = false;
    await _prefs.setBool('biometrics_enabled', false);
  }
  
  /// Check if biometric authentication is enabled
  bool get isBiometricsEnabled {
    return _biometricsEnabled;
  }
  
  /// Toggle biometric authentication
  Future<bool> toggleBiometrics() async {
    if (!_initialized) await initialize();
    
    _biometricsEnabled = !_biometricsEnabled;
    await _prefs.setBool('biometrics_enabled', _biometricsEnabled);
    
    return _biometricsEnabled;
  }
  
  /// Get the biometric type name
  String getBiometricTypeName(BiometricAvailability availability) {
    switch (availability) {
      case BiometricAvailability.faceAvailable:
        return 'Face ID';
      case BiometricAvailability.fingerprintAvailable:
        return 'Fingerprint';
      case BiometricAvailability.irisAvailable:
        return 'Iris';
      case BiometricAvailability.otherBiometricAvailable:
        return 'Biometric';
      default:
        return 'None';
    }
  }
}

/// Biometric availability enum
enum BiometricAvailability {
  notAvailable,
  faceAvailable,
  fingerprintAvailable,
  irisAvailable,
  otherBiometricAvailable,
  error,
}

/// Biometric authentication result enum
enum BiometricAuthResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  disabled,
  error,
}

/// A widget that handles biometric authentication
class BiometricAuthWidget extends StatefulWidget {
  /// Child widget to display after successful authentication
  final Widget child;
  
  /// Widget to display while authenticating
  final Widget? loadingWidget;
  
  /// Widget to display when authentication fails
  final Widget? errorWidget;
  
  /// Whether to automatically authenticate when the widget is built
  final bool autoAuthenticate;
  
  /// Authentication prompt message
  final String localizedReason;
  
  /// Whether to use error dialogs
  final bool useErrorDialogs;
  
  /// Whether to use sticky authentication
  final bool stickyAuth;
  
  /// Whether this is a sensitive transaction
  final bool sensitiveTransaction;
  
  /// Create a new biometric authentication widget
  const BiometricAuthWidget({
    Key? key,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.autoAuthenticate = true,
    this.localizedReason = 'Authenticate to continue',
    this.useErrorDialogs = true,
    this.stickyAuth = false,
    this.sensitiveTransaction = true,
  }) : super(key: key);
  
  @override
  _BiometricAuthWidgetState createState() => _BiometricAuthWidgetState();
}

class _BiometricAuthWidgetState extends State<BiometricAuthWidget> {
  /// Authentication state
  BiometricAuthResult? _authResult;
  
  /// Whether authentication is in progress
  bool _authenticating = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.autoAuthenticate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticate();
      });
    }
  }
  
  /// Authenticate the user
  Future<void> _authenticate() async {
    if (_authenticating) return;
    
    setState(() {
      _authenticating = true;
      _authResult = null;
    });
    
    final result = await BiometricAuthHelper.instance.authenticate(
      localizedReason: widget.localizedReason,
      useErrorDialogs: widget.useErrorDialogs,
      stickyAuth: widget.stickyAuth,
      sensitiveTransaction: widget.sensitiveTransaction,
    );
    
    setState(() {
      _authResult = result;
      _authenticating = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_authenticating) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }
    
    if (_authResult == BiometricAuthResult.success) {
      return widget.child;
    }
    
    return widget.errorWidget ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fingerprint,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _getErrorMessage(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _authenticate,
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
  }
  
  /// Get the error message based on the authentication result
  String _getErrorMessage() {
    switch (_authResult) {
      case BiometricAuthResult.failed:
        return 'Authentication failed. Please try again.';
      case BiometricAuthResult.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case BiometricAuthResult.notEnrolled:
        return 'No biometric credentials are enrolled on this device.';
      case BiometricAuthResult.lockedOut:
        return 'Biometric authentication is temporarily locked out due to too many failed attempts.';
      case BiometricAuthResult.permanentlyLockedOut:
        return 'Biometric authentication is permanently locked out due to too many failed attempts.';
      case BiometricAuthResult.disabled:
        return 'Biometric authentication is disabled. Please enable it in the settings.';
      case BiometricAuthResult.error:
        return 'An error occurred during authentication. Please try again.';
      default:
        return 'Please authenticate to continue.';
    }
  }
}

/// Example usage:
///
/// ```dart
/// // Initialize in main.dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize biometric authentication
///   await BiometricAuthHelper.instance.initialize();
///   
///   runApp(MyApp());
/// }
///
/// // Check if biometrics are available
/// Future<void> checkBiometrics() async {
///   final availability = await BiometricAuthHelper.instance.checkBiometricAvailability();
///   
///   switch (availability) {
///     case BiometricAvailability.faceAvailable:
///       print('Face ID is available');
///       break;
///     case BiometricAvailability.fingerprintAvailable:
///       print('Fingerprint is available');
///       break;
///     case BiometricAvailability.irisAvailable:
///       print('Iris scanner is available');
///       break;
///     case BiometricAvailability.otherBiometricAvailable:
///       print('Other biometric is available');
///       break;
///     case BiometricAvailability.notAvailable:
///       print('No biometrics are available');
///       break;
///     case BiometricAvailability.error:
///       print('Error checking biometric availability');
///       break;
///   }
/// }
///
/// // Authenticate the user
/// Future<void> authenticateUser() async {
///   final result = await BiometricAuthHelper.instance.authenticate(
///     localizedReason: 'Authenticate to access your account',
///   );
///   
///   if (result == BiometricAuthResult.success) {
///     print('Authentication successful');
///     // Proceed with the authenticated action
///   } else {
///     print('Authentication failed: $result');
///     // Handle the error
///   }
/// }
///
/// // Using the BiometricAuthWidget
/// Widget build(BuildContext context) {
///   return BiometricAuthWidget(
///     localizedReason: 'Authenticate to view your profile',
///     child: ProfileScreen(),
///     loadingWidget: Center(
///       child: Column(
///         mainAxisAlignment: MainAxisAlignment.center,
///         children: [
///           CircularProgressIndicator(),
///           SizedBox(height: 16),
///           Text('Authenticating...'),
///         ],
///       ),
///     ),
///     errorWidget: Center(
///       child: Column(
///         mainAxisAlignment: MainAxisAlignment.center,
///         children: [
///           Icon(Icons.error, size: 64, color: Colors.red),
///           SizedBox(height: 16),
///           Text('Authentication failed. Please try again.'),
///           SizedBox(height: 16),
///           ElevatedButton(
///             onPressed: () {
///               // Retry authentication
///             },
///             child: Text('Retry'),
///           ),
///         ],
///       ),
///     ),
///   );
/// }
///
/// // Toggle biometric authentication in settings
/// Widget buildSettingsScreen() {
///   return Scaffold(
///     appBar: AppBar(title: Text('Settings')),
///     body: ListView(
///       children: [
///         SwitchListTile(
///           title: Text('Enable Biometric Authentication'),
///           subtitle: Text('Use your fingerprint or face to log in'),
///           value: BiometricAuthHelper.instance.isBiometricsEnabled,
///           onChanged: (value) async {
///             if (value) {
///               await BiometricAuthHelper.instance.enableBiometrics();
///             } else {
///               await BiometricAuthHelper.instance.disableBiometrics();
///             }
///             setState(() {});
///           },
///         ),
///       ],
///     ),
///   );
/// }
/// ```
