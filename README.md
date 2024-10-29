# Traffic Statistics Plugin for Flutter

This plugin provides a simple way to monitor network speed (download and upload) as well as 
data usage in your Flutter applications.

## Features

* Monitors real-time network traffic statistics
* Provides separate values for download and upload speeds in kilobits per second (kbps)
* Provides separate values for all sent and received data in kilobytes since the device started
* Provided separate values for total sent and received kilobytes from when the statistics stream was started
* Example of integration with your Flutter UI to display network speed and data usage information

## How To Use

This pub offers a streaming API for getting network usage statistics as well as current 
upload and download speed. The API looks like this:

```dart
  final TrafficStatisticsService _trafficStatisticsService = TrafficStatisticsService();

  late Stream<TrafficStatistics> _statisticsStream;
  late TrafficStatistics _currentStatistics;

  @override
  void initState() {
    _trafficStatisticsService.init(); // Initialize the service

    _statisticsStream = _trafficStatisticsService.statisticsStream; // Get the statisticsStream
    
    _currentStatistics = TrafficStatistics(uploadSpeed: 0,  // Set up a default value initially
        downloadSpeed: 0,
        totalTx: 0.0,
        totalRx: 0.0,
        uid: 0,
        totalAllTx: 0.0,
        totalAllRx: 0.0);

    // Listen to the statistics stream and update the state with new data
    _statisticsStream.listen((data) {
      setState(() {
        _currentStatistics = data;
      });
    });    
  }
```

The statistics information that is passed back from the statisticsStream includes the following:

* uploadSpeed - a double value that is the current upload speed, calculated by taking the
    amount of data uploaded since the last check, the time since the last check, and running
    a simple calculation to give back kbps (kilobytes per second)

* downloadSpeed - a double value that is the current download speed, calculated by taking 
    the amount of data downloaded since the last check, the time since the last check, and 
    running a simple calculation to give back kbps (kilobytes per second)

* totalTx - a double value of the total transmitted data since the service started. For Android,
    that is the total transmitted data for this app. For iOS, that is the total transmitted 
    data across both WiFi and Cellular.

* uid - an integer value which specifies the application UID in Android and a Process ID in iOS

* totalAllTx - a double value that is all the data transmitted by all WiFi and Cellular 
    connections since the device started (or rebooted, or restarted).

* totalAllRx - a double value that is all the data received by all WiFi and Cellular 
    connections since the device has started (or rebooted, or restarted).

## How To Use

This pub offers a streaming API for getting network usage statistics as well as current 
upload and download speed. The API looks like this:

```dart
  final TrafficStatisticsService _trafficStatisticsService = TrafficStatisticsService();

  late Stream<TrafficStatistics> _statisticsStream;
  late TrafficStatistics _currentStatistics;

  @override
  void initState() {
    _trafficStatisticsService.init(); // Initialize the service

    _statisticsStream = _trafficStatisticsService.statisticsStream; // Get the statisticsStream
    
    _currentStatistics = TrafficStatistics(uploadSpeed: 0,  // Set up a default value initially
        downloadSpeed: 0,
        totalTx: 0.0,
        totalRx: 0.0,
        uid: 0,
        totalAllTx: 0.0,
        totalAllRx: 0.0);

    // Listen to the statistics stream and update the state with new data
    _statisticsStream.listen((data) {
      setState(() {
        _currentStatistics = data;
      });
    });    
  }
```

The statistics information that is passed back from the statisticsStream includes the following:

* uploadSpeed - a double value that is the current upload speed, calculated by taking the
    amount of data uploaded since the last check, the time since the last check, and running
    a simple calculation to give back kbps (kilobytes per second)

* downloadSpeed - a double value that is the current download speed, calculated by taking 
    the amount of data downloaded since the last check, the time since the last check, and 
    running a simple calculation to give back kbps (kilobytes per second)

* totalTx - a double value of the total transmitted data since the service started. For Android,
    that is the total transmitted data for this app. For iOS, that is the total transmitted 
    data across both WiFi and Cellular.

* uid - an integer value which specifies the application UID in Android and a Process ID in iOS

* totalAllTx - a double value that is all the data transmitted by all WiFi and Cellular 
    connections since the device started (or rebooted, or restarted).

* totalAllRx - a double value that is all the data received by all WiFi and Cellular 
    connections since the device has started (or rebooted, or restarted).

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
import 'package:webview_flutter/webview_flutter.dart';

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
      home: const _TrafficStatisticsPage(),
    );
  }
}

class _TrafficStatisticsPage extends StatefulWidget {
  const _TrafficStatisticsPage();

  @override
  _TrafficStatisticsPageState createState() => _TrafficStatisticsPageState();
}

class _TrafficStatisticsPageState extends State<_TrafficStatisticsPage> {
  final TrafficStatisticsService _trafficStatisticsService = TrafficStatisticsService();
  late Stream<TrafficStatistics> _statisticsStream;
  late TrafficStatistics _currentStatistics;

  final _webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {
          // Show loading indicator
        },
        onPageFinished: (String url) {
          //Hide loading indicator
        },
        onWebResourceError: (WebResourceError error) {
          // Handle errors
        },
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  //..loadRequest(Uri.parse('https://flutter.dev'));

  final _textController = TextEditingController(text: 'https://flutter.dev');

  @override
  void initState() {
    super.initState();

    _trafficStatisticsService.init(); // Initialize the service

    _statisticsStream = _trafficStatisticsService.statisticsStream;
    _currentStatistics = TrafficStatistics(uploadSpeed: 0,
        downloadSpeed: 0,
        totalTx: 0.0,
        totalRx: 0.0,
        uid: 0,
        totalAllTx: 0.0,
        totalAllRx: 0.0);

    // Listen to the statistics stream and update the state with new data
    _statisticsStream.listen((data) {
      setState(() {
        _currentStatistics = data;
      });
    });
  }

  @override
  void dispose() {
    _trafficStatisticsService
        .dispose(); // Dispose the service when the widget is disposed

    _textController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Traffic Statistics Monitor'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Download Speed: ${_currentStatistics.downloadSpeed} Kbps',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload Speed: ${_currentStatistics.uploadSpeed} Kbps',
                      style: const TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'UID: ${_currentStatistics.uid}',
                      style: const TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Tx Usage: ${(_currentStatistics.totalTx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rx Usage: ${(_currentStatistics.totalRx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'ALL Tx Usage: ${(_currentStatistics.totalAllTx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ALL Rx Usage: ${(_currentStatistics.totalAllRx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            Padding( // Web browser section
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Enter URL',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _webViewController.loadRequest(Uri.parse(_textController.text));
                        },
                        child: const Text('GO'),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 400, // Adjust height as needed
                    child: WebViewWidget(controller: _webViewController),
                  ),
                ],
              ),
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
