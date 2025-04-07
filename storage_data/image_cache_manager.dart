import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A utility class to manage image caching in Flutter apps.
/// 
/// This helper provides methods to cache images from network or assets,
/// retrieve cached images, and manage the cache size and expiration.
class ImageCacheManager {
  /// The cache directory
  late Directory _cacheDir;
  
  /// Maximum cache size in bytes (default: 100 MB)
  final int _maxCacheSize;
  
  /// Maximum age of cached files in days (default: 7 days)
  final int _maxAgeDays;
  
  /// Whether the cache has been initialized
  bool _initialized = false;
  
  /// In-memory cache for frequently accessed images
  final Map<String, Uint8List> _memoryCache = {};
  
  /// Maximum number of items in memory cache
  final int _maxMemoryCacheItems;
  
  /// Singleton instance
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  
  /// Get the singleton instance
  static ImageCacheManager get instance => _instance;
  
  /// Private constructor
  ImageCacheManager._internal({
    int maxCacheSize = 100 * 1024 * 1024, // 100 MB
    int maxAgeDays = 7,
    int maxMemoryCacheItems = 100,
  })  : _maxCacheSize = maxCacheSize,
        _maxAgeDays = maxAgeDays,
        _maxMemoryCacheItems = maxMemoryCacheItems;
  
  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Get the cache directory
    final appCacheDir = await getTemporaryDirectory();
    _cacheDir = Directory('${appCacheDir.path}/image_cache');
    
    // Create the cache directory if it doesn't exist
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    
    // Clean up the cache
    await _cleanupCache();
    
    _initialized = true;
  }
  
  /// Clean up the cache
  Future<void> _cleanupCache() async {
    try {
      // Delete expired files
      final now = DateTime.now();
      final files = await _cacheDir.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;
          
          if (age > _maxAgeDays) {
            await file.delete();
          }
        }
      }
      
      // Check cache size
      final cacheSize = await _getCacheSize();
      if (cacheSize > _maxCacheSize) {
        await _reduceCacheSize();
      }
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
  }
  
  /// Get the current cache size in bytes
  Future<int> _getCacheSize() async {
    int size = 0;
    final files = await _cacheDir.list().toList();
    
    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        size += stat.size;
      }
    }
    
    return size;
  }
  
  /// Reduce the cache size by deleting the oldest files
  Future<void> _reduceCacheSize() async {
    try {
      final files = await _cacheDir.list().toList();
      
      // Convert to list of files with their stats
      final fileStats = <MapEntry<File, FileStat>>[];
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          fileStats.add(MapEntry(entity, stat));
        }
      }
      
      // Sort by modified date (oldest first)
      fileStats.sort((a, b) => a.value.modified.compareTo(b.value.modified));
      
      // Delete oldest files until cache size is below the limit
      int currentSize = await _getCacheSize();
      int targetSize = _maxCacheSize * 3 ~/ 4; // Reduce to 75% of max
      
      for (final entry in fileStats) {
        if (currentSize <= targetSize) break;
        
        final file = entry.key;
        final size = entry.value.size;
        
        await file.delete();
        currentSize -= size;
      }
    } catch (e) {
      debugPrint('Error reducing cache size: $e');
    }
  }
  
  /// Generate a cache key for a URL or asset path
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
  
  /// Get the cache file for a URL or asset path
  File _getCacheFile(String url) {
    final key = _generateCacheKey(url);
    return File('${_cacheDir.path}/$key');
  }
  
  /// Cache an image from a URL
  Future<File> cacheImageFromUrl(String url) async {
    if (!_initialized) await initialize();
    
    final cacheFile = _getCacheFile(url);
    
    // Check if the file already exists in the cache
    if (await cacheFile.exists()) {
      // Update the last modified time
      await cacheFile.setLastModified(DateTime.now());
      return cacheFile;
    }
    
    // Download the image
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image: ${response.statusCode}');
    }
    
    // Write the image to the cache
    await cacheFile.writeAsBytes(response.bodyBytes);
    
    // Add to memory cache
    _addToMemoryCache(url, response.bodyBytes);
    
    return cacheFile;
  }
  
  /// Cache an image from asset
  Future<File> cacheImageFromAsset(String assetPath) async {
    if (!_initialized) await initialize();
    
    final cacheFile = _getCacheFile(assetPath);
    
    // Check if the file already exists in the cache
    if (await cacheFile.exists()) {
      // Update the last modified time
      await cacheFile.setLastModified(DateTime.now());
      return cacheFile;
    }
    
    // Load the asset
    final ByteData data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    
    // Write the image to the cache
    await cacheFile.writeAsBytes(bytes);
    
    // Add to memory cache
    _addToMemoryCache(assetPath, bytes);
    
    return cacheFile;
  }
  
  /// Add an image to the memory cache
  void _addToMemoryCache(String key, Uint8List bytes) {
    // Remove oldest item if cache is full
    if (_memoryCache.length >= _maxMemoryCacheItems) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
    
    // Add to memory cache
    _memoryCache[key] = bytes;
  }
  
  /// Get an image from the cache
  Future<Uint8List?> getImageFromCache(String url) async {
    if (!_initialized) await initialize();
    
    // Check memory cache first
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }
    
    final cacheFile = _getCacheFile(url);
    
    // Check if the file exists in the cache
    if (await cacheFile.exists()) {
      // Read the file
      final bytes = await cacheFile.readAsBytes();
      
      // Add to memory cache
      _addToMemoryCache(url, bytes);
      
      return bytes;
    }
    
    return null;
  }
  
  /// Clear the cache
  Future<void> clearCache() async {
    if (!_initialized) await initialize();
    
    try {
      // Clear memory cache
      _memoryCache.clear();
      
      // Delete all files in the cache directory
      final files = await _cacheDir.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
  
  /// Get the cache size in a human-readable format
  Future<String> getCacheSizeString() async {
    if (!_initialized) await initialize();
    
    final cacheSize = await _getCacheSize();
    
    if (cacheSize < 1024) {
      return '$cacheSize B';
    } else if (cacheSize < 1024 * 1024) {
      return '${(cacheSize / 1024).toStringAsFixed(2)} KB';
    } else if (cacheSize < 1024 * 1024 * 1024) {
      return '${(cacheSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(cacheSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

/// A widget that displays a cached image
class CachedNetworkImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext, String, DownloadProgress)? progressIndicatorBuilder;
  
  const CachedNetworkImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
    this.progressIndicatorBuilder,
  }) : super(key: key);
  
  @override
  _CachedNetworkImageWidgetState createState() => _CachedNetworkImageWidgetState();
}

class _CachedNetworkImageWidgetState extends State<CachedNetworkImageWidget> {
  late Future<Uint8List?> _imageFuture;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  @override
  void didUpdateWidget(CachedNetworkImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }
  
  void _loadImage() {
    _imageFuture = _getImage();
  }
  
  Future<Uint8List?> _getImage() async {
    // Check if the image is in the cache
    final cachedImage = await ImageCacheManager.instance.getImageFromCache(widget.imageUrl);
    if (cachedImage != null) {
      return cachedImage;
    }
    
    // If not, download and cache it
    try {
      final file = await ImageCacheManager.instance.cacheImageFromUrl(widget.imageUrl);
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.progressIndicatorBuilder != null
              ? widget.progressIndicatorBuilder!(
                  context,
                  widget.imageUrl,
                  DownloadProgress(widget.imageUrl, null, null),
                )
              : const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          return widget.errorBuilder != null
              ? widget.errorBuilder!(context, widget.imageUrl)
              : const Center(child: Icon(Icons.error));
        } else {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }
      },
    );
  }
}

/// Class to represent download progress
class DownloadProgress {
  final String url;
  final int? downloaded;
  final int? total;
  
  DownloadProgress(this.url, this.downloaded, this.total);
  
  double? get progress {
    if (downloaded == null || total == null) return null;
    return downloaded! / total!;
  }
}

/// Example usage:
///
/// ```dart
/// // Initialize in main.dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize image cache manager
///   await ImageCacheManager.instance.initialize();
///   
///   runApp(MyApp());
/// }
///
/// // Use the cached image widget
/// Widget build(BuildContext context) {
///   return CachedNetworkImageWidget(
///     imageUrl: 'https://example.com/image.jpg',
///     width: 200,
///     height: 200,
///     fit: BoxFit.cover,
///     progressIndicatorBuilder: (context, url, progress) {
///       return Center(
///         child: CircularProgressIndicator(
///           value: progress.progress,
///         ),
///       );
///     },
///     errorBuilder: (context, url) {
///       return Center(
///         child: Icon(Icons.error),
///       );
///     },
///   );
/// }
///
/// // Or use the cache manager directly
/// Future<void> loadAndDisplayImage() async {
///   final bytes = await ImageCacheManager.instance.getImageFromCache('https://example.com/image.jpg');
///   if (bytes == null) {
///     final file = await ImageCacheManager.instance.cacheImageFromUrl('https://example.com/image.jpg');
///     // Use the file
///   } else {
///     // Use the bytes
///   }
/// }
///
/// // Clear the cache
/// void clearCache() async {
///   await ImageCacheManager.instance.clearCache();
/// }
///
/// // Get cache size
/// void showCacheSize() async {
///   final size = await ImageCacheManager.instance.getCacheSizeString();
///   print('Cache size: $size');
/// }
/// ```
