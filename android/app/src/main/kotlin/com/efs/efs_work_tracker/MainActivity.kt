package com.efs.efs_work_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertsChannel()
    }

    // Push alerts arrive on this channel (see AndroidManifest and the
    // send-notification-push function). Without it Android files them under a
    // silent default channel: no sound and no banner. Creating a channel that
    // already exists changes nothing, so the user's own settings are kept.
    private fun createAlertsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "alerts",
            "التنبيهات",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = "طلبات تنتظر المراجعة وقرارات طلباتك"
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }
}
