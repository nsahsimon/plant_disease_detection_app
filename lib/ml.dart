import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:image/image.dart' as img;
import 'dart:math';

const int imageSize = 224;

const Map<String, String> labels = {
    "0" :"Pepper_bell__Bacterial_spot",
    "1" :"Pepper_bell__healthy",
    "2" :"Potato___Early_blight",
    "3" :"Potato___Late_blight",
    "4" :"Potato___healthy",
    "5" :"Tomato_Bacterial_spot",
    "6" :"Tomato_Early_blight",
    "7" :"Tomato_Late_blight",
    "8" :"Tomato_Leaf_Mold",
    "9" :"Tomato_Septoria_leaf_spot",
    "10" :"Tomato_Spider_mites_Two_spotted_spider_mite",
    "11" :"Tomato__Target_Spot",
    "12" :"Tomato_Tomato_YellowLeaf_Curl_Virus",
    "13" :"Tomato__Tomato_mosaic_virus",
    "14" :"Tomato_healthy",
    "15" :"Invalid Picture"
};

class MLService {
  static late Interpreter interpreter;
  static late Interpreter letterInterpreter;
  static InterpreterOptions interpreterOptions = InterpreterOptions()..threads = 2;

  MLService();

  static Future<void> initialize() async {
    try {
      interpreter = await Interpreter.fromAsset("plant_disease_detector.tflite", options: interpreterOptions);
      debugPrint("Successfully initialized Model");
    }catch(e) {
      debugPrint("$e");
      debugPrint("Initializing model");
    }

  }

  Future<Map<String, dynamic>> recognizeDisease(String imagePath) async {
    var _file = io.File(imagePath);
    img.Image imageTemp = img.decodeImage(_file.readAsBytesSync())!;
    debugPrint("Resizing image");
    img.Image resizedImage = img.copyResize(imageTemp, width: 224, height: 224);
    debugPrint("Number of channels: ${resizedImage.numChannels}, Format: ${resizedImage.format}");
    Uint8List imgBytes = resizedImage.getBytes();
    Uint8List imgAsList = imgBytes.buffer.asUint8List();
    debugPrint("Getting predictions for: ${imagePath}");
    return getPrediction(imgAsList);
  }


  Future<Map<String, dynamic>> getPrediction(Uint8List imgAsList) async {
    // final List<dynamic> resultBytes = List.filled(mnistSize * mnistSize, 0.0);
    final List<dynamic> resultBytes = List.filled(imageSize * imageSize * 3, 0.0);
    debugPrint("Image as list length: ${imgAsList.length}");
    int index = 0;
    try {
      for (int i = 0; i < imgAsList.length - 3; i += 3) {
        final r = imgAsList[i];
        final g = imgAsList[i+1];
        final b = imgAsList[i+2];

        // Take the mean of R,G,B channel into single GrayScale
        resultBytes[index] = (r / 127.5) - 1; //(((r + g + b) / 3) / 255);
        index++;
        resultBytes[index+1] = (g / 127.5) - 1;
        index++;
        resultBytes[index+2] = (b / 127.5) - 1;
        index++;
      }
    }catch (e) {
      debugPrint("$e");
    }

    debugPrint("Result bytes length: ${resultBytes.length}");

    var input = resultBytes.reshape([1, imageSize, imageSize, 3]);
    var output = List.filled(16, 0.0).reshape([1, 16]);

    // Track how long it took to do inference
    int startTime = new DateTime.now().millisecondsSinceEpoch;

    try {
      interpreter.run(input, output);
    } catch (e) {
      debugPrint('Error loading or running model: ' + e.toString());
    }

    int endTime = new DateTime.now().millisecondsSinceEpoch;
    debugPrint("Inference took ${endTime - startTime} ms");

    // Obtain the highest score from the output of the model
    double highestProb = 0;
    late String prediction;

    // double total = output[0].reduce((a, b) => a + b);
    double total = 0.0;
    for (int i = 0; i < output[0].length; i++) {
      total+=output[0][i];
      if (output[0][i] > highestProb) {
        highestProb = output[0][i];

        prediction = labels["${i.toString()}"]??"";
      }
    }
    return {"predicted_class" : prediction, "confidence" : highestProb * 100 / total };
  }


  // Future predictImage(String imagePath) async {
  //   // Interpreter interpreter = await Interpreter.fromAsset('model.tflite');
  //   var inputShape = interpreter.getInputTensor(0).shape;
  //   var outputShape = interpreter.getOutputTensor(0).shape;
  //   var inputType = interpreter.getInputTensor(0).type;
  //
  //   // Load and resize the image
  //   var imageBytes = await File(imagePath).readAsBytes();
  //   var image = img.decodeImage(imageBytes);
  //   image = img.copyResize(image!, height: inputShape[1], width: inputShape[2]);
  //
  //   // Normalize the image
  //   var input = imageToByteListFloat32(image, inputShape[1], inputShape[2], 127.5, 1);
  //
  //   // Make the prediction
  //   interpreter.allocateTensors();
  //   interpreter.setTensor(0, input);
  //   interpreter.invoke();
  //   var output = interpreter.getOutputTensor(0);
  //   var predictions = output.getFloatList();
  //   var index = predictions.indexWhere((element) => element == predictions.reduce(max));
  //   _class = class_names[index];
  //   _confidence = predictions[index];
  //
  //   setState(() {});
  // }
  //
  //
  // Future<Float32List> imageToByteListFloat32(img.Image image, {int height = 224, int width = 224,double thresh=127.5}) async {
  //   final bytes = await File(imagePath).readAsBytes();
  //   final decodedImage = img.decodeImage(bytes);
  //
  //   final resizedImage = img.copyResize(decodedImage, width: inputSize, height: inputSize);
  //   final convertedBytes = Float32List(image.length);
  //   final buffer = Float32List.view(convertedBytes.buffer);
  //
  //   for (var i = 0; i < resizedImage.length; i++) {
  //     buffer[i] = (resizedImage[i] - 127.5) / 127.5;
  //   }
  //
  //   return convertedBytes;
  // }


}
