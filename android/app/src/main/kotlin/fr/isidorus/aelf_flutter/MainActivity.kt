package fr.isidorus.aelf_flutter

import android.view.View
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aelf_flutter/display")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "applyLowProfile" -> {
                        applyLowProfile()
                        result.success(null)
                    }
                    "applySystemBars" -> {
                        applySystemBars()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onPostResume() {
        // FlutterActivity resets the system UI flags here, so apply ours after.
        super.onPostResume()
        applySystemBars()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // Back from a dialog, the date picker or the share sheet.
        if (hasFocus) applySystemBars()
    }

    /// Keeps the status bar and hides the navigation bar, which a swipe from
    /// the bottom edge brings back over the content for a few seconds.
    /// Flutter's SystemChrome only offers this sticky behavior when both bars
    /// are hidden, hence the native code.
    private fun applySystemBars() {
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        controller.show(WindowInsetsCompat.Type.statusBars())
        controller.hide(WindowInsetsCompat.Type.navigationBars())
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }

    @Suppress("DEPRECATION")
    private fun applyLowProfile() {
        window.decorView.systemUiVisibility =
            window.decorView.systemUiVisibility or View.SYSTEM_UI_FLAG_LOW_PROFILE
    }
}
