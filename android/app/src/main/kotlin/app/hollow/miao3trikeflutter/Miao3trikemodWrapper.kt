package app.hollow.miao3trikeflutter

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.widget.Toast
import androidx.core.app.NotificationManagerCompat
import com.miao3strikemod.matches.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class Miao3trikemodWrapper : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.miao3strikemod/bridge")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "checkAccessibilityPermission" -> {
                    result.success(checkAccessibilityPermission())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val isGranted = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(context)
                    } else {
                        true
                    }
                    result.success(isGranted)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "startFloatingService" -> {
                    result.success(startFloatingService())
                }
                "stopFloatingService" -> {
                    stopFloatingService()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(isServiceRunning())
                }
                "setFunctionEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    VolumeKeyAccessibilityService.setFunctionEnabled(enabled)
                    result.success(true)
                }
                "isFunctionEnabled" -> {
                    result.success(VolumeKeyAccessibilityService.isFunctionEnabled())
                }
                "getMacroConfig" -> {
                    result.success(getMacroConfig())
                }
                "saveMacroConfig" -> {
                    val config = call.arguments as? Map<String, Any>
                    config?.let { saveMacroConfig(it) }
                    result.success(true)
                }
                "resetMacroConfig" -> {
                    MacroConfig.resetToDefaults(context)
                    result.success(true)
                }
                "getPlatformInfo" -> {
                    result.success(getPlatformInfo())
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("EXCEPTION", e.message, e.stackTraceToString())
        }
    }

    private fun checkAccessibilityPermission(): Boolean {
        val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? android.view.accessibility.AccessibilityManager
        if (manager == null) return false
        
        val enabledServices = manager.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        if (enabledServices == null) return false
        
        val myPackage = context.packageName.lowercase(Locale.getDefault())
        for (serviceInfo in enabledServices) {
            val id = serviceInfo.id?.lowercase(Locale.getDefault())
            if (id != null && id.contains(myPackage)) {
                return true
            }
        }
        return false
    }

    private fun requestAccessibilityPermission() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
            Toast.makeText(context, "请在无障碍设置中开启喵3StrikeMod", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(context, "无法打开无障碍设置", Toast.LENGTH_SHORT).show()
        }
    }

    private fun requestOverlayPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:${context.packageName}")
                )
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun startFloatingService(): Boolean {
        // 检查悬浮窗权限
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            Toast.makeText(context, "请先授予悬浮窗权限", Toast.LENGTH_SHORT).show()
            return false
        }
        
        // 检查无障碍权限
        if (!checkAccessibilityPermission()) {
            Toast.makeText(context, "请先开启无障碍服务", Toast.LENGTH_SHORT).show()
            return false
        }

        try {
            val serviceIntent = Intent(context, FloatingWindowService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            VolumeKeyAccessibilityService.setMasterEnabled(true)
            Toast.makeText(context, "悬浮窗服务已启动", Toast.LENGTH_SHORT).show()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(context, "启动服务失败: ${e.message}", Toast.LENGTH_SHORT).show()
            return false
        }
    }

    private fun stopFloatingService() {
        try {
            val intent = Intent(context, FloatingWindowService::class.java)
            context.stopService(intent)
            FloatingWindowService.stopService(context)
            VolumeKeyAccessibilityService.setMasterEnabled(false)
            Toast.makeText(context, "悬浮窗服务已停止", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isServiceRunning(): Boolean {
        try {
            // 先检查静态标志
            if (FloatingWindowService.isRunning()) return true
            
            // 再通过ActivityManager检查
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? android.app.ActivityManager
            if (manager == null) return false
            
            val runningServices = manager.getRunningServices(Integer.MAX_VALUE)
            for (serviceInfo in runningServices) {
                if (FloatingWindowService::class.java.name == serviceInfo.service.className) {
                    return true
                }
            }
            return false
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun getMacroConfig(): Map<String, Any> {
        return try {
            val delays = MacroConfig.load(context)
            mapOf(
                "startupDelayMs" to delays.startupDelayMs,
                "stepDelayMs" to delays.stepDelayMs,
                "dragDurationMs" to delays.dragDurationMs,
                "holdDelayMs" to delays.holdDelayMs,
                "clickCaptureEnabled" to MacroConfig.isClickCaptureEnabled(context),
                "stepMacroDelayMs" to MacroConfig.getStepMacroDelayMs(context),
                "stepMacroEnabled" to MacroConfig.isStepMacroEnabled(context)
            )
        } catch (e: Exception) {
            e.printStackTrace()
            emptyMap()
        }
    }

    private fun saveMacroConfig(config: Map<String, Any>) {
        try {
            val delays = MacroConfig.MacroDelays(
                (config["startupDelayMs"] as? Number)?.toLong() ?: MacroConfig.DEFAULT_STARTUP_DELAY_MS,
                (config["stepDelayMs"] as? Number)?.toLong() ?: MacroConfig.DEFAULT_STEP_DELAY_MS,
                (config["dragDurationMs"] as? Number)?.toLong() ?: MacroConfig.DEFAULT_DRAG_DURATION_MS,
                (config["holdDelayMs"] as? Number)?.toLong() ?: MacroConfig.DEFAULT_HOLD_DELAY_MS
            )
            
            MacroConfig.save(context, delays)
            MacroConfig.setClickCaptureEnabled(context, config["clickCaptureEnabled"] as? Boolean ?: MacroConfig.DEFAULT_CLICK_CAPTURE_ENABLED)
            MacroConfig.setStepMacroDelayMs(context, (config["stepMacroDelayMs"] as? Number)?.toLong() ?: MacroConfig.DEFAULT_STEP_MACRO_DELAY_MS)
            MacroConfig.setStepMacroEnabled(context, config["stepMacroEnabled"] as? Boolean ?: MacroConfig.DEFAULT_STEP_MACRO_ENABLED)
            
            Toast.makeText(context, "配置已保存", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(context, "保存配置失败", Toast.LENGTH_SHORT).show()
        }
    }

    private fun getPlatformInfo(): Map<String, Any> {
        return mapOf(
            "platform" to "Android",
            "version" to android.os.Build.VERSION.SDK_INT,
            "versionName" to android.os.Build.VERSION.RELEASE,
            "brand" to android.os.Build.BRAND,
            "model" to android.os.Build.MODEL,
            "deviceId" to UUID.randomUUID().toString(),
            "hasOverlayPermission" to if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(context)
            } else true,
            "hasAccessibilityPermission" to checkAccessibilityPermission(),
            "hasNotificationPermission" to NotificationManagerCompat.from(context).areNotificationsEnabled()
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}