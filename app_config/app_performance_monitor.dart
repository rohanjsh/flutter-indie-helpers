import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A utility class to monitor and log performance metrics in Flutter apps.
/// 
/// This helper provides methods to track frame build times, method execution times,
/// memory usage, and other performance metrics to help identify bottlenecks.
class AppPerformanceMonitor {
  /// Singleton instance
  static final AppPerformanceMonitor _instance = AppPerformanceMonitor._internal();
  
  /// Get the singleton instance
  static AppPerformanceMonitor get instance => _instance;
  
  /// Private constructor
  AppPerformanceMonitor._internal();
  
  /// Whether performance monitoring is enabled
  bool _isEnabled = false;
  
  /// Whether to log performance metrics to the console
  bool _logToConsole = true;
  
  /// Whether to track frame build times
  bool _trackFrames = false;
  
  /// Maximum number of metrics to keep in history
  int _maxHistorySize = 100;
  
  /// Queue to store performance metrics
  final Queue<PerformanceMetric> _metricsHistory = Queue<PerformanceMetric>();
  
  /// Map to store ongoing timers
  final Map<String, DateTime> _timers = {};
  
  /// Enable or disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    
    if (enabled && _trackFrames) {
      _startFrameTracking();
    } else if (!enabled && _trackFrames) {
      _stopFrameTracking();
    }
  }
  
  /// Set whether to log metrics to the console
  void setLogToConsole(bool logToConsole) {
    _logToConsole = logToConsole;
  }
  
  /// Set whether to track frame build times
  void setTrackFrames(bool trackFrames) {
    if (trackFrames == _trackFrames) return;
    
    _trackFrames = trackFrames;
    
    if (_isEnabled && trackFrames) {
      _startFrameTracking();
    } else if (!trackFrames) {
      _stopFrameTracking();
    }
  }
  
  /// Set the maximum number of metrics to keep in history
  void setMaxHistorySize(int maxSize) {
    _maxHistorySize = maxSize;
    _trimHistoryIfNeeded();
  }
  
  /// Start tracking frame build times
  void _startFrameTracking() {
    WidgetsBinding.instance.addTimingsCallback(_onReportTimings);
    debugPrint('Frame tracking started');
  }
  
  /// Stop tracking frame build times
  void _stopFrameTracking() {
    WidgetsBinding.instance.removeTimingsCallback(_onReportTimings);
    debugPrint('Frame tracking stopped');
  }
  
  /// Callback for frame timings
  void _onReportTimings(List<FrameTiming> timings) {
    if (!_isEnabled) return;
    
    for (final timing in timings) {
      final buildTime = timing.buildDuration.inMicroseconds / 1000.0;
      final rasterTime = timing.rasterDuration.inMicroseconds / 1000.0;
      final totalTime = buildTime + rasterTime;
      
      final metric = PerformanceMetric(
        name: 'Frame Render',
        duration: totalTime,
        type: MetricType.frame,
        details: {
          'build_time_ms': buildTime,
          'raster_time_ms': rasterTime,
          'total_time_ms': totalTime,
        },
      );
      
      _addMetric(metric);
      
      // Log slow frames (> 16ms for 60fps)
      if (totalTime > 16.0 && _logToConsole) {
        debugPrint('⚠️ Slow frame detected: ${totalTime.toStringAsFixed(2)}ms '
            '(build: ${buildTime.toStringAsFixed(2)}ms, '
            'raster: ${rasterTime.toStringAsFixed(2)}ms)');
      }
    }
  }
  
  /// Start a timer with the given name
  void startTimer(String name) {
    if (!_isEnabled) return;
    
    _timers[name] = DateTime.now();
  }
  
  /// Stop a timer with the given name and record the metric
  double stopTimer(String name, {Map<String, dynamic>? details}) {
    if (!_isEnabled || !_timers.containsKey(name)) return 0.0;
    
    final startTime = _timers.remove(name)!;
    final endTime = DateTime.now();
    final durationMs = endTime.difference(startTime).inMicroseconds / 1000.0;
    
    final metric = PerformanceMetric(
      name: name,
      duration: durationMs,
      type: MetricType.method,
      details: details ?? {},
    );
    
    _addMetric(metric);
    
    if (_logToConsole) {
      debugPrint('⏱️ $name: ${durationMs.toStringAsFixed(2)}ms');
    }
    
    return durationMs;
  }
  
  /// Track a method execution time using a callback
  Future<T> trackMethod<T>(String name, Future<T> Function() callback, {Map<String, dynamic>? details}) async {
    if (!_isEnabled) return await callback();
    
    startTimer(name);
    try {
      final result = await callback();
      stopTimer(name, details: details);
      return result;
    } catch (e) {
      stopTimer(name, details: {...?details, 'error': e.toString()});
      rethrow;
    }
  }
  
  /// Track a synchronous method execution time
  T trackMethodSync<T>(String name, T Function() callback, {Map<String, dynamic>? details}) {
    if (!_isEnabled) return callback();
    
    startTimer(name);
    try {
      final result = callback();
      stopTimer(name, details: details);
      return result;
    } catch (e) {
      stopTimer(name, details: {...?details, 'error': e.toString()});
      rethrow;
    }
  }
  
  /// Log memory usage
  void logMemoryUsage() {
    if (!_isEnabled) return;
    
    final memoryInfo = MemoryUsageInfo();
    
    final metric = PerformanceMetric(
      name: 'Memory Usage',
      duration: 0,
      type: MetricType.memory,
      details: {
        'used_heap_size': memoryInfo.usedHeapSize,
        'heap_size': memoryInfo.heapSize,
      },
    );
    
    _addMetric(metric);
    
    if (_logToConsole) {
      debugPrint('💾 Memory Usage: ${(memoryInfo.usedHeapSize / (1024 * 1024)).toStringAsFixed(2)}MB / '
          '${(memoryInfo.heapSize / (1024 * 1024)).toStringAsFixed(2)}MB');
    }
  }
  
  /// Add a custom metric
  void addCustomMetric(String name, {
    required double value,
    Map<String, dynamic>? details,
  }) {
    if (!_isEnabled) return;
    
    final metric = PerformanceMetric(
      name: name,
      duration: value,
      type: MetricType.custom,
      details: details ?? {},
    );
    
    _addMetric(metric);
    
    if (_logToConsole) {
      debugPrint('📊 $name: ${value.toStringAsFixed(2)}');
    }
  }
  
  /// Add a metric to the history
  void _addMetric(PerformanceMetric metric) {
    _metricsHistory.add(metric);
    _trimHistoryIfNeeded();
    
    // Send to DevTools timeline (only in debug mode)
    if (kDebugMode) {
      developer.Timeline.timeSync(
        metric.name,
        () {},
        arguments: metric.details,
      );
    }
  }
  
  /// Trim the history if it exceeds the maximum size
  void _trimHistoryIfNeeded() {
    while (_metricsHistory.length > _maxHistorySize) {
      _metricsHistory.removeFirst();
    }
  }
  
  /// Get all metrics in the history
  List<PerformanceMetric> getMetricsHistory() {
    return List.unmodifiable(_metricsHistory);
  }
  
  /// Get metrics of a specific type
  List<PerformanceMetric> getMetricsByType(MetricType type) {
    return _metricsHistory.where((m) => m.type == type).toList();
  }
  
  /// Get metrics with a specific name
  List<PerformanceMetric> getMetricsByName(String name) {
    return _metricsHistory.where((m) => m.name == name).toList();
  }
  
  /// Clear all metrics in the history
  void clearMetrics() {
    _metricsHistory.clear();
  }
  
  /// Get average duration for a specific metric name
  double getAverageDuration(String name) {
    final metrics = getMetricsByName(name);
    if (metrics.isEmpty) return 0.0;
    
    final total = metrics.fold<double>(0.0, (sum, metric) => sum + metric.duration);
    return total / metrics.length;
  }
  
  /// Get the performance report as a string
  String getPerformanceReport() {
    if (_metricsHistory.isEmpty) {
      return 'No performance metrics collected.';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Performance Report:');
    buffer.writeln('-------------------');
    
    // Group metrics by name
    final metricsByName = <String, List<PerformanceMetric>>{};
    for (final metric in _metricsHistory) {
      metricsByName.putIfAbsent(metric.name, () => []).add(metric);
    }
    
    // Generate report for each group
    for (final entry in metricsByName.entries) {
      final name = entry.key;
      final metrics = entry.value;
      final count = metrics.length;
      
      // Calculate statistics
      final durations = metrics.map((m) => m.duration).toList();
      durations.sort();
      
      final min = durations.first;
      final max = durations.last;
      final avg = durations.reduce((a, b) => a + b) / count;
      final median = count.isOdd
          ? durations[count ~/ 2]
          : (durations[count ~/ 2 - 1] + durations[count ~/ 2]) / 2;
      
      // Add to report
      buffer.writeln('$name:');
      buffer.writeln('  Count: $count');
      buffer.writeln('  Min: ${min.toStringAsFixed(2)}ms');
      buffer.writeln('  Max: ${max.toStringAsFixed(2)}ms');
      buffer.writeln('  Avg: ${avg.toStringAsFixed(2)}ms');
      buffer.writeln('  Median: ${median.toStringAsFixed(2)}ms');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// Types of performance metrics
enum MetricType {
  frame,
  method,
  memory,
  custom,
}

/// Class to represent a performance metric
class PerformanceMetric {
  final String name;
  final double duration;
  final MetricType type;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  
  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.type,
    required this.details,
  }) : timestamp = DateTime.now();
}

/// Class to get memory usage information
class MemoryUsageInfo {
  final int usedHeapSize;
  final int heapSize;
  
  MemoryUsageInfo()
      : usedHeapSize = _getUsedHeapSize(),
        heapSize = _getHeapSize();
  
  static int _getUsedHeapSize() {
    // This is a simplified implementation
    // In a real app, you might use platform channels to get actual memory usage
    return 0;
  }
  
  static int _getHeapSize() {
    // This is a simplified implementation
    // In a real app, you might use platform channels to get actual memory usage
    return 0;
  }
}

/// Example usage:
///
/// ```dart
/// // Initialize in main.dart or app startup
/// void main() {
///   // Enable performance monitoring in debug mode
///   if (kDebugMode) {
///     AppPerformanceMonitor.instance.setEnabled(true);
///     AppPerformanceMonitor.instance.setTrackFrames(true);
///   }
///   
///   runApp(MyApp());
/// }
///
/// // Track method execution time
/// Future<void> loadData() async {
///   await AppPerformanceMonitor.instance.trackMethod(
///     'loadData',
///     () async {
///       // Your code here
///       await Future.delayed(Duration(seconds: 1));
///       return 'Data loaded';
///     },
///   );
/// }
///
/// // Get performance report
/// void showPerformanceReport() {
///   final report = AppPerformanceMonitor.instance.getPerformanceReport();
///   print(report);
/// }
/// ```
