import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A utility class to monitor and handle network connectivity changes in Flutter apps.
/// 
/// This helper provides methods to check network status, listen for connectivity changes,
/// and display appropriate UI elements when the network status changes.
class NetworkConnectivityMonitor {
  /// The connectivity instance
  final Connectivity _connectivity;
  
  /// Stream controller for connectivity status
  final StreamController<ConnectivityStatus> _controller = StreamController<ConnectivityStatus>.broadcast();
  
  /// Stream subscription for connectivity changes
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  /// Current connectivity status
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  
  /// Singleton instance
  static final NetworkConnectivityMonitor _instance = NetworkConnectivityMonitor._internal();
  
  /// Get the singleton instance
  static NetworkConnectivityMonitor get instance => _instance;
  
  /// Private constructor
  NetworkConnectivityMonitor._internal() : _connectivity = Connectivity() {
    // Initialize
    _init();
  }
  
  /// Initialize the connectivity monitor
  void _init() async {
    // Get initial connectivity status
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }
  
  /// Update the connectivity status
  void _updateStatus(ConnectivityResult result) {
    ConnectivityStatus status;
    
    switch (result) {
      case ConnectivityResult.wifi:
        status = ConnectivityStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        status = ConnectivityStatus.cellular;
        break;
      case ConnectivityResult.ethernet:
        status = ConnectivityStatus.ethernet;
        break;
      case ConnectivityResult.bluetooth:
        status = ConnectivityStatus.bluetooth;
        break;
      case ConnectivityResult.none:
        status = ConnectivityStatus.offline;
        break;
      default:
        status = ConnectivityStatus.unknown;
    }
    
    // Only notify if status changed
    if (status != _currentStatus) {
      _currentStatus = status;
      _controller.add(status);
    }
  }
  
  /// Get the current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;
  
  /// Check if the device is currently connected to the internet
  bool get isConnected => _currentStatus != ConnectivityStatus.offline && 
                          _currentStatus != ConnectivityStatus.unknown;
  
  /// Get a stream of connectivity status changes
  Stream<ConnectivityStatus> get onStatusChange => _controller.stream;
  
  /// Check connectivity and return the current status
  Future<ConnectivityStatus> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    return _currentStatus;
  }
  
  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.close();
  }
}

/// Connectivity status enum
enum ConnectivityStatus {
  wifi,
  cellular,
  ethernet,
  bluetooth,
  offline,
  unknown,
}

/// A widget that shows a banner when the device is offline
class OfflineBanner extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color textColor;
  final String message;
  final double height;
  
  const OfflineBanner({
    Key? key,
    required this.child,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    this.message = 'No internet connection',
    this.height = 30.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: NetworkConnectivityMonitor.instance.onStatusChange,
      initialData: NetworkConnectivityMonitor.instance.currentStatus,
      builder: (context, snapshot) {
        final isOffline = snapshot.data == ConnectivityStatus.offline;
        
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isOffline ? height : 0,
              color: backgroundColor,
              child: isOffline
                  ? Center(
                      child: Text(
                        message,
                        style: TextStyle(color: textColor),
                      ),
                    )
                  : null,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// A widget that wraps a child and shows a different widget when offline
class ConnectivityAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget offlineWidget;
  
  const ConnectivityAwareWidget({
    Key? key,
    required this.child,
    required this.offlineWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: NetworkConnectivityMonitor.instance.onStatusChange,
      initialData: NetworkConnectivityMonitor.instance.currentStatus,
      builder: (context, snapshot) {
        final isOffline = snapshot.data == ConnectivityStatus.offline;
        return isOffline ? offlineWidget : child;
      },
    );
  }
}

/// A provider that makes connectivity status available to the widget tree
class ConnectivityProvider extends InheritedWidget {
  final ConnectivityStatus connectivityStatus;
  
  const ConnectivityProvider({
    Key? key,
    required this.connectivityStatus,
    required Widget child,
  }) : super(key: key, child: child);
  
  static ConnectivityProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ConnectivityProvider>();
    if (provider == null) {
      throw Exception('No ConnectivityProvider found in the widget tree');
    }
    return provider;
  }
  
  @override
  bool updateShouldNotify(ConnectivityProvider oldWidget) {
    return connectivityStatus != oldWidget.connectivityStatus;
  }
}

/// A widget that provides connectivity status to its descendants
class ConnectivityProviderWidget extends StatefulWidget {
  final Widget child;
  
  const ConnectivityProviderWidget({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  _ConnectivityProviderWidgetState createState() => _ConnectivityProviderWidgetState();
}

class _ConnectivityProviderWidgetState extends State<ConnectivityProviderWidget> {
  late StreamSubscription<ConnectivityStatus> _subscription;
  ConnectivityStatus _status = NetworkConnectivityMonitor.instance.currentStatus;
  
  @override
  void initState() {
    super.initState();
    _subscription = NetworkConnectivityMonitor.instance.onStatusChange.listen((status) {
      setState(() {
        _status = status;
      });
    });
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ConnectivityProvider(
      connectivityStatus: _status,
      child: widget.child,
    );
  }
}

/// Example usage:
///
/// ```dart
/// // In your main.dart
/// void main() {
///   runApp(
///     ConnectivityProviderWidget(
///       child: MyApp(),
///     ),
///   );
/// }
///
/// // In your app
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         body: OfflineBanner(
///           child: MyHomePage(),
///         ),
///       ),
///     );
///   }
/// }
///
/// // Or use the connectivity-aware widget
/// Widget build(BuildContext context) {
///   return ConnectivityAwareWidget(
///     offlineWidget: Center(
///       child: Column(
///         mainAxisAlignment: MainAxisAlignment.center,
///         children: [
///           Icon(Icons.wifi_off, size: 50),
///           Text('You are offline'),
///           ElevatedButton(
///             onPressed: () async {
///               await NetworkConnectivityMonitor.instance.checkConnectivity();
///             },
///             child: Text('Retry'),
///           ),
///         ],
///       ),
///     ),
///     child: YourNormalWidget(),
///   );
/// }
///
/// // Or access the status directly
/// Widget build(BuildContext context) {
///   final status = ConnectivityProvider.of(context).connectivityStatus;
///   return Text('Current status: $status');
/// }
/// ```
