package com.gitlab.nathanael2.aelf_flutter;

import android.content.res.Configuration;

import android.view.Display;
import android.view.Surface;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    /**
     * To help the prayer, we strive to dim distractions while not getting in
     * the way of the user.
     * 
     * In practive, a sweet spot is:
     * - Keep the screen on: No need to constantly touch the screen to keep it on
     * - Dim the notifications BUT do not hide them: They must remain at the user's hand
     * - Set the navigation bar as translucent
     * 
     * These settings must be refresh on focus change.
     */
    private void enterLowProfileMode() {
        Window window = getWindow();
        View decorView = window.getDecorView();

        // Dim the notifications
        int uiOptions = decorView.getSystemUiVisibility();
        decorView.setSystemUiVisibility(
            uiOptions | View.SYSTEM_UI_FLAG_LOW_PROFILE
        );

        // Set the navigation bar to translucent mode
        if (hasBottomNavigationBar()) {
            window.addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION);
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION);
        }

        // Keep the screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    private boolean hasBottomNavigationBar() {
        // Detect orientation
        Display getOrient = getWindowManager().getDefaultDisplay();
        boolean isPortrait = getOrient.getRotation() == Surface.ROTATION_0
                || getOrient.getRotation() == Surface.ROTATION_180;

        // Guess the device type
        Configuration cfg = getResources().getConfiguration();
        boolean isTablet = cfg.smallestScreenWidthDp >= 600;

        // Guess navigation bar location (bottom or side)
        return isPortrait || isTablet;
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        enterLowProfileMode();
    }

    @Override
    public void onMultiWindowModeChanged(boolean isInMultiWindowMode) {
        super.onMultiWindowModeChanged(isInMultiWindowMode);
        enterLowProfileMode();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        enterLowProfileMode();
    }
}
