import Flutter
import UIKit
import MetricKit
import RealReachability

public class TrafficStatisticsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private static let SPEED_CHANNEL = "traffic_statistics/network_speed"
    private static let USAGE_CHANNEL = "traffic_statistics/network_usage"

    private var started: Bool = false

    private var timer: Timer?
    private var previousBytesReceived: Int64 = 0
    private var previousBytesSent: Int64 = 0

    private var previousUploadSpeed: Int64 = 0
    private var previousDownloadSpeed: Int64 = 0

    private var totalBytesSent: Int64 = 0
    private var totalBytesReceived: Int64 = 0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let speedChannel = FlutterEventChannel(name: SPEED_CHANNEL, binaryMessenger: registrar.messenger())
        let usageChannel = FlutterEventChannel(name: USAGE_CHANNEL, binaryMessenger: registrar.messenger())
        let instance = TrafficStatisticsPlugin()
        speedCannel.setStreamHandler(instance)
        usageChannel.setStreamHandler(instance)
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

    private func startSpeedMonitoring() {
        if started {
            return
        }
        started = true
        RealReachability.sharedInstance()?.startNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(networkChanged(_:)), name: NSNotification.Name.realReachabilityChanged, object: nil)
        startTimer()
    }

    private func stopSpeedMonitoring() {
        if !started {
            return
        }
        started = false
        RealReachability.sharedInstance()?.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.realReachabilityChanged, object: nil)
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
                                 "totalTx": 0,
                                 "totalRx": 0])
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
        calculateSpeed()
        calculateUsage()
    }

    @objc private func calculateSpeed() {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>? = nil
        var uploadSpeed: Int64 = 0
        var downloadSpeed: Int64 = 0

        if getifaddrs(&ifaddrs) == 0 {
            var pointer = ifaddrs
            while pointer != nil {
                if let ifa_name = pointer?.pointee.ifa_name {
                    let name = String(cString: ifa_name)
                    if name == "en0" || name == "pdp_ip0" { // en0 for Wi-Fi, pdp_ip0 for cellular
                        if let data = pointer?.pointee.ifa_data {
                            let networkData = data.load(as: if_data.self)
                            let receivedBytes = Int64(networkData.ifi_ibytes)
                            let sentBytes = Int64(networkData.ifi_obytes)
                            
                            if self.previousBytesReceived > 0 {
                                let downloadBytes = receivedBytes - self.previousBytesReceived
                                downloadSpeed = (downloadBytes * 8) / 1000 // Convert to kbps
                            }
                            if self.previousBytesSent > 0 {
                                let uploadBytes = sentBytes - self.previousBytesSent
                                uploadSpeed = (uploadBytes * 8) / 1000 // Convert to kbps
                            }
                            
                            self.previousBytesReceived = receivedBytes
                            self.previousBytesSent = sentBytes
                        }
                    }
                }
                pointer = pointer?.pointee.ifa_next
            }
            freeifaddrs(ifaddrs)
        }

        previousUploadSpeed = uploadSpeed
        previousDownloadSpeed = downloadSpeed

        DispatchQueue.main.async {
            self.eventSink?(["uploadSpeed": uploadSpeed,
                             "downloadSpeed": downloadSpeed,
                             "totalTx": totalBytesSent,
                             "totalRx": totalBytesSent])
        }
    }

    func calculateUsage() async {
        do {
            let metricManager = MXMetricManager.shared
            let networkMetrics = await metricManager.metrics(for: MXMetricPayload.self)

            var totalTransmitted: Int64 = 0
            var totalReceived: Int64 = 0

            for metricPayload in networkMetrics {
                if let networkTransferMetric = metricPayload.networkTransferMetrics.first {
                    totalTransmitted += networkTransferMetric.cumulativeCellularTxBytes + networkTransferMetric.cumulativeWifiTxBytes
                    totalReceived += networkTransferMetric.cumulativeCellularRxBytes + networkTransferMetric.cumulativeWifiRxBytes
                }
            }

            totalBytesSent = totalTransmitted
            totalBytesReceived = totalReceived

            DispatchQueue.main.async {
                self.eventSink?([ "uploadSpeed": previousUploadSpeed,
                                  "downloadSpeed": previousDownloadSpeed,
                                  "totalTx": totalBytesSent,
                                  "totalRx": totalBytesReceived])
            }
        } catch (_) {
            // Do nothing - just wait for next call and try again!
        }
    }
}
