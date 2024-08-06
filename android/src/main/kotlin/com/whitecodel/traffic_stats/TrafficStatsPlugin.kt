package com.whitecodel.traffic_stats

import android.annotation.SuppressLint
import android.net.TrafficStats
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

class TrafficStatsPlugin : FlutterPlugin, EventChannel.StreamHandler {
    private lateinit var eventChannel: EventChannel
    private val SPEED_CHANNEL = "traffic_stats/network_speed"
    private val UPDATE_INTERVAL = 1000L // 1 second

    private val handler = Handler(Looper.getMainLooper())
    private var speedRunnable: Runnable? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, SPEED_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        startSpeedMonitoring(events)
    }

    override fun onCancel(arguments: Any?) {
        stopSpeedMonitoring()
    }

    private fun startSpeedMonitoring(events: EventChannel.EventSink?) {
        speedRunnable = object : Runnable {
            @SuppressLint("MissingPermission")
            override fun run() {
                try {
                    val currentRxBytes = TrafficStats.getTotalRxBytes()
                    val currentTxBytes = TrafficStats.getTotalTxBytes()
                    val startTime = System.currentTimeMillis()

                    handler.postDelayed({
                        val newRxBytes = TrafficStats.getTotalRxBytes()
                        val newTxBytes = TrafficStats.getTotalTxBytes()
                        val endTime = System.currentTimeMillis()

                        val downloadSpeed = ((newRxBytes - currentRxBytes) * 1000 / (endTime - startTime)) / 1024 // Speed in Kbps
                        val uploadSpeed = ((newTxBytes - currentTxBytes) * 1000 / (endTime - startTime)) / 1024 // Speed in Kbps

                        events?.success(mapOf("uploadSpeed" to uploadSpeed, "downloadSpeed" to downloadSpeed))
                    }, UPDATE_INTERVAL)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                handler.postDelayed(this, UPDATE_INTERVAL)
            }
        }
        handler.post(speedRunnable!!)
    }

    private fun stopSpeedMonitoring() {
        speedRunnable?.let { handler.removeCallbacks(it) }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel.setStreamHandler(null)
    }
}
