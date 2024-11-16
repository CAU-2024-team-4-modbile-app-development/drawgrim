import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> with SingleTickerProviderStateMixin {
  final DrawingController _drawingController = DrawingController();
  final String promptWord = "애 호 박";
  late AnimationController _timerController;
  final TransformationController _transformationController = TransformationController();
  Color timeColor = Colors.green;
  final double first_timeWidth = 300.0;
  double timeWidth = 300.0;
  bool isTimeLow = false;

  double _colorOpacity = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10), // Set the desired countdown time
    )
      ..addListener(() {
        setState(() {
          // Update time bar color and width based on remaining time
          double progress = _timerController.value;
          timeColor = Color.lerp(Colors.green, Colors.red, progress)!;
          timeWidth = 300 * (1 - progress);

          // Trigger shake effect when time is low
          if (progress > 0.8) {
            isTimeLow = true;
          }
        });
      });

    // Start the timer when the game starts
    _timerController.forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _drawingController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage(Uint8List imageData) async {
    try {
      // Create a reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('drawings/${DateTime.now().millisecondsSinceEpoch}.png');

      // Upload the image
      debugPrint('Uploading image...');
      final uploadTask = ref.putData(imageData);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Upload progress: ${snapshot.bytesTransferred} bytes of ${snapshot.totalBytes}');
      });

      // Wait until the upload is complete
      await uploadTask;

      // Get the image URL
      String downloadUrl = await ref.getDownloadURL();

      // Save the URL to Firestore for real-time access
      await FirebaseFirestore.instance.collection('drawings').add({
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Image uploaded successfully, URL: $downloadUrl');
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('FirebaseException: ${e.message}');
      } else {
        debugPrint('Error uploading image: $e');
      }
    }
  }


  Future<void> testUploadImage() async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('test_folder/test_image.png');

      // Create a dummy image for testing (1x1 white pixel)
      Uint8List imageData = Uint8List.fromList([255, 255, 255, 255]);

      await ref.putData(imageData);
      String downloadUrl = await ref.getDownloadURL();

      print('Image uploaded successfully: $downloadUrl');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  /// Capture the drawing data as image and upload
  Future<void> _getImageData() async {
    final Uint8List? data = (await _drawingController.getImageData())?.buffer.asUint8List();
    print(data);
    if (data == null) {
      debugPrint('Failed to get image data');
      return;
    }
    // Upload the image to Firebase
    //await testUploadImage();

    await _uploadImage(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey,
      body: Stack(
        children: <Widget>[
          // Main content
          Column(
            children: <Widget>[
              // Prompt Word
              SizedBox(height: 25),
              Text(
                promptWord,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Transform.translate(
                offset: isTimeLow ? Offset(5 * (0.5 - _timerController.value), 0) : Offset(0, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width * (timeWidth / first_timeWidth),
                  height: 3,
                  color: timeColor,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return DrawingBoard(
                      boardPanEnabled: false,
                      boardScaleEnabled: false,
                      transformationController: _transformationController,
                      controller: _drawingController,
                      background: Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        color: Colors.white,
                      ),
                      showDefaultActions: true,
                      showDefaultTools: true,
                    );
                    //DRAWING BOARD
                  },
                ),
              ),

            ],
          ),

          Center(
            child: ElevatedButton(
              onPressed: (){
                _getImageData();
              }, // Upload the drawing when button pressed
              child: Text('Upload Drawing'),
            ),
          ),

          // Positioned 'Back' button at top-left
          Positioned(
            top: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Back'),
            ),
          ),
        ],
      ),
    );
  }
}