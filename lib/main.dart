import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as dir;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String result = 'Result will be displayed here...';
  late dir.Ink ink;
  List<dir.StrokePoint> points = [];
  bool isModelDownloaded = false;
  dynamic modelManager;
  late DigitalInkRecognizer digitalInkRecognizer;

  @override
  void initState() {
    super.initState();
    ink = dir.Ink();
    modelManager = DigitalInkRecognizerModelManager();
    checkAndDownloadModel();
  }

  @override
  void dispose() {
    super.dispose();
  }

  checkAndDownloadModel() async {
    isModelDownloaded = await modelManager.isModelDownloaded('en-US');

    if (!isModelDownloaded) {
      isModelDownloaded = await modelManager.downloadModel('en-US');
    }

    if (isModelDownloaded) {
      digitalInkRecognizer = DigitalInkRecognizer(languageCode: 'en-US');
    }
  }

  Future<void> recogniseText() async {
    if (isModelDownloaded) {
      result = '';
      final List<RecognitionCandidate> candidates =
          await digitalInkRecognizer.recognize(ink);

      for (final candidate in candidates) {
        final text = candidate.text;
        final score = candidate.score;
        result += '$text \n';
      }
      setState(() {
        result;
      });
    } else {
      setState(() {
        result =
            'The Language model isn\'t downloaded. Please Download the Model First. To Download the Model, Please Open your Network Connectivity(or Wifi) and restart the Application.';
      });
    }
  }

  clearPad() {
    setState(() {
      ink.strokes.clear();
      points.clear();
      result = 'Result will be displayed here...';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: const Text(
                  'Draw in the white box below',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              //TODO: Gesture Detector
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 360,
                height: 400,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 40,
                        offset: Offset(5, 10),
                      )
                    ]),
                child: GestureDetector(
                  onPanStart: (DragStartDetails details) {
                    ink.strokes.add(Stroke());
                    print("onPanStart");
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    print("onPanUpdate");
                    setState(() {
                      final RenderObject? object = context.findRenderObject();
                      final localPosition = (object as RenderBox)
                          .globalToLocal(details.localPosition);

                      points = List.from(points)
                        ..add(StrokePoint(
                          x: localPosition.dx,
                          y: localPosition.dy,
                          t: DateTime.now().millisecondsSinceEpoch,
                        ));

                      if (ink.strokes.isNotEmpty) {
                        ink.strokes.last.points = points.toList();
                      }
                    });
                  },
                  onPanEnd: (DragEndDetails details) {
                    print("onPanEnd");
                    points.clear();
                    setState(() {});
                  },
                  child: CustomPaint(
                    painter: Signature(ink: ink),
                    size: Size.infinite,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: recogniseText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 20,
                      ),
                      child: const Text('Read Text'),
                    ),
                    ElevatedButton(
                      onPressed: clearPad,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 20,
                      ),
                      child: const Text('Clear Pad'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (result.isNotEmpty)
                Text(
                  result,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Signature extends CustomPainter {
  Signature({required this.ink});
  dir.Ink ink;
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint();
    p.color = Colors.blue;
    p.strokeCap = StrokeCap.round;
    p.strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
