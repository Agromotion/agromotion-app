import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Vista do Robô'), backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.white54, size: 64),
                  Text("A ligar à VPN (Tailscale)...", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(32),
            color: Colors.white10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: () {}),
                CircleAvatar(radius: 30, backgroundColor: Colors.red, child: IconButton(icon: const Icon(Icons.fiber_manual_record, color: Colors.white), onPressed: () {})),
                IconButton(icon: const Icon(Icons.sync, color: Colors.white), onPressed: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }
}