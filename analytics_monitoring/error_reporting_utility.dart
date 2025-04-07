import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

/// A utility class to capture, log, and report errors in Flutter apps.
/// 
/// This helper provides methods to handle uncaught exceptions, log errors,
/// and send error reports to a backend service or analytics platform.
class ErrorReportingUtility {
  /// Function to call when an error occurs
  final Future<void> Function(ErrorReport)? _onError;
  
  /// Whether to show error dialogs to the user
  final bool _showErrorDialogs;
  
  /// Whether to log errors to the console
  final bool _logErrorsToConsole;
  
  /// Whether to log errors to a file
  final bool _logErrorsToFile;
  
  /// Maximum number of log files to keep
  final int _maxLogFiles;
  
  /// Maximum size of a log file in bytes
  final int _maxLogSizeBytes;
  
  /// Current log file
  File? _currentLogFile;
  
  /// Singleton instance
  static ErrorReportingUtility? _instance;
  
  /// Get the singleton instance
  static ErrorReportingUtility get instance {
    if (_instance == null) {
      throw Exception('ErrorReportingUtility not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the error reporting utility
  static Future<void> initialize({
    Future<void> Function(ErrorReport)? onError,
    bool showErrorDialogs = true,
    bool logErrorsToConsole = true,
    bool logErrorsToFile = true,
    int maxLogFiles = 5,
    int maxLogSizeBytes = 5 * 1024 * 1024, // 5 MB
  }) async {
    _instance = ErrorReportingUtility._internal(
      onError: onError,
      showErrorDialogs: showErrorDialogs,
      logErrorsToConsole: logErrorsToConsole,
      logErrorsToFile: logErrorsToFile,
      maxLogFiles: maxLogFiles,
      maxLogSizeBytes: maxLogSizeBytes,
    );
    
    await _instance!._initialize();
  }
  
  /// Private constructor
  ErrorReportingUtility._internal({
    Future<void> Function(ErrorReport)? onError,
    required bool showErrorDialogs,
    required bool logErrorsToConsole,
    required bool logErrorsToFile,
    required int maxLogFiles,
    required int maxLogSizeBytes,
  })  : _onError = onError,
        _showErrorDialogs = showErrorDialogs,
        _logErrorsToConsole = logErrorsToConsole,
        _logErrorsToFile = logErrorsToFile,
        _maxLogFiles = maxLogFiles,
        _maxLogSizeBytes = maxLogSizeBytes;
  
  /// Initialize the error reporting utility
  Future<void> _initialize() async {
    // Set up error handling
    FlutterError.onError = _handleFlutterError;
    
    // Set up uncaught error handling
    PlatformDispatcher.instance.onError = _handlePlatformError;
    
    // Initialize log file
    if (_logErrorsToFile) {
      await _initLogFile();
    }
    
    // Log app start
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await _getDeviceInfo();
    
    await logInfo(
      'App started',
      details: {
        'app_name': packageInfo.appName,
        'package_name': packageInfo.packageName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'device': deviceInfo,
      },
    );
  }
  
  /// Initialize the log file
  Future<void> _initLogFile() async {
    try {
      final directory = await _getLogDirectory();
      final now = DateTime.now();
      final fileName = 'app_log_${now.year}-${now.month}-${now.day}.log';
      _currentLogFile = File('${directory.path}/$fileName');
      
      // Create the file if it doesn't exist
      if (!await _currentLogFile!.exists()) {
        await _currentLogFile!.create(recursive: true);
      }
      
      // Clean up old log files
      await _cleanupOldLogFiles();
    } catch (e) {
      debugPrint('Error initializing log file: $e');
    }
  }
  
  /// Get the log directory
  Future<Directory> _getLogDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${appDocDir.path}/logs');
    
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    
    return logDir;
  }
  
  /// Clean up old log files
  Future<void> _cleanupOldLogFiles() async {
    try {
      final logDir = await _getLogDirectory();
      final files = await logDir.list().where((entity) => entity is File && entity.path.endsWith('.log')).toList();
      
      // Sort files by last modified time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      // Delete old files
      if (files.length > _maxLogFiles) {
        for (var i = _maxLogFiles; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old log files: $e');
    }
  }
  
  /// Handle Flutter errors
  void _handleFlutterError(FlutterErrorDetails details) {
    // Report to zone
    Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
  }
  
  /// Handle platform errors
  bool _handlePlatformError(Object error, StackTrace stack) {
    _reportError(error, stack);
    return true; // Let other error handlers run
  }
  
  /// Report an error
  Future<void> _reportError(Object error, StackTrace stack) async {
    try {
      // Create error report
      final report = await ErrorReport.create(
        error: error,
        stackTrace: stack,
        type: 'uncaught_exception',
      );
      
      // Log to console
      if (_logErrorsToConsole) {
        debugPrint('ERROR: ${report.error}');
        debugPrint('STACK TRACE: ${report.stackTrace}');
        debugPrint('DETAILS: ${report.details}');
      }
      
      // Log to file
      if (_logErrorsToFile && _currentLogFile != null) {
        await _writeToLogFile(
          'ERROR',
          report.error.toString(),
          details: report.details,
          stackTrace: report.stackTrace,
        );
      }
      
      // Call error handler
      if (_onError != null) {
        await _onError!(report);
      }
    } catch (e) {
      debugPrint('Error in error reporter: $e');
    }
  }
  
  /// Log an error
  Future<void> logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) async {
    try {
      // Create error report
      final report = await ErrorReport.create(
        error: error ?? message,
        stackTrace: stackTrace ?? StackTrace.current,
        type: 'logged_error',
        details: details,
      );
      
      // Log to console
      if (_logErrorsToConsole) {
        debugPrint('ERROR: $message');
        if (error != null) debugPrint('EXCEPTION: $error');
        if (stackTrace != null) debugPrint('STACK TRACE: $stackTrace');
        if (details != null) debugPrint('DETAILS: $details');
      }
      
      // Log to file
      if (_logErrorsToFile && _currentLogFile != null) {
        await _writeToLogFile(
          'ERROR',
          message,
          details: details,
          error: error,
          stackTrace: stackTrace,
        );
      }
      
      // Call error handler
      if (_onError != null) {
        await _onError!(report);
      }
    } catch (e) {
      debugPrint('Error in error logger: $e');
    }
  }
  
  /// Log a warning
  Future<void> logWarning(
    String message, {
    Map<String, dynamic>? details,
  }) async {
    try {
      // Log to console
      if (_logErrorsToConsole) {
        debugPrint('WARNING: $message');
        if (details != null) debugPrint('DETAILS: $details');
      }
      
      // Log to file
      if (_logErrorsToFile && _currentLogFile != null) {
        await _writeToLogFile('WARNING', message, details: details);
      }
    } catch (e) {
      debugPrint('Error in warning logger: $e');
    }
  }
  
  /// Log an info message
  Future<void> logInfo(
    String message, {
    Map<String, dynamic>? details,
  }) async {
    try {
      // Log to console
      if (_logErrorsToConsole) {
        debugPrint('INFO: $message');
        if (details != null) debugPrint('DETAILS: $details');
      }
      
      // Log to file
      if (_logErrorsToFile && _currentLogFile != null) {
        await _writeToLogFile('INFO', message, details: details);
      }
    } catch (e) {
      debugPrint('Error in info logger: $e');
    }
  }
  
  /// Write to the log file
  Future<void> _writeToLogFile(
    String level,
    String message, {
    Map<String, dynamic>? details,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    try {
      if (_currentLogFile == null) return;
      
      // Check file size
      final fileStats = await _currentLogFile!.stat();
      if (fileStats.size > _maxLogSizeBytes) {
        // Create a new log file
        await _initLogFile();
      }
      
      // Format log entry
      final now = DateTime.now().toIso8601String();
      final buffer = StringBuffer();
      buffer.writeln('[$now] $level: $message');
      
      if (error != null) {
        buffer.writeln('Exception: $error');
      }
      
      if (stackTrace != null) {
        buffer.writeln('Stack Trace: $stackTrace');
      }
      
      if (details != null) {
        buffer.writeln('Details: ${jsonEncode(details)}');
      }
      
      buffer.writeln('---');
      
      // Write to file
      await _currentLogFile!.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }
  
  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final result = <String, dynamic>{};
    
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        result['os'] = 'Android';
        result['os_version'] = info.version.release;
        result['device'] = info.model;
        result['manufacturer'] = info.manufacturer;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        result['os'] = 'iOS';
        result['os_version'] = info.systemVersion;
        result['device'] = info.model;
        result['manufacturer'] = 'Apple';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    
    return result;
  }
  
  /// Show an error dialog to the user
  Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? buttonText,
  }) async {
    if (!_showErrorDialogs) return;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText ?? 'OK'),
          ),
        ],
      ),
    );
  }
  
  /// Get all log files
  Future<List<File>> getLogFiles() async {
    try {
      final logDir = await _getLogDirectory();
      final files = await logDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .map((entity) => entity as File)
          .toList();
      
      // Sort files by last modified time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      debugPrint('Error getting log files: $e');
      return [];
    }
  }
  
  /// Get the contents of a log file
  Future<String> getLogFileContents(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      debugPrint('Error reading log file: $e');
      return 'Error reading log file: $e';
    }
  }
  
  /// Delete all log files
  Future<void> deleteAllLogFiles() async {
    try {
      final files = await getLogFiles();
      for (final file in files) {
        await file.delete();
      }
      
      // Create a new log file
      await _initLogFile();
    } catch (e) {
      debugPrint('Error deleting log files: $e');
    }
  }
}

