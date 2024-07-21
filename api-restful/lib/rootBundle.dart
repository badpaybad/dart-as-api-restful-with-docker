import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

class rootBundle {
  static String rootDir()  {
    var file = Platform.script.toFilePath();
    file = file.replaceAll("\\", "/");
    var idx = file.lastIndexOf("/");
    if (idx <= 0) return file;
    file = file.substring(0, idx);

    if (file != Directory.current.path) {
      print({"rootDir": Directory.current});
    }
    return file;
  }

  static Future<ByteData> load(String assetPath) async {
    var file = "$assetPath".replaceAll("//", "/");
    return ByteData.sublistView(await File(file).readAsBytes());
  }

  static Future<File> loadFile(String assetPath) async {
    return File(assetPath);
  }
}
