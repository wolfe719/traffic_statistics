import 'dart:async';
import 'package:flutter/services.dart';

// Data class to hold network speed data
class TrafficStatistics {
  // Hold upload and download and upload speed
  final int uploadSpeed;
  final int downloadSpeed;

  // Hold network transmit and receive data
  // Unit of measure is constant for Android,
  //     and handed to us in iOS
  //
  // Information Transfer
  // Units of bits commonly represent the amount of transferred information.
  //
  // Decimal Bits | Coefficient | Binary Bits | Coefficient
  //   kilobits   |   1000      |  kibibits   |   1024
  //   megabits   |   1000e2    |  mebibits   |   1024e2
  //   gigabits   |   1000e3    |  gibibits   |   1024e3
  //   terabits   |   1000e4    |  tebibits   |   1024e4
  //   petabits   |   1000e5    |  pebibits   |   1024e5
  //   exabits    |   1000e6    |  exbibits   |   1024e6
  //   zettabits  |   1000e7    |  zebibits   |   1024e7
  //   yottabits  |   1000e8    |  yobibits   |   1024e8
  //
  final double totalTx;
  final double totalRx;

  final int uid;

  final double totalAllTx;
  final double totalAllRx;

  TrafficStatistics({
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.totalTx,
    required this.totalRx,
    required this.uid,
    required this.totalAllTx,
    required this.totalAllRx});
}

// Service class for network speed monitoring
class TrafficStatisticsService {

  // EventChannel for receiving network speed updates from the native side
  static const EventChannel _statisticsChannel =
      EventChannel('traffic_statistics/traffic_statistics');

  // StreamSubscription for managing the subscription to the EventChannel
  StreamSubscription? _subscription;

  // StreamController to broadcast network speed data to multiple listeners
  StreamController<TrafficStatistics> _statisticsStreamController =
      StreamController<TrafficStatistics>.broadcast();

  // Private constructor to ensure only one instance is created
  TrafficStatisticsService._internal();

  // Singleton instance of the service
  static final TrafficStatisticsService _instance = TrafficStatisticsService._internal();

  // Factory constructor to return the singleton instance
  factory TrafficStatisticsService() => _instance;

  // Initialize the service and start listening to network speed updates
  void init() {
    // Dispose any existing subscription before initializing a new one
    dispose();

    _statisticsStreamController = StreamController<TrafficStatistics>.broadcast();

    // Listen to the EventChannel and handle incoming data
    _subscription = _statisticsChannel.receiveBroadcastStream().listen((data) {
      // Parse the incoming data and create a NetworkSpeedData object
      TrafficStatistics statistics = TrafficStatistics(
        uploadSpeed: data['uploadSpeed'] ?? 0.0,
        downloadSpeed: data['downloadSpeed'] ?? 0.0,
        totalTx: data['totalTx'] ?? 0.0,
        totalRx: data['totalRx'] ?? 0.0,
        uid: data['uid'] ?? 0,
        totalAllTx: data['totalAllTx'] ?? 0.0,
        totalAllRx: data['totalAllRx'] ?? 0.0
      );
      // Add the parsed data to the stream controller
      _statisticsStreamController.add(statistics);
    }, onError: (error) {
      // Handle errors by adding them to the stream controller
      _statisticsStreamController.addError("Failed to get network speed: '$error'.");
    });
  }

  // Stream to allow listeners to receive network statistics updates
  Stream<TrafficStatistics> get statisticsStream => _statisticsStreamController.stream;

  // Dispose the service by closing the stream controller and cancelling the subscription
  void dispose() {
    _statisticsStreamController.close();
    _subscription?.cancel();
    _subscription = null;
  }
}
