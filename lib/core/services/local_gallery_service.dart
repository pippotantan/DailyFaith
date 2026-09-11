import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user-selected background images from device gallery.
/// Images are copied to app storage for persistent access (gallery paths are session-only).
class LocalGalleryService {
  static const String _pathsKey = 'local_background_image_paths';
  static const String _storageDirName = 'local_backgrounds';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  /// Returns the list of stored local image paths.
  static Future<List<String>> getStoredPaths() async {
    final p = await _prefs();
    final json = p.getString(_pathsKey);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => e.toString()).where((p) => p.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves the list of paths to preferences.
  static Future<void> _savePaths(List<String> paths) async {
    final p = await _prefs();
    await p.setString(_pathsKey, jsonEncode(paths));
  }

  /// Picks multiple images from gallery, copies them to app storage, and adds to stored list.
  /// Returns the number of images successfully added.
  static Future<int> pickAndAddImages() async {
    final picker = ImagePicker();
    final xFiles = await picker.pickMultiImage(
      limit: 50,
      imageQuality: 90,
    );
    if (xFiles.isEmpty) return 0;

    final dir = await _getStorageDirectory();
    final existingPaths = await getStoredPaths();
    final added = <String>[];

    for (var i = 0; i < xFiles.length; i++) {
      try {
        final xFile = xFiles[i];
        final bytes = await xFile.readAsBytes();
        if (bytes.isEmpty) continue;

        final ext = _extensionFromPath(xFile.path) ?? 'jpg';
        final name = 'bg_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes);

        final path = file.path;
        if (!existingPaths.contains(path) && !added.contains(path)) {
          added.add(path);
        }
      } catch (e) {
        developer.log('Failed to copy image $i: $e', name: 'LocalGalleryService');
      }
    }

    if (added.isNotEmpty) {
      final newPaths = [...existingPaths, ...added];
      await _savePaths(newPaths);
    }
    return added.length;
  }

  static String? _extensionFromPath(String path) {
    final ext = path.split('.').lastOrNull?.toLowerCase();
    if (ext == null || ext.isEmpty) return null;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return ext;
    return 'jpg';
  }

  /// Removes an image from the stored list. Does not delete the file.
  static Future<void> removePath(String path) async {
    final paths = await getStoredPaths();
    final updated = paths.where((p) => p != path).toList();
    await _savePaths(updated);
  }

  /// Removes all stored images. Optionally deletes files from disk.
  static Future<void> clearAll({bool deleteFiles = true}) async {
    final paths = await getStoredPaths();
    if (deleteFiles) {
      for (final p in paths) {
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
    await _savePaths([]);
  }

  /// Returns a random path from the stored list, or null if empty.
  static Future<String?> getRandomPath() async {
    final paths = await getStoredPaths();
    if (paths.isEmpty) return null;

    // Filter to paths that still exist (user may have deleted files)
    final validPaths = <String>[];
    for (final p in paths) {
      if (await File(p).exists()) validPaths.add(p);
    }
    if (validPaths.isEmpty) {
      await _savePaths([]);
      return null;
    }
    if (validPaths.length < paths.length) {
      await _savePaths(validPaths);
    }

    return validPaths[Random().nextInt(validPaths.length)];
  }

  static Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_storageDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
