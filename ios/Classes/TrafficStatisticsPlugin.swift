import Flutter
import UIKit
import MetricKit
import RealReachability

public class TrafficStatisticsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, MXMetricManagerSubscriber {
    private var eventSink: FlutterEventSink?
    private static let STATISTICS_CHANNEL = "traffic_statistics/traffic_statistics"
    
    private var started: Bool = false
    
    private var timer: Timer?
    
    private var baseBytesSent: Double = 0
    private var baseBytesReceived: Double = 0
    
    private var uploadSpeed: Int = 0
    private var downloadSpeed: Int = 0
    
    private var previousBytesSent: Double = 0
    private var previousBytesReceived: Double = 0
    
    private var bytesSent: Double = 0
    private var bytesReceived: Double = 0
    
    private var totalBytesSent: Double = 0.0
    private var totalBytesReceived: Double = 0.0
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let statisticsChannel = FlutterEventChannel(name: STATISTICS_CHANNEL, binaryMessenger: registrar.messenger())
        let instance = TrafficStatisticsPlugin()
        statisticsChannel.setStreamHandler(instance)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        startMonitoring()
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopMonitoring()
        return nil
    }
    
    private func startMonitoring() {
        if started {
            return
        }
        started = true
        RealReachability.sharedInstance()?.startNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(networkChanged(_:)), name: NSNotification.Name.realReachabilityChanged, object: nil)
        
        let metricManager = MXMetricManager.shared
        metricManager.add(self)
        
        startTimer()
    }
    
    private func stopMonitoring() {
        if !started {
            return
        }
        started = false
        RealReachability.sharedInstance()?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.realReachabilityChanged, object: nil)
        
        let metricManager = MXMetricManager.shared
        metricManager.remove(self)
        
        stopTimer()
    }
    
    @objc private func networkChanged(_ notification: Notification) {
        guard let reachability =
                RealReachability.sharedInstance()?.currentReachabilityStatus()
        else { return }
        
        switch reachability {
        case .RealStatusNotReachable:
            DispatchQueue.main.async {
                self.eventSink?(["uploadSpeed": 0,
                                 "downloadSpeed": 0,
                                 "totalTx": 0.0,
                                 "totalRx": 0.0,
                                 "uid": Double(ProcessInfo().processIdentifier),
                                 "totalAllTx": 0.0,
                                 "totalAllRx": 0.0])
            }
        case .RealStatusViaWiFi, .RealStatusViaWWAN:
            // Start the timer to monitor speed
            startTimer()
        default:
            break
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(calculateStats),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func calculateStats() {
        calculateStatistics()
    }
    
    @objc private func calculateStatistics() {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>? = nil
        var setBaseBytes = baseBytesSent == 0 && baseBytesReceived == 0
        
        if getifaddrs(&ifaddrs) == 0 {
            var pointer = ifaddrs
            
            var sent: Int64 = 0
            var received: Int64 = 0
            
            while pointer != nil {
                if let ifa_name = pointer?.pointee.ifa_name {
                    let name = String(cString: ifa_name)
                    if name == "en0" || name == "pdp_ip0" { // en0 for Wi-Fi, pdp_ip0 for cellular
                        if let data = pointer?.pointee.ifa_data {
                            let networkData = data.load(as: if_data.self)
                            let receivedBytes = Int64(networkData.ifi_ibytes)
                            let sentBytes = Int64(networkData.ifi_obytes)
                            
                            if self.previousBytesReceived > 0 {
                                let downloadBytes = Double(receivedBytes) - self.previousBytesReceived
                            }
                            if self.previousBytesSent > 0 {
                                let uploadBytes = Double(sentBytes) - self.previousBytesSent
                            }
                            
                            received += receivedBytes
                            sent += sentBytes
                        }
                    }
                }
                pointer = pointer?.pointee.ifa_next
            }
            freeifaddrs(ifaddrs)
            
            downloadSpeed = Int((received * 8) / 1024) // Convert to kbps
            uploadSpeed = Int((sent * 8) / 1024) // Convert to kbps

            previousBytesSent = bytesSent
            previousBytesReceived = bytesReceived
            
            bytesSent = Double(sent)
            bytesReceived = Double(received)
        }
        
        if setBaseBytes {
            baseBytesSent = previousBytesSent
            baseBytesReceived = previousBytesReceived
        }

        sendEvent()
    }
    
    /**
     @method        didReceiveMetricPayloads:payloads
     @abstract      This method is invoked when a new MXMetricPayload has been received.
     @param         payloads
     An NSArray of MXMetricPayload objects. This array of payloads contains data from previous usage sessions.
     @discussion    You can expect for this method to be invoked atleast once per day when the app is running and subscribers are available.
     @discussion    If no subscribers are available, this method will not be invoked.
     @discussion    Atleast one subscriber must be available to receive metrics.
     @discussion    This method is invoked on a background queue.
     */
    public func didReceive(_ payloads: [MXMetricPayload]) {
        guard payloads.count > 0 else { return }
        
        var totalTransmitted = 0.0
        var totalReceived = 0.0
        
        for payload in payloads {
            if payload.networkTransferMetrics == nil { continue }
            
            let networkMetrics = payload.networkTransferMetrics
            totalTransmitted += (networkMetrics?.cumulativeCellularUpload.value ?? 0.0)
            totalTransmitted += (networkMetrics?.cumulativeWifiUpload.value ?? 0.0)
            totalReceived += (networkMetrics?.cumulativeCellularDownload.value ?? 0.0)
            totalReceived += (networkMetrics?.cumulativeWifiDownload.value ?? 0.0)
        }
        
        totalBytesSent = totalTransmitted
        totalBytesReceived = totalReceived
        
        sendEvent()

    }
    
    private func sendEvent() {
        var totalSent = previousBytesSent - baseBytesSent
        var totalReceived = previousBytesReceived - baseBytesReceived;
        
        DispatchQueue.main.async {
            self.eventSink?(["uploadSpeed": self.uploadSpeed,
                             "downloadSpeed": self.downloadSpeed,
                             "totalTx": self.bytesSent,
                             "totalRx": self.bytesReceived,
                             "uid": Double(ProcessInfo().processIdentifier),
                             "totalAllTx": self.totalBytesSent,
                             "totalAllRx": self.totalBytesReceived])
        }
    }
    
    /**
     @method        didReceiveDiagnosticPayloads:payloads
     @abstract      This method is invoked when a new MXDiagnosticPayload has been received.
     @param         payloads
     An NSArray of MXDiagnosticPayload objects. This array of payloads contains diagnostics from previous usage sessions.
     @discussion    You can expect for this method to be invoked atleast once per day when the app is running and subscribers are available.
     @discussion    If no subscribers are available, this method will not be invoked.
     @discussion    Atleast one subscriber must be available to receive diagnostics.
     @discussion    This method is invoked on a background queue.
     */
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Do nothing with the payloads coming in
    }
    
}
