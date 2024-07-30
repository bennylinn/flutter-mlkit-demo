import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final BoxConstraints constraints;

  PosePainter(this.poses, this.imageSize, this.constraints);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final pose in poses) {
      for (final landmark in pose.landmarks.values) {
        if (_isRelevantLandmark(landmark)) {
          final offset = _translateOffset(
              landmark.x, landmark.y, imageSize, constraints.biggest);
          canvas.drawCircle(offset, 2, paint);
        }
      }

      _drawLineBetweenLandmarks(canvas, pose, PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder, paint, imageSize, size);
      _drawLineBetweenLandmarks(canvas, pose, PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightElbow, paint, imageSize, size);
      _drawLineBetweenLandmarks(canvas, pose, PoseLandmarkType.rightElbow,
          PoseLandmarkType.rightWrist, paint, imageSize, size);
      _drawLineBetweenLandmarks(canvas, pose, PoseLandmarkType.rightWrist,
          PoseLandmarkType.rightIndex, paint, imageSize, size);
      _drawLineBetweenLandmarks(canvas, pose, PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftElbow, paint, imageSize, size);
      _drawLineBetweenLandmarks(canvas, pose, PoseLandmarkType.leftElbow,
          PoseLandmarkType.leftWrist, paint, imageSize, size);
      _drawLineBetweenLandmarks(canvas, pose, PoseLandmarkType.leftWrist,
          PoseLandmarkType.leftIndex, paint, imageSize, size);
    }
  }

  bool _isRelevantLandmark(PoseLandmark landmark) {
    return landmark.type == PoseLandmarkType.leftWrist ||
        landmark.type == PoseLandmarkType.rightWrist ||
        landmark.type == PoseLandmarkType.leftElbow ||
        landmark.type == PoseLandmarkType.rightElbow ||
        landmark.type == PoseLandmarkType.leftShoulder ||
        landmark.type == PoseLandmarkType.rightShoulder ||
        landmark.type == PoseLandmarkType.leftIndex ||
        landmark.type == PoseLandmarkType.rightIndex;
  }

  Offset _translateOffset(double x, double y, Size imageSize, Size widgetSize) {
    // Calculate the scale factor for width and height
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    // Determine the scale factor based on the aspect ratio of the widget and image
    final double scale = (scaleX < scaleY) ? scaleX : scaleY;

    // Calculate the translated offsets
    final double dx = (widgetSize.width - imageSize.width * scale) / 2;
    final double dy = (widgetSize.height - imageSize.height * scale) / 2;

    return Offset(x * scale + dx, y * scale + dy);
  }

  void _drawLineBetweenLandmarks(
      Canvas canvas,
      Pose pose,
      PoseLandmarkType type1,
      PoseLandmarkType type2,
      Paint paint,
      Size imageSize,
      Size widgetSize) {
    final landmark1 = pose.landmarks[type1];
    final landmark2 = pose.landmarks[type2];
    if (landmark1 != null && landmark2 != null) {
      final offset1 =
          _translateOffset(landmark1.x, landmark1.y, imageSize, widgetSize);
      final offset2 =
          _translateOffset(landmark2.x, landmark2.y, imageSize, widgetSize);
      canvas.drawLine(offset1, offset2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
