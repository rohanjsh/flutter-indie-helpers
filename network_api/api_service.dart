import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A utility class to handle API requests in Flutter apps.
/// 
/// This helper provides methods to make HTTP requests, handle errors,
/// and parse responses with proper error handling and logging.
class ApiService {
  /// Base URL for the API
  final String baseUrl;
  
  /// Default headers to include in all requests
  final Map<String, String> defaultHeaders;
  
  /// Default timeout duration for requests
  final Duration timeout;
  
  /// Whether to log requests and responses
  final bool enableLogging;
  
  /// Function to get the authentication token
  final Future<String?> Function()? getAuthToken;
  
  /// Function to refresh the authentication token
  final Future<String?> Function()? refreshToken;
  
  /// Function to handle unauthorized errors
  final Future<void> Function()? onUnauthorized;
  
  /// HTTP client
  final http.Client _client;
  
  /// Create a new API service
  ApiService({
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.timeout = const Duration(seconds: 30),
    this.enableLogging = false,
    this.getAuthToken,
    this.refreshToken,
    this.onUnauthorized,
    http.Client? client,
  }) : _client = client ?? http.Client();
  
  /// Dispose of resources
  void dispose() {
    _client.close();
  }
  
  /// Make a GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      'GET',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }
  
  /// Make a POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      'POST',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }
  
  /// Make a PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      'PUT',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }
  
  /// Make a PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      'PATCH',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }
  
