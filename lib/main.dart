import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_demo/ml.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MLService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Plant Disease Detection Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? prediction;
  String? confidence;
  File? selectedImageFile;
  bool isLoading = false;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void startLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void stopLoading() {
    setState(() {
      isLoading = false;
    });
  }




  Future<void> onPredictButtonPressed() async {
    startLoading();
    try{
      Map<String, dynamic> result = await MLService().recognizeDisease(selectedImageFile!.path);
      setState(() {
        prediction = result['predicted_class'].toString();
        confidence = result['confidence'].toString();
      });
    }catch(e) {
      debugPrint("Something went wrong during prediction");
    }
    stopLoading();
    //do something
  }

  Future<void> onSelectImage() async {
    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        selectedImageFile = File(pickedImage.path);
      });
    }

    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   type: FileType.image,
    //   allowMultiple: false,
    // );
    //
    // if (result != null) {
    //   setState(() {
    //     selectedImageFile = resultFile;
    //   });
    // }

  }


  @override
  Widget build(BuildContext context) {

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 30),
                selectedImageFile == null ? Container(child: null) : Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(selectedImageFile!)
                    )
                  ),
                  child: null

                ),
                SizedBox(height: 10),
                (prediction == null || confidence == null) ? Container(child: null) : Center(
                  child: Container(
                    child: Column(
                      children: [
                        Text("Prediction: $prediction"),
                        Text("Confidence: $confidence %")
                      ],
                    )
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                    onPressed: onSelectImage,
                    child: Text(
                        "Select an Image"
                    )
                ),
                SizedBox(height: 20),
                ElevatedButton(
                    onPressed: onPredictButtonPressed,
                    child: Text(
                      "Make Prediction"
                    )
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
