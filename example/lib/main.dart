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
      body: Column(
        children: [
          Expanded( // Make the existing content scrollable
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Download Speed: ${_currentStatistics.downloadSpeed} Kbps',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Upload Speed: ${_currentStatistics.uploadSpeed} Kbps',
                      style: const TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 64),

                    Text(
                      'UID: ${_currentStatistics.uid}',
                      style: const TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Tx Usage: ${(_currentStatistics.totalTx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rx Usage: ${(_currentStatistics.totalRx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'ALL Tx Usage: ${(_currentStatistics.totalAllTx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ALL Rx Usage: ${(_currentStatistics.totalAllRx / 1024).floor()} kb',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
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
                  height: 300, // Adjust height as needed
                  child: WebViewWidget(controller: _webViewController),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}
