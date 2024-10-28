package us.lobo.traffic_statistics

import android.annotation.SuppressLint
import android.net.TrafficStats
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class TrafficStatisticsPlugin : FlutterPlugin, EventChannel.StreamHandler {
    private lateinit var eventChannel: EventChannel
    private val STATISTICS_CHANNEL = "traffic_statistics/traffic_statistics"
    private val UPDATE_INTERVAL = 1000L // 1 second

//    private var index = 0;

    private val uid = android.os.Process.myUid()

    private val baseRxBytes = TrafficStats.getUidRxBytes(uid).toDouble()
    private val baseTxBytes = TrafficStats.getUidTxBytes(uid).toDouble()
    private val baseTotalRxBytes = TrafficStats.getTotalRxBytes().toDouble()
    private val baseTotalTxBytes = TrafficStats.getTotalTxBytes().toDouble()

    private val handler = Handler(Looper.getMainLooper())
    private var speedRunnable: Runnable? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, STATISTICS_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        startStatisticsMonitoring(events)
    }

    override fun onCancel(arguments: Any?) {
        stopStatisticsMonitoring()
    }

    private fun startStatisticsMonitoring(events: EventChannel.EventSink?) {
        speedRunnable = object : Runnable {
            @SuppressLint("MissingPermission")
            override fun run() {
                try {
                    val currentRxBytes = TrafficStats.getUidRxBytes(uid).toDouble()
                    val currentTxBytes = TrafficStats.getUidTxBytes(uid).toDouble()
                    val startTime = System.currentTimeMillis()

                    handler.postDelayed({
                        val newRxBytes = TrafficStats.getUidRxBytes(uid).toDouble()
                        val newTxBytes = TrafficStats.getUidTxBytes(uid).toDouble()
                        val endTime = System.currentTimeMillis()

                        var deltaTime = startTime - endTime;
                        if (deltaTime <= 0) {
                            deltaTime = 1;
                        }

                        val currentTotalRxBytes = TrafficStats.getTotalRxBytes().toDouble()
                        val currentTotalTxBytes = TrafficStats.getTotalTxBytes().toDouble()

                        val downloadSpeed = ((newRxBytes - currentRxBytes) * 1000 / deltaTime) / 1024 // Speed in Kbps
                        val uploadSpeed = ((newTxBytes - currentTxBytes) * 1000 / deltaTime) / 1024 // Speed in Kbps

                        events?.success(
                            mapOf("uploadSpeed" to uploadSpeed.toInt(),
                                "downloadSpeed" to downloadSpeed.toInt(),
                                "totalTx" to newTxBytes - baseTxBytes,
                                "totalRx" to newRxBytes - baseRxBytes,
                                "uid" to uid,
                                "totalAllTx" to currentTotalTxBytes - baseTotalTxBytes,
                                "totalAllRx" to currentTotalRxBytes - baseTotalRxBytes
                            )
                        )
                    }, UPDATE_INTERVAL)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                handler.postDelayed(this, UPDATE_INTERVAL)
            }
        }
        handler.post(speedRunnable!!)
    }

    private fun stopStatisticsMonitoring() {
        speedRunnable?.let { handler.removeCallbacks(it) }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel.setStreamHandler(null)
    }
}
