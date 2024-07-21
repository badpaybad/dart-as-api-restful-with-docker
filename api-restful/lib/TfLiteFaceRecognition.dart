import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cli/rootBundle.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as DartImage;

class TfLiteFaceRecognition {
  List _preprocessImage_1_3_112_112(DartImage.Image image) {
    // Convert the image to a float32 list and normalize the pixel values
    var input = List.generate(
        1,
            (_) => List.generate(
            3, (_) => List.generate(112, (_) => List.filled(112, 0.0))));

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        var pixel = image.getPixel(x, y);
        input[0][0][y][x] = DartImage.getRed(pixel) / 255.0;
        input[0][1][y][x] = DartImage.getGreen(pixel) / 255.0;
        input[0][2][y][x] = DartImage.getBlue(pixel) / 255.0;
      }
    }

    return input;
  }

  List<dynamic> _preprocessImage_1_256_256_3(DartImage.Image image) {
    //Input Shape: [  1 256 256   3]
    // Convert the image to a float32 list and normalize the pixel values
    List<List<List<List<double>>>> input = List.generate(
      1,
          (_) => List.generate(
        256,
            (_) => List.generate(
          256,
              (_) => List.filled(3, 0.0),
        ),
      ),
    );

    for (int y = 0; y < 256; y++) {
      for (int x = 0; x < 256; x++) {
        var pixel = image.getPixel(x, y);
        input[0][y][x][0] = DartImage.getRed(pixel) / 255.0;
        input[0][y][x][1] = DartImage.getGreen(pixel) / 255.0;
        input[0][y][x][2] = DartImage.getBlue(pixel) / 255.0;
      }
    }

    return input;
  }

  Future<List> getInput_1_3_112_112_FromImageAsset(
      String imgFileInAsset) async {
    var bytes2 = (await rootBundle.load(imgFileInAsset)).buffer.asUint8List();
    var imageInput2 = DartImage.decodeImage(bytes2)!;
    var resizedImage2 =
    DartImage.copyResize(imageInput2, width: 112, height: 112);
    return _preprocessImage_1_3_112_112(resizedImage2);
  }

  Future<List> getInput_1_3_112_112_FromImage(Uint8List img) async {
    // var bytes2 = (await rootBundle.load(imgFileInAsset)).buffer.asUint8List();
    var imageInput2 = DartImage.decodeImage(img)!;
    var resizedImage2 =
    DartImage.copyResize(imageInput2, width: 112, height: 112);
    return _preprocessImage_1_3_112_112(resizedImage2);
  }

  Future<List> getInput_1_256_256_3_FromImageAsset(
      String imgFileInAsset) async {
    var bytes2 = (await rootBundle.load(imgFileInAsset)).buffer.asUint8List();
    var imageInput2 = DartImage.decodeImage(bytes2)!;
    var resizedImage2 =
    DartImage.copyResize(imageInput2, width: 256, height: 256);
    return _preprocessImage_1_256_256_3(resizedImage2);
  }

  Future<List> getInput_1_256_256_3_FromImage(Uint8List img) async {
    var imageInput2 = DartImage.decodeImage(img)!;
    var resizedImage2 =
    DartImage.copyResize(imageInput2, width: 256, height: 256);
    return _preprocessImage_1_256_256_3(resizedImage2);
  }

  static Interpreter? _mediaposeDetect;

  ///
  ///  var img = (await rootBundle.load(imgFileInAsset)).buffer.asUint8List();
  ///
  Future<dynamic> MediapipeObjectDetect(Uint8List img) async {
    if (_mediaposeDetect == null) {
      var modelfileasset = "assets/chunom_detect/model.tflite";
      _mediaposeDetect = await Interpreter.fromAsset(modelfileasset);
    }
    var output0 = List.generate(
      1,
          (_) => List.generate(
        12276,
            (_) => List.filled(4, 0.0),
      ),
    );
    var output1 = List.generate(
      1,
          (_) => List.generate(
        12276,
            (_) => List.filled(2, 0.0),
      ),
    );
    var input = getInput_1_256_256_3_FromImage(img);
    _mediaposeDetect!.runForMultipleInputs([input], {0: output0, 1: output1});

    return output0;
  }

  static Interpreter? _insightFace;

  Future<List<double>> InsightFaceVector(Uint8List img) async {
    if (_insightFace == null) {
      var modelfileasset = "assets/updated_resnet100.tflite";
      _insightFace = await Interpreter.fromAsset(modelfileasset);
    }

    var output = List<double>.filled(512, 0).reshape([1, 512]);
    var input = await getInput_1_3_112_112_FromImage(img);

    _insightFace!.run(input, output);

    return output[0];
  }

  static Interpreter? _eyeFace;

  Future<List<double>> EyeFaceVector(Uint8List img) async {
    if (_eyeFace == null) {
      var modelfileasset = "assets/face_extract_feature/model.tflite";
      _eyeFace = await Interpreter.fromAsset(modelfileasset);
    }
    var output0 = List<double>.filled(512, 0).reshape([1, 512]);
    var output1 =
    List<double>.filled(1 * 512 * 7 * 7, 0).reshape([1, 512, 7, 7]);
    var input = await getInput_1_3_112_112_FromImage(img);

    _eyeFace!.runForMultipleInputs([input], {0: output0, 1: output1});

    return output0[0];
  }

  double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    // Check if the vectors have the same length
    if (vectorA.length != vectorB.length) {
      throw ArgumentError("Vectors must have the same length.");
    }

    // Calculate dot product
    double dotProduct = 0;
    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
    }

    // Calculate magnitudes
    double magnitudeA = 0;
    double magnitudeB = 0;
    for (int i = 0; i < vectorA.length; i++) {
      magnitudeA += pow(vectorA[i], 2);
      magnitudeB += pow(vectorB[i], 2);
    }
    magnitudeA = sqrt(magnitudeA);
    magnitudeB = sqrt(magnitudeB);

    // Compute cosine similarity
    if (magnitudeA != 0 && magnitudeB != 0) {
      return dotProduct / (magnitudeA * magnitudeB);
    } else {
      return 0.0;
    }
  }

  Future<dynamic> Test() async {
    var img = (await rootBundle.load("assets/dunp1.png")).buffer.asUint8List();

    print("Test -----------1");
    var v2 = await EyeFaceVector(img);
    print("Test -----------2");
    var v1 = await InsightFaceVector(img);

    var score = cosineSimilarity(v1, v2);
    print("Test ----------- $score");
    return {"v1": v1, "v2": v2, "sim": score};
  }
}
