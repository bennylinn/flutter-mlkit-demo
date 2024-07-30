import 'package:flutter/material.dart';
import 'package:mlkit_demo/services/pose_detection.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Pose Detection'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PoseDetectionScreen()),
            );
          },
          child: Text('Start Pose Detection'),
        ),
      ),
    );
  }
}
