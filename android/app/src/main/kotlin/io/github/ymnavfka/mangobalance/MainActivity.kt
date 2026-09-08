package io.github.ymnavfka.mangobalance

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mango_balance/notification_settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "openNotificationSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val intents = mutableListOf<Intent>()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val manager = getSystemService(NotificationManager::class.java)
                    val channelId = call.argument<String>("channelId")
                    if (manager.areNotificationsEnabled() && channelId != null &&
                        manager.getNotificationChannel(channelId)?.importance == NotificationManager.IMPORTANCE_NONE) {
                        intents.add(Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            .putExtra(Settings.EXTRA_CHANNEL_ID, channelId))
                    }
                    intents.add(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                }
                intents.add(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName")))
                val opened = intents.any { intent ->
                    try {
                        startActivity(intent)
                        true
                    } catch (_: android.content.ActivityNotFoundException) {
                        false
                    } catch (_: SecurityException) {
                        false
                    }
                }
                result.success(opened)
            }
    }
}
