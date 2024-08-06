# Traffic Stats Plugin for Flutter

This plugin provides a simple way to monitor network speed (download and upload) in your Flutter applications.

## Features

* Monitors real-time network traffic statistics.
* Provides separate values for download and upload speeds in kilobits per second (kbps).
* Easy integration with your Flutter UI to display network speed information.

# Traffic Stats Plugin for Flutter

This plugin provides a simple way to monitor network speed (download and upload) in your Flutter applications.

## Features

* Monitors real-time network traffic statistics.
* Provides separate values for download and upload speeds in kilobits per second (kbps).
* Easy integration with your Flutter UI to display network speed information.

## Installation

1. **Add the dependency to your `pubspec.yaml` file:**

```yaml
dependencies:
  traffic_stats: ^0.0.1 (replace with your actual version)
```

2. **Install the package:**

```bash
$ flutter pub get
```

3. **Import the package:**

```dart
import 'package:traffic_stats/traffic_stats.dart'; 
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:traffic_stats/traffic_stats.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Speed Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NetworkSpeedPage(),
    );
  }
}

class NetworkSpeedPage extends StatefulWidget {
  const NetworkSpeedPage({super.key});

  @override
  NetworkSpeedPageState createState() => NetworkSpeedPageState();
}

class NetworkSpeedPageState extends State<NetworkSpeedPage> {
  final NetworkSpeedService _networkSpeedService = NetworkSpeedService();
  late Stream<NetworkSpeedData> _speedStream;
  late NetworkSpeedData _currentSpeed;

  @override
  void initState() {
    super.initState();
    _networkSpeedService.init(); // Initialize the service
    _speedStream = _networkSpeedService.speedStream;
    _currentSpeed = NetworkSpeedData(downloadSpeed: 0, uploadSpeed: 0);

    // Listen to the stream and update the state with new data
    _speedStream.listen((speedData) {
      setState(() {
        _currentSpeed = speedData;
      });
    });
  }

  @override
  void dispose() {
    _networkSpeedService
        .dispose(); // Dispose the service when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Speed Monitor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Download Speed: ${_currentSpeed.downloadSpeed} Kbps',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Speed: ${_currentSpeed.uploadSpeed} Kbps',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Crafted with ❤️ by - Bhawani Shankar