  /// Make a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      'DELETE',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
    );
  }
  
  /// Send a request to the API
  Future<ApiResponse<T>> _sendRequest<T>(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool isRetry = false,
  }) async {
    try {
      // Build the URL
      var uri = Uri.parse('$baseUrl/$endpoint');
      
      if (queryParameters != null) {
        uri = uri.replace(queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }
      
      // Build the headers
      final requestHeaders = Map<String, String>.from(defaultHeaders);
      
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      
      // Add authentication token if required
      if (requiresAuth && getAuthToken != null) {
        final token = await getAuthToken!();
        if (token != null) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      }
      
      // Convert body to JSON if it's a Map or List
      dynamic requestBody;
      if (body != null) {
        if (body is Map || body is List) {
          requestBody = json.encode(body);
        } else {
          requestBody = body;
        }
      }
      
      // Log the request
      if (enableLogging) {
        _logRequest(method, uri, requestHeaders, requestBody);
      }
      
      // Send the request
      final response = await _sendHttpRequest(
        method,
        uri,
        requestHeaders,
        requestBody,
      ).timeout(timeout);
      
      // Log the response
      if (enableLogging) {
        _logResponse(response);
      }
      
      // Handle the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        return _handleSuccessResponse<T>(response, fromJson);
      } else if (response.statusCode == 401 && !isRetry) {
        // Unauthorized - try to refresh token and retry
        return await _handleUnauthorizedResponse<T>(
          method,
          endpoint,
          headers,
          queryParameters,
          body,
          fromJson,
          requiresAuth,
        );
      } else {
        // Error
        return _handleErrorResponse<T>(response);
      }
    } on SocketException catch (e) {
      // Network error
      return ApiResponse<T>.error(
        error: 'Network error: ${e.message}',
        statusCode: 0,
        isNetworkError: true,
      );
    } on TimeoutException catch (e) {
      // Timeout error
      return ApiResponse<T>.error(
        error: 'Request timeout: ${e.message}',
        statusCode: 0,
        isTimeoutError: true,
      );
    } catch (e) {
      // Other errors
      return ApiResponse<T>.error(
        error: 'Error: $e',
        statusCode: 0,
      );
    }
  }
  
  /// Send an HTTP request
  Future<http.Response> _sendHttpRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) async {
    switch (method) {
      case 'GET':
        return await _client.get(uri, headers: headers);
      case 'POST':
        return await _client.post(uri, headers: headers, body: body);
      case 'PUT':
        return await _client.put(uri, headers: headers, body: body);
      case 'PATCH':
        return await _client.patch(uri, headers: headers, body: body);
      case 'DELETE':
        return await _client.delete(uri, headers: headers, body: body);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
  
  /// Handle a successful response
  ApiResponse<T> _handleSuccessResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      // Parse the response body
      final dynamic responseBody = _parseResponseBody(response);
      
      // Convert to the desired type
      T? data;
      if (fromJson != null && responseBody != null) {
        data = fromJson(responseBody);
      } else if (T == String) {
        data = response.body as T;
      } else if (responseBody != null) {
        data = responseBody as T;
      }
      
      return ApiResponse<T>.success(
        data: data,
        statusCode: response.statusCode,
        headers: response.headers,
      );
    } catch (e) {
      return ApiResponse<T>.error(
        error: 'Error parsing response: $e',
        statusCode: response.statusCode,
        headers: response.headers,
      );
    }
  }
  
  /// Handle an unauthorized response
  Future<ApiResponse<T>> _handleUnauthorizedResponse<T>(
    String method,
    String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic)? fromJson,
    bool requiresAuth,
  ) async {
    // Try to refresh the token
    if (refreshToken != null) {
      final newToken = await refreshToken!();
      
      if (newToken != null) {
        // Retry the request with the new token
        return _sendRequest<T>(
          method,
          endpoint,
          headers: headers,
          queryParameters: queryParameters,
          body: body,
          fromJson: fromJson,
          requiresAuth: requiresAuth,
          isRetry: true,
        );
      }
    }
    
    // Call the onUnauthorized callback
    if (onUnauthorized != null) {
      await onUnauthorized!();
    }
    
    // Return an error response
    return ApiResponse<T>.error(
      error: 'Unauthorized',
      statusCode: 401,
      isUnauthorized: true,
    );
  }
  
  /// Handle an error response
  ApiResponse<T> _handleErrorResponse<T>(http.Response response) {
    try {
      // Parse the error response
      final dynamic responseBody = _parseResponseBody(response);
      
      // Extract the error message
      String errorMessage;
      if (responseBody is Map && responseBody.containsKey('message')) {
        errorMessage = responseBody['message'];
      } else if (responseBody is Map && responseBody.containsKey('error')) {
        errorMessage = responseBody['error'];
      } else if (responseBody is String) {
        errorMessage = responseBody;
      } else {
        errorMessage = 'Error ${response.statusCode}';
      }
      
      return ApiResponse<T>.error(
        error: errorMessage,
        statusCode: response.statusCode,
        headers: response.headers,
        rawError: responseBody,
      );
    } catch (e) {
      return ApiResponse<T>.error(
        error: 'Error ${response.statusCode}',
        statusCode: response.statusCode,
        headers: response.headers,
      );
    }
  }
  
  /// Parse the response body
  dynamic _parseResponseBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    
    final contentType = response.headers['content-type'];
    if (contentType != null && contentType.contains('application/json')) {
      return json.decode(response.body);
    }
    
    return response.body;
  }
  
  /// Log a request
  void _logRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) {
    debugPrint('┌── API Request ──────────────────────────────────────────────');
    debugPrint('│ $method $uri');
    debugPrint('│ Headers: $headers');
    if (body != null) {
      debugPrint('│ Body: $body');
    }
    debugPrint('└────────────────────────────────────────────────────────────');
  }
  
  /// Log a response
  void _logResponse(http.Response response) {
    debugPrint('┌── API Response ─────────────────────────────────────────────');
    debugPrint('│ Status: ${response.statusCode}');
    debugPrint('│ Headers: ${response.headers}');
    debugPrint('│ Body: ${response.body}');
    debugPrint('└────────────────────────────────────────────────────────────');
  }
}

/// A class to represent an API response
class ApiResponse<T> {
  /// The response data
  final T? data;
  
  /// The error message
  final String? error;
  
  /// The HTTP status code
  final int statusCode;
  
  /// The response headers
  final Map<String, String>? headers;
  
  /// The raw error response
  final dynamic rawError;
  
  /// Whether the request was successful
  final bool isSuccess;
  
  /// Whether the error is a network error
  final bool isNetworkError;
  
  /// Whether the error is a timeout error
  final bool isTimeoutError;
  
  /// Whether the error is an unauthorized error
  final bool isUnauthorized;
  
  /// Create a successful response
  ApiResponse.success({
    this.data,
    required this.statusCode,
    this.headers,
  })  : error = null,
        rawError = null,
        isSuccess = true,
        isNetworkError = false,
        isTimeoutError = false,
        isUnauthorized = false;
  
  /// Create an error response
  ApiResponse.error({
    required this.error,
    required this.statusCode,
    this.headers,
    this.rawError,
    this.isNetworkError = false,
    this.isTimeoutError = false,
    this.isUnauthorized = false,
  })  : data = null,
        isSuccess = false;
  
  /// Check if the response has data
  bool get hasData => data != null;
  
  /// Check if the response has an error
  bool get hasError => error != null;
  
  /// Get the response data or throw an error
  T get dataOrThrow {
    if (data == null) {
      throw Exception(error ?? 'No data available');
    }
    return data!;
  }
}

/// Example usage:
///
/// ```dart
/// // Create an API service
/// final apiService = ApiService(
///   baseUrl: 'https://api.example.com',
///   enableLogging: true,
///   getAuthToken: () async {
///     // Get the token from secure storage
///     return await SecureStorageHelper.instance.getString('auth_token');
///   },
///   refreshToken: () async {
///     // Refresh the token
///     final refreshToken = await SecureStorageHelper.instance.getString('refresh_token');
///     if (refreshToken == null) return null;
///     
///     // Call the refresh token endpoint
///     final response = await http.post(
///       Uri.parse('https://api.example.com/auth/refresh'),
///       body: {'refresh_token': refreshToken},
///     );
///     
///     if (response.statusCode == 200) {
///       final data = json.decode(response.body);
///       final newToken = data['access_token'];
///       
///       // Save the new token
///       await SecureStorageHelper.instance.saveString('auth_token', newToken);
///       
///       return newToken;
///     }
///     
///     return null;
///   },
///   onUnauthorized: () async {
///     // Handle unauthorized error
///     // For example, log out the user
///     await SecureStorageHelper.instance.delete('auth_token');
///     await SecureStorageHelper.instance.delete('refresh_token');
///     
///     // Navigate to login screen
///     // ...
///   },
/// );
///
/// // Define a model class
/// class User {
///   final int id;
///   final String name;
///   final String email;
///   
///   User({
///     required this.id,
///     required this.name,
///     required this.email,
///   });
///   
///   factory User.fromJson(Map<String, dynamic> json) {
///     return User(
///       id: json['id'],
///       name: json['name'],
///       email: json['email'],
///     );
///   }
/// }
///
/// // Make a GET request
/// Future<void> getUser(int userId) async {
///   final response = await apiService.get<User>(
///     'users/$userId',
///     fromJson: (json) => User.fromJson(json),
///   );
///   
///   if (response.isSuccess) {
///     final user = response.data;
///     print('User: ${user?.name}');
///   } else {
///     print('Error: ${response.error}');
///   }
/// }
///
/// // Make a POST request
/// Future<void> createUser(String name, String email, String password) async {
///   final response = await apiService.post<User>(
///     'users',
///     body: {
///       'name': name,
///       'email': email,
///       'password': password,
///     },
///     fromJson: (json) => User.fromJson(json),
///   );
///   
///   if (response.isSuccess) {
///     final user = response.data;
///     print('User created: ${user?.name}');
///   } else {
///     print('Error: ${response.error}');
///   }
/// }
///
/// // Make a PUT request
/// Future<void> updateUser(int userId, String name) async {
///   final response = await apiService.put<User>(
///     'users/$userId',
///     body: {
///       'name': name,
///     },
///     fromJson: (json) => User.fromJson(json),
///   );
///   
///   if (response.isSuccess) {
///     final user = response.data;
///     print('User updated: ${user?.name}');
///   } else {
///     print('Error: ${response.error}');
///   }
/// }
///
/// // Make a DELETE request
/// Future<void> deleteUser(int userId) async {
///   final response = await apiService.delete<void>(
///     'users/$userId',
///   );
///   
///   if (response.isSuccess) {
///     print('User deleted');
///   } else {
///     print('Error: ${response.error}');
///   }
/// }
/// ```
