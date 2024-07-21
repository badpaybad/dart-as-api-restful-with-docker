
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
class rootBundle{
  static Future<String> rootDir() async{
    var file =  Platform.script.toFilePath();
    file= file.replaceAll("\\", "/");

    var idx= file.lastIndexOf("/");
    if(idx<=0) return file;
    return file.substring(0,idx);
  }
  static Future<ByteData> load(String assertPath) async{
    var file= "${await rootDir()}/$assertPath".replaceAll("//", "/");
    return ByteData.sublistView(await File(file).readAsBytes());
  }
}