/// Class to represent an error report
class ErrorReport {
  final Object error;
  final StackTrace stackTrace;
  final String type;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  
  ErrorReport({
    required this.error,
    required this.stackTrace,
    required this.type,
    required this.details,
    required this.timestamp,
  });
  
  /// Create an error report
  static Future<ErrorReport> create({
    required Object error,
    required StackTrace stackTrace,
    required String type,
    Map<String, dynamic>? details,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await _getDeviceInfo();
    
    final reportDetails = <String, dynamic>{
      'app_name': packageInfo.appName,
      'package_name': packageInfo.packageName,
      'version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'device': deviceInfo,
      ...?details,
    };
    
    return ErrorReport(
      error: error,
      stackTrace: stackTrace,
      type: type,
      details: reportDetails,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get device information
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final result = <String, dynamic>{};
    
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        result['os'] = 'Android';
        result['os_version'] = info.version.release;
        result['device'] = info.model;
        result['manufacturer'] = info.manufacturer;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        result['os'] = 'iOS';
        result['os_version'] = info.systemVersion;
        result['device'] = info.model;
        result['manufacturer'] = 'Apple';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    
    return result;
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'error': error.toString(),
      'stack_trace': stackTrace.toString(),
      'type': type,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// A widget that catches errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object, StackTrace)? fallbackBuilder;
  
  const ErrorBoundary({
    Key? key,
    required this.child,
    this.fallbackBuilder,
  }) : super(key: key);
  
  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // If a fallback builder is provided, use it
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(context, _error!, _stackTrace!);
      }
      
      // Default fallback
      return Material(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _stackTrace = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    // No error, show the child
    return ErrorWidget.builder = (details) {
      // Capture the error
      _captureError(details.exception, details.stack ?? StackTrace.empty);
      
      // Return an empty container to be replaced by our error UI
      return Container();
    };
  }
  
  /// Capture an error
  void _captureError(Object error, StackTrace stackTrace) {
    // Log the error
    ErrorReportingUtility.instance.logError(
      'Widget error',
      error: error,
      stackTrace: stackTrace,
    );
    
    // Update state to show error UI
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });
  }
}

/// Example usage:
///
/// ```dart
/// // Initialize in main.dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize error reporting
///   await ErrorReportingUtility.initialize(
///     onError: (report) async {
///       // Send error to your backend or analytics service
///       await sendErrorToBackend(report);
///     },
///     showErrorDialogs: true,
///     logErrorsToConsole: true,
///     logErrorsToFile: true,
///   );
///   
///   // Wrap your app in a zone to catch all errors
///   runZonedGuarded(
///     () => runApp(MyApp()),
///     (error, stackTrace) {
///       // This will be called for any uncaught errors
///       ErrorReportingUtility.instance.logError(
///         'Uncaught error',
///         error: error,
///         stackTrace: stackTrace,
///       );
///     },
///   );
/// }
///
/// // Use in your app
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: ErrorBoundary(
///         child: HomeScreen(),
///       ),
///     );
///   }
/// }
///
/// // Log errors, warnings, and info
/// void someFunction() {
///   try {
///     // Some code that might throw an error
///   } catch (e, stack) {
///     ErrorReportingUtility.instance.logError(
///       'Failed to do something',
///       error: e,
///       stackTrace: stack,
///       details: {'action': 'someFunction'},
///     );
///   }
///   
///   // Log warnings
///   ErrorReportingUtility.instance.logWarning(
///     'Something unusual happened',
///     details: {'value': 'unexpected'},
///   );
///   
///   // Log info
///   ErrorReportingUtility.instance.logInfo(
///     'User performed action',
///     details: {'action': 'button_click'},
///   );
/// }
/// ```
