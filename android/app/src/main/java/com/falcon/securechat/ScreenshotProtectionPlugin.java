package com.falcon.securechat;

import android.app.Activity;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class ScreenshotProtectionPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Activity activity;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "falcon/screenshot_protection");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "No activity available", null);
            return;
        }

        switch (call.method) {
            case "enableScreenshotProtection":
                enableScreenshotProtection(result);
                break;
            case "disableScreenshotProtection":
                disableScreenshotProtection(result);
                break;
            case "enableScreenRecordingProtection":
                enableScreenRecordingProtection(result);
                break;
            case "disableScreenRecordingProtection":
                disableScreenRecordingProtection(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void enableScreenshotProtection(Result result) {
        try {
            activity.runOnUiThread(() -> {
                activity.getWindow().setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE
                );
            });
            result.success(true);
        } catch (Exception e) {
            result.error("SCREENSHOT_PROTECTION_ERROR", "Failed to enable screenshot protection", e);
        }
    }

    private void disableScreenshotProtection(Result result) {
        try {
            activity.runOnUiThread(() -> {
                activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
            });
            result.success(true);
        } catch (Exception e) {
            result.error("SCREENSHOT_PROTECTION_ERROR", "Failed to disable screenshot protection", e);
        }
    }

    private void enableScreenRecordingProtection(Result result) {
        // On Android, FLAG_SECURE also prevents screen recording
        enableScreenshotProtection(result);
    }

    private void disableScreenRecordingProtection(Result result) {
        // On Android, FLAG_SECURE also prevents screen recording
        disableScreenshotProtection(result);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        this.activity = null;
    }
}