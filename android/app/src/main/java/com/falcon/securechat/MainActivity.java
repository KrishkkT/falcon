package com.falcon.securechat;

import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import androidx.annotation.NonNull;

import com.falcon.securechat.vpn.VpnManager;
import com.falcon.securechat.ScreenshotProtectionPlugin;

public class MainActivity extends FlutterActivity {
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // Register VPN Manager plugin
        flutterEngine.getPlugins().add(new VpnManager());
        
        // Register Screenshot Protection plugin
        flutterEngine.getPlugins().add(new ScreenshotProtectionPlugin());
    }
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }
}