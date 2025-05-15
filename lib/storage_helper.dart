import 'dart:io';
import 'package:path/path.dart' as path;

class StorageHelper {
  static Future<String> _getFolderPath() async {
    final Directory dir = Directory('/storage/emulated/0/DCIM/materiFlutter');

    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<File> saveImage(File file, String prefix) async {
    final String dirPath = await _getFolderPath();
    final String filename =
        '$prefix${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';

    final String savedPath = path.join(dirPath, filename);
    return await file.copy(savedPath);
  }
}
