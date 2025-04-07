import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

/// A utility class to handle file picking in Flutter apps.
/// 
/// This helper provides methods to pick files, images, and videos,
/// as well as utilities to handle the picked files.
class FilePickerHelper {
  /// Image picker instance
  final ImagePicker _imagePicker;
  
  /// File picker instance
  final FilePicker _filePicker;
  
  /// Singleton instance
  static final FilePickerHelper _instance = FilePickerHelper._internal();
  
  /// Get the singleton instance
  static FilePickerHelper get instance => _instance;
  
  /// Private constructor
  FilePickerHelper._internal()
      : _imagePicker = ImagePicker(),
        _filePicker = FilePicker.platform;
  
  /// Pick a single file
  Future<PickedFile?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
    bool allowCompression = true,
  }) async {
    try {
      final result = await _filePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowCompression: allowCompression,
      );
      
      if (result == null || result.files.isEmpty) {
        return null;
      }
      
      final platformFile = result.files.first;
      
      return PickedFile(
        name: platformFile.name,
        path: platformFile.path,
        size: platformFile.size,
        extension: platformFile.extension,
        bytes: platformFile.bytes,
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }
  
  /// Pick multiple files
  Future<List<PickedFile>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
    bool allowCompression = true,
  }) async {
    try {
      final result = await _filePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowCompression: allowCompression,
        allowMultiple: true,
      );
      
      if (result == null || result.files.isEmpty) {
        return [];
      }
      
      return result.files.map((platformFile) {
        return PickedFile(
          name: platformFile.name,
          path: platformFile.path,
          size: platformFile.size,
          extension: platformFile.extension,
          bytes: platformFile.bytes,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
      return [];
    }
  }
  
  /// Pick an image from the gallery
  Future<PickedFile?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      return PickedFile(
        name: path.basename(pickedFile.path),
        path: pickedFile.path,
        size: fileSize,
        extension: path.extension(pickedFile.path).replaceFirst('.', ''),
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }
  
  /// Pick an image from the camera
  Future<PickedFile?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      return PickedFile(
        name: path.basename(pickedFile.path),
        path: pickedFile.path,
        size: fileSize,
        extension: path.extension(pickedFile.path).replaceFirst('.', ''),
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }
  
  /// Pick a video from the gallery
  Future<PickedFile?> pickVideoFromGallery({
    Duration? maxDuration,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      return PickedFile(
        name: path.basename(pickedFile.path),
        path: pickedFile.path,
        size: fileSize,
        extension: path.extension(pickedFile.path).replaceFirst('.', ''),
      );
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
      return null;
    }
  }
  
  /// Pick a video from the camera
  Future<PickedFile?> pickVideoFromCamera({
    Duration? maxDuration,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: maxDuration,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      return PickedFile(
        name: path.basename(pickedFile.path),
        path: pickedFile.path,
        size: fileSize,
        extension: path.extension(pickedFile.path).replaceFirst('.', ''),
      );
    } catch (e) {
      debugPrint('Error picking video from camera: $e');
      return null;
    }
  }
  
  /// Save a file to the app's documents directory
  Future<File?> saveFileToDocuments(PickedFile pickedFile) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final fileName = pickedFile.name;
      final filePath = path.join(documentsDir.path, fileName);
      
      if (pickedFile.bytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(pickedFile.bytes!);
        return file;
      } else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        final savedFile = await file.copy(filePath);
        return savedFile;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error saving file to documents: $e');
      return null;
    }
  }
  
  /// Save a file to a temporary directory
  Future<File?> saveFileToTemp(PickedFile pickedFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = pickedFile.name;
      final filePath = path.join(tempDir.path, fileName);
      
      if (pickedFile.bytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(pickedFile.bytes!);
        return file;
      } else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        final savedFile = await file.copy(filePath);
        return savedFile;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error saving file to temp: $e');
      return null;
    }
  }
  
  /// Get the MIME type of a file
  String? getMimeType(PickedFile pickedFile) {
    if (pickedFile.path != null) {
      return lookupMimeType(pickedFile.path!);
    } else if (pickedFile.name != null) {
      return lookupMimeType(pickedFile.name);
    }
    
    return null;
  }
  
  /// Check if a file is an image
  bool isImage(PickedFile pickedFile) {
    final mimeType = getMimeType(pickedFile);
    return mimeType != null && mimeType.startsWith('image/');
  }
  
  /// Check if a file is a video
  bool isVideo(PickedFile pickedFile) {
    final mimeType = getMimeType(pickedFile);
    return mimeType != null && mimeType.startsWith('video/');
  }
  
  /// Check if a file is an audio
  bool isAudio(PickedFile pickedFile) {
    final mimeType = getMimeType(pickedFile);
    return mimeType != null && mimeType.startsWith('audio/');
  }
  
  /// Check if a file is a PDF
  bool isPdf(PickedFile pickedFile) {
    final mimeType = getMimeType(pickedFile);
    return mimeType == 'application/pdf';
  }
  
  /// Get a human-readable file size
  String getReadableFileSize(int size) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double fileSize = size.toDouble();
    
    while (fileSize > 1024 && i < suffixes.length - 1) {
      fileSize /= 1024;
      i++;
    }
    
    return '${fileSize.toStringAsFixed(2)} ${suffixes[i]}';
  }
  
  /// Clear the cache directory
  Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File) {
          await file.delete();
        } else if (file is Directory) {
          await file.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}

/// A class to represent a picked file
class PickedFile {
  /// File name
  final String name;
  
  /// File path
  final String? path;
  
  /// File size in bytes
  final int size;
  
  /// File extension
  final String? extension;
  
  /// File bytes
  final Uint8List? bytes;
  
  /// Create a new picked file
  PickedFile({
    required this.name,
    this.path,
    required this.size,
    this.extension,
    this.bytes,
  });
  
  /// Get the file as a File object
  File? get file => path != null ? File(path!) : null;
  
  /// Get a human-readable file size
  String get readableSize => FilePickerHelper.instance.getReadableFileSize(size);
  
  /// Get the MIME type of the file
  String? get mimeType => FilePickerHelper.instance.getMimeType(this);
  
  /// Check if the file is an image
  bool get isImage => FilePickerHelper.instance.isImage(this);
  
  /// Check if the file is a video
  bool get isVideo => FilePickerHelper.instance.isVideo(this);
  
  /// Check if the file is an audio
  bool get isAudio => FilePickerHelper.instance.isAudio(this);
  
  /// Check if the file is a PDF
  bool get isPdf => FilePickerHelper.instance.isPdf(this);
}

/// A widget that displays a file picker button
class FilePickerButton extends StatelessWidget {
  /// Callback when a file is picked
  final Function(PickedFile) onFilePicked;
  
  /// Button text
  final String text;
  
  /// Button icon
  final IconData icon;
  
  /// Allowed file extensions
  final List<String>? allowedExtensions;
  
  /// File type
  final FileType type;
  
  /// Whether to allow compression
  final bool allowCompression;
  
  /// Button style
  final ButtonStyle? style;
  
  /// Create a new file picker button
  const FilePickerButton({
    Key? key,
    required this.onFilePicked,
    this.text = 'Pick File',
    this.icon = Icons.attach_file,
    this.allowedExtensions,
    this.type = FileType.any,
    this.allowCompression = true,
    this.style,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      style: style,
      onPressed: () async {
        final pickedFile = await FilePickerHelper.instance.pickFile(
          allowedExtensions: allowedExtensions,
          type: type,
          allowCompression: allowCompression,
        );
        
        if (pickedFile != null) {
          onFilePicked(pickedFile);
        }
      },
    );
  }
}

/// A widget that displays an image picker button
class ImagePickerButton extends StatelessWidget {
  /// Callback when an image is picked
  final Function(PickedFile) onImagePicked;
  
  /// Button text
  final String text;
  
  /// Button icon
  final IconData icon;
  
  /// Maximum width of the image
  final double? maxWidth;
  
  /// Maximum height of the image
  final double? maxHeight;
  
  /// Image quality (0-100)
  final int? imageQuality;
  
  /// Whether to pick from camera
  final bool fromCamera;
  
  /// Button style
  final ButtonStyle? style;
  
  /// Create a new image picker button
  const ImagePickerButton({
    Key? key,
    required this.onImagePicked,
    this.text = 'Pick Image',
    this.icon = Icons.image,
    this.maxWidth,
    this.maxHeight,
    this.imageQuality,
    this.fromCamera = false,
    this.style,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      style: style,
      onPressed: () async {
        final pickedFile = fromCamera
            ? await FilePickerHelper.instance.pickImageFromCamera(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                imageQuality: imageQuality,
              )
            : await FilePickerHelper.instance.pickImageFromGallery(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                imageQuality: imageQuality,
              );
        
        if (pickedFile != null) {
          onImagePicked(pickedFile);
        }
      },
    );
  }
}

/// A widget that displays a video picker button
class VideoPickerButton extends StatelessWidget {
  /// Callback when a video is picked
  final Function(PickedFile) onVideoPicked;
  
  /// Button text
  final String text;
  
  /// Button icon
  final IconData icon;
  
  /// Maximum duration of the video
  final Duration? maxDuration;
  
  /// Whether to pick from camera
  final bool fromCamera;
  
  /// Button style
  final ButtonStyle? style;
  
  /// Create a new video picker button
  const VideoPickerButton({
    Key? key,
    required this.onVideoPicked,
    this.text = 'Pick Video',
    this.icon = Icons.video_library,
    this.maxDuration,
    this.fromCamera = false,
    this.style,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      style: style,
      onPressed: () async {
        final pickedFile = fromCamera
            ? await FilePickerHelper.instance.pickVideoFromCamera(
                maxDuration: maxDuration,
              )
            : await FilePickerHelper.instance.pickVideoFromGallery(
                maxDuration: maxDuration,
              );
        
        if (pickedFile != null) {
          onVideoPicked(pickedFile);
        }
      },
    );
  }
}

/// Example usage:
///
/// ```dart
/// // Pick a file
/// Future<void> pickFile() async {
///   final pickedFile = await FilePickerHelper.instance.pickFile(
///     type: FileType.image,
///     allowedExtensions: ['jpg', 'png', 'jpeg'],
///   );
///   
///   if (pickedFile != null) {
///     print('File name: ${pickedFile.name}');
///     print('File path: ${pickedFile.path}');
///     print('File size: ${pickedFile.readableSize}');
///     print('File extension: ${pickedFile.extension}');
///     print('File MIME type: ${pickedFile.mimeType}');
///     print('Is image: ${pickedFile.isImage}');
///     
///     // Save the file
///     final savedFile = await FilePickerHelper.instance.saveFileToDocuments(pickedFile);
///     if (savedFile != null) {
///       print('Saved file path: ${savedFile.path}');
///     }
///   }
/// }
///
/// // Pick an image from the gallery
/// Future<void> pickImageFromGallery() async {
///   final pickedFile = await FilePickerHelper.instance.pickImageFromGallery(
///     maxWidth: 800,
///     maxHeight: 800,
///     imageQuality: 80,
///   );
///   
///   if (pickedFile != null) {
///     // Use the image
///   }
/// }
///
/// // Pick a video from the camera
/// Future<void> pickVideoFromCamera() async {
///   final pickedFile = await FilePickerHelper.instance.pickVideoFromCamera(
///     maxDuration: Duration(seconds: 30),
///   );
///   
///   if (pickedFile != null) {
///     // Use the video
///   }
/// }
///
/// // Using the buttons
/// Widget build(BuildContext context) {
///   return Column(
///     children: [
///       FilePickerButton(
///         text: 'Pick Document',
///         icon: Icons.description,
///         type: FileType.custom,
///         allowedExtensions: ['pdf', 'doc', 'docx'],
///         onFilePicked: (pickedFile) {
///           // Use the file
///         },
///       ),
///       
///       ImagePickerButton(
///         text: 'Take Photo',
///         icon: Icons.camera_alt,
///         fromCamera: true,
///         maxWidth: 800,
///         maxHeight: 800,
///         imageQuality: 80,
///         onImagePicked: (pickedFile) {
///           // Use the image
///         },
///       ),
///       
///       VideoPickerButton(
///         text: 'Pick Video',
///         icon: Icons.video_library,
///         maxDuration: Duration(minutes: 5),
///         onVideoPicked: (pickedFile) {
///           // Use the video
///         },
///       ),
///     ],
///   );
/// }
/// ```
