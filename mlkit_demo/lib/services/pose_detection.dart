import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_painter.dart';

class PoseDetectionScreen extends StatefulWidget {
  @override
  _PoseDetectionScreenState createState() => _PoseDetectionScreenState();
}

class _PoseDetectionScreenState extends State<PoseDetectionScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  bool isDetectingPose = false;
  List<Pose> _poses = [];
  Size _imageSize = Size(0, 0);
  double leftElbowAngle = 0.0;
  double rightElbowAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _controller = CameraController(cameras![0], ResolutionPreset.high,
          enableAudio: false);
      await _controller!.initialize();
      _imageSize = Size(
        _controller!.value.previewSize!.height,
        _controller!.value.previewSize!.width,
      );
      setState(() {
        isCameraInitialized = true;
      });
      print("Camera initialized successfully");

      // Start the image stream after the camera is initialized
      _controller!.startImageStream((image) {
        if (!isDetectingPose) {
          isDetectingPose = true;
          _detectPose(image).then((_) => isDetectingPose = false);
        }
      });
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _initializePoseDetector() {
    try {
      final options = PoseDetectorOptions(
          model: PoseDetectionModel.base, mode: PoseDetectionMode.stream);
      _poseDetector = PoseDetector(options: options);
      print("Pose detector initialized successfully");
    } catch (e) {
      print("Error initializing pose detector: $e");
    }
  }

  Future<void> _detectPose(CameraImage image) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation90deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        _calculateElbowAngles(poses);
      }

      if (mounted) {
        setState(() {
          _poses = poses;
        });
      } else {
        print('Widget is not mounted, skipping setState');
      }
    } catch (e) {
      print('Error detecting pose: $e');
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    allBytes.putUint8List(planes[0].bytes);
    return allBytes.done().buffer.asUint8List();
  }

  void _calculateElbowAngles(List<Pose> poses) {
    for (final pose in poses) {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

      if (leftShoulder != null && leftElbow != null && leftWrist != null) {
        leftElbowAngle = _calculateAngle(leftShoulder.x, leftShoulder.y,
            leftElbow.x, leftElbow.y, leftWrist.x, leftWrist.y);
      }

      if (rightShoulder != null && rightElbow != null && rightWrist != null) {
        rightElbowAngle = _calculateAngle(rightShoulder.x, rightShoulder.y,
            rightElbow.x, rightElbow.y, rightWrist.x, rightWrist.y);
      }
    }
  }

  double _calculateAngle(
      double ax, double ay, double bx, double by, double cx, double cy) {
    final abx = ax - bx;
    final aby = ay - by;
    final cbx = cx - bx;
    final cby = cy - by;

    final dotProduct = (abx * cbx) + (aby * cby);
    final crossProduct = (abx * cby) - (aby * cbx);

    final angle = (dotProduct != 0)
        ? (atan2(crossProduct, dotProduct) * (180 / pi)).abs()
        : 0.0;
    return ((angle > 180 ? 360 - angle : angle) / 5).floorToDouble() * 5;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector?.close();
    super.dispose();
    print("Disposed camera controller and pose detector");
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Pose Detection')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              CustomPaint(
                painter: PosePainter(_poses, _imageSize, constraints),
                child: Container(),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        'Left Elbow Angle: ${leftElbowAngle.toStringAsFixed(2)}°',
                        style: TextStyle(
                          color: (leftElbowAngle < 20 || leftElbowAngle > 70)
                              ? Colors.red
                              : Colors.green,
                          fontSize: 16,
                        )),
                    Text(
                        'Right Elbow Angle: ${rightElbowAngle.toStringAsFixed(2)}°',
                        style: TextStyle(
                          color: (rightElbowAngle < 20 || rightElbowAngle > 70)
                              ? Colors.red
                              : Colors.green,
                          fontSize: 16,
                        )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
