package com.mobiusdesk.mobius_desk_flutter

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.mobiusdesk.accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> {
                        result.success(RemoteControlAccessibilityService.isRunning())
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    }
                    "performClick" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        val service = RemoteControlAccessibilityService.getInstance()
                        if (service != null) {
                            result.success(service.click(x, y))
                        } else {
                            result.error("NO_SERVICE", "Accessibility service not running", null)
                        }
                    }
                    "performLongClick" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        val service = RemoteControlAccessibilityService.getInstance()
                        if (service != null) {
                            result.success(service.longClick(x, y))
                        } else {
                            result.error("NO_SERVICE", "Accessibility service not running", null)
                        }
                    }
                    "performSwipe" -> {
                        val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                        val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                        val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                        val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                        val duration = call.argument<Int>("duration")?.toLong() ?: 300L
                        val service = RemoteControlAccessibilityService.getInstance()
                        if (service != null) {
                            result.success(service.swipe(startX, startY, endX, endY, duration))
                        } else {
                            result.error("NO_SERVICE", "Accessibility service not running", null)
                        }
                    }
                    "performScroll" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        val dx = call.argument<Double>("dx")?.toFloat() ?: 0f
                        val dy = call.argument<Double>("dy")?.toFloat() ?: 0f
                        val service = RemoteControlAccessibilityService.getInstance()
                        if (service != null) {
                            result.success(service.scroll(x, y, dx, dy))
                        } else {
                            result.error("NO_SERVICE", "Accessibility service not running", null)
                        }
                    }
                    "performMove" -> {
                        val x = call.argument<Double>("x")?.toFloat() ?: 0f
                        val y = call.argument<Double>("y")?.toFloat() ?: 0f
                        val service = RemoteControlAccessibilityService.getInstance()
                        if (service != null) {
                            result.success(service.movePointer(x, y))
                        } else {
                            result.error("NO_SERVICE", "Accessibility service not running", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
