import 'dart:async';
import 'package:flutter/services.dart';

// Data class to hold network speed data
class NetworkSpeedData {
  final int downloadSpeed;
  final int uploadSpeed;

  NetworkSpeedData({required this.downloadSpeed, required this.uploadSpeed});
}

// Service class for network speed monitoring
class NetworkSpeedService {
  // EventChannel for receiving network speed updates from the native side
  static const EventChannel _speedChannel =
      EventChannel('traffic_stats/network_speed');

  // StreamSubscription for managing the subscription to the EventChannel
  StreamSubscription? _subscription;

  // StreamController to broadcast network speed data to multiple listeners
  StreamController<NetworkSpeedData> _speedStreamController =
      StreamController<NetworkSpeedData>.broadcast();

  // Private constructor to ensure only one instance is created
  NetworkSpeedService._internal();

  // Singleton instance of the service
  static final NetworkSpeedService _instance = NetworkSpeedService._internal();

  // Factory constructor to return the singleton instance
  factory NetworkSpeedService() => _instance;

  // Initialize the service and start listening to network speed updates
  void init() {
    // Dispose any existing subscription before initializing a new one
    dispose();

    _speedStreamController = StreamController<NetworkSpeedData>.broadcast();

    // Listen to the EventChannel and handle incoming data
    _subscription = _speedChannel.receiveBroadcastStream().listen((data) {
      // Parse the incoming data and create a NetworkSpeedData object
      NetworkSpeedData speedData = NetworkSpeedData(
        downloadSpeed: data['downloadSpeed'],
        uploadSpeed: data['uploadSpeed'],
      );
      // Add the parsed data to the stream controller
      _speedStreamController.add(speedData);
    }, onError: (error) {
      // Handle errors by adding them to the stream controller
      _speedStreamController.addError("Failed to get network speed: '$error'.");
    });
  }

  // Stream to allow listeners to receive network speed updates
  Stream<NetworkSpeedData> get speedStream => _speedStreamController.stream;

  // Dispose the service by closing the stream controller and cancelling the subscription
  void dispose() {
    _speedStreamController.close();
    _subscription?.cancel();
    _subscription = null;
  }
}
