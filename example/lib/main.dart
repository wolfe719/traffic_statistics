import 'package:flutter/material.dart';
import 'package:traffic_statistics/traffic_statistics.dart'; // Update this import based on your actual package path

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
      home: const _NetworkStatisticsPage(),
    );
  }
}

class _NetworkStatisticsPage extends StatefulWidget {
  const _NetworkStatisticsPage();

  @override
  _NetworkStatisticsPageState createState() => _NetworkStatisticsPageState();
}

class _NetworkStatisticsPageState extends State<_NetworkStatisticsPage> {
  final NetworkSpeedAndUsageService _networkSpeedAndUsageService = NetworkSpeedAndUsageService();
  late Stream<NetworkStatistics> _statisticsStream;
  late NetworkStatistics _currentStatistics;

  @override
  void initState() {
    super.initState();
    _networkSpeedAndUsageService.init(); // Initialize the service

    _statisticsStream = _networkSpeedAndUsageService.statisticsStream;
    _currentStatistics = NetworkStatistics(uploadSpeed: 0,
                                           downloadSpeed: 0,
                                           overallTx: 0,
                                           overallRx: 0);

    // Listen to the statistics stream and update the state with new data
    _statisticsStream.listen((data) {
      setState(() {
        _currentStatistics = data;
      });
    });
  }

  @override
  void dispose() {
    _networkSpeedAndUsageService
        .dispose(); // Dispose the service when the widget is disposed

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Speed And Usage Monitor'),
      ),
      body: Center(
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

            Text(
              'Tx Usage: ${_currentStatistics.overallTx} ????',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Rx Usage: ${_currentStatistics.overallRx} ????',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
