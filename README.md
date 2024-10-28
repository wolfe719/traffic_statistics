# Traffic Stats Plugin for Flutter

This plugin provides a simple way to monitor network speed (download and upload) as well as 
data usage in your Flutter applications.

## Features

* Monitors real-time network traffic statistics.
* Provides separate values for download and upload speeds in kilobits per second (kbps).
* Provided separate values for total send and received kilobytes.
* Easy integration with your Flutter UI to display network speed information.

## Installation

1. **Add the dependency to your `pubspec.yaml` file:**

```yaml
dependencies:
  traffic_statistics: 
```

2. **Install the package:**

```bash
$ flutter pub get
```

3. **Import the package:**

```dart
import 'package:traffic_statistics/traffic_statistics.dart'; 
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:traffic_statistics/traffic_statistics.dart';

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

class NetworkUsagePage extends StatefulWidget {
  const NetworkUsagePage({super.key});

  @override
  NetworkUsagePageState createState() => NetworkUsagePageState();
}

class NetworkUsagePageState extends State<NetworkUsagePage> {
  final NetworkUsageService _networkUsageService = NetworkUsageService();
  late Stream<NetworkStatistics> _statisticsStream;
  late NetworkStatistics _currentStatistics;

  @override
  void initState() {
    super.initState();
    _networkSpeedService.init(); // Initialize the service
    _statisticsStream = _networkUsageService.ststisticsStream;
    _currentSpeed = NetworkStatistics(downloadSpeed: 0, uploadSpeed: 0, totalTx: 0, totalRx: 0);

    // Listen to the stream and update the state with new data
    _statisticsStream.listen((data) {
      setState(() {
        _currentStatistics = data;
      });
    });
  }

  @override
  void dispose() {
    _networkUsageService
        .dispose(); // Dispose the service when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Speed and Usage Monitor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Upload Speed: ${_currentStatistics.uploadSpeed} Kbps',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Download Speed: ${_currentStatistics.downloadSpeed} Kbps',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 32),
            Text(
              'Total Transmitted: ${_currentStatistics.totalTx} Kbps',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Received: ${_currentStatistics.totalRx} Kbps',
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
## Updated and expanded by - John Wolfe
