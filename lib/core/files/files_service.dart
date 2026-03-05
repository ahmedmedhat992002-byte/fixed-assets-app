import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileItem {
  final String id;
  final String name;
  final String size;
  final String localPath;
  final DateTime createdAt;
  final String type;
  final String category;

  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.localPath,
    required this.createdAt,
    required this.type,
    this.category = 'Others',
  });

  factory FileItem.fromMap(Map<dynamic, dynamic> map) {
    return FileItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      size: map['size'] ?? '',
      localPath: map['localPath'] ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
      type: map['type'] ?? '',
      category: map['category'] ?? 'Others',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'localPath': localPath,
      'createdAt': createdAt,
      'type': type,
      'category': category,
    };
  }

  // Compatibility getter for UI that expects downloadUrl
  String get downloadUrl => localPath;
  // Compatibility getter for UI that expects storagePath
  String get storagePath => localPath;
}

class FilesService extends ChangeNotifier {
  static const String _boxName = 'local_files_metadata';
  final _uuid = const Uuid();

  FilesService() {
    // We'll open the box when needed or ensure it's open
  }

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Stream<List<FileItem>> getFilesStream({String? category}) async* {
    final box = await _getBox();

    // Yield initial data
    yield _getFilesFromBox(box, category);

    // Watch for changes
    await for (final _ in box.watch()) {
      yield _getFilesFromBox(box, category);
    }
  }

  List<FileItem> _getFilesFromBox(Box box, String? category) {
    final List<FileItem> allFiles = box.values
        .map((data) => FileItem.fromMap(data as Map))
        .toList();

    // Sort by date descending
    allFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (category == null || category == 'All') {
      return allFiles;
    }
    return allFiles.where((f) => f.category == category).toList();
  }

  Future<void> uploadFile(
    File file,
    String fileName, {
    String category = 'Others',
  }) async {
    try {
      if (!file.existsSync()) {
        throw Exception('Source file does not exist: ${file.path}');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory(p.join(appDir.path, 'local_files'));

      try {
        if (!filesDir.existsSync()) {
          await filesDir.create(recursive: true);
        }
      } catch (e) {
        throw Exception('Could not create storage directory: $e');
      }

      final fileId = _uuid.v4();
      final extension = p.extension(fileName);
      final localFileName = '$fileId$extension';
      final localPath = p.join(filesDir.path, localFileName);

      // Copy file to local app directory
      try {
        await file.copy(localPath);
      } catch (e) {
        throw Exception('Failed to copy file to local storage: $e');
      }

      // Get size
      int bytes = 0;
      try {
        bytes = await file.length();
      } catch (_) {}

      final sizeStr = _formatBytes(bytes);

      final fileItem = FileItem(
        id: fileId,
        name: fileName,
        size: sizeStr,
        localPath: localPath,
        createdAt: DateTime.now(),
        type: extension.startsWith('.')
            ? extension.substring(1).toLowerCase()
            : 'bin',
        category: category,
      );

      final box = await _getBox();
      await box.put(fileId, fileItem.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('DEBUG: [FilesService] uploadFile failed: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String fileId, String localPath) async {
    try {
      final box = await _getBox();
      await box.delete(fileId);

      final file = File(localPath);
      if (file.existsSync()) {
        await file.delete();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('DEBUG: [FilesService] Delete failed: $e');
      rethrow;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }
}
