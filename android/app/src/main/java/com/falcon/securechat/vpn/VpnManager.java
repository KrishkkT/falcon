package com.falcon.securechat.vpn;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * VPN Manager plugin for Flutter integration
 * Handles VPN connection requests from the Flutter app
 */
public class VpnManager implements FlutterPlugin, MethodCallHandler, ActivityAware,
        PluginRegistry.ActivityResultListener {
    
    private static final String TAG = "VpnManager";
    private static final String CHANNEL = "falcon/vpn_manager";
    private static final int VPN_REQUEST_CODE = 24;
    
    private MethodChannel channel;
    private Context context;
    private Activity activity;
    private Result pendingResult;
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
        Log.d(TAG, "VpnManager plugin attached to engine");
    }
    
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "startVpn":
                startVpn(result);
                break;
            case "stopVpn":
                stopVpn(result);
                break;
            case "getVpnStatus":
                getVpnStatus(result);
                break;
            case "isVpnPermissionGranted":
                isVpnPermissionGranted(result);
                break;
            case "requestVpnPermission":
                requestVpnPermission(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }
    
    /**
     * Start the VPN service
     */
    private void startVpn(Result result) {
        Log.i(TAG, "Starting VPN service");
        
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null);
            return;
        }
        
        // Check if VPN permission is granted
        Intent vpnIntent = VpnService.prepare(context);
        
        if (vpnIntent != null) {
            // Permission not granted, request it
            Log.d(TAG, "VPN permission not granted, requesting...");
            pendingResult = result;
            activity.startActivityForResult(vpnIntent, VPN_REQUEST_CODE);
        } else {
            // Permission already granted, start VPN
            Log.d(TAG, "VPN permission already granted, starting service");
            startVpnService();
            result.success("VPN service started");
        }
    }
    
    /**
     * Stop the VPN service
     */
    private void stopVpn(Result result) {
        Log.i(TAG, "Stopping VPN service");
        
        Intent stopIntent = new Intent(context, FalconVpnService.class);
        stopIntent.setAction("STOP_VPN");
        context.startService(stopIntent);
        
        result.success("VPN service stopped");
    }
    
    /**
     * Get current VPN status
     */
    private void getVpnStatus(Result result) {
        // For now, return a simple status
        // In a real implementation, you would check the actual service status
        result.success("disconnected");
    }
    
    /**
     * Check if VPN permission is granted
     */
    private void isVpnPermissionGranted(Result result) {
        Intent vpnIntent = VpnService.prepare(context);
        result.success(vpnIntent == null);
    }
    
    /**
     * Request VPN permission
     */
    private void requestVpnPermission(Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null);
            return;
        }
        
        Intent vpnIntent = VpnService.prepare(context);
        
        if (vpnIntent != null) {
            pendingResult = result;
            activity.startActivityForResult(vpnIntent, VPN_REQUEST_CODE);
        } else {
            result.success(true);
        }
    }
    
    /**
     * Actually start the VPN service
     */
    private void startVpnService() {
        Intent serviceIntent = new Intent(context, FalconVpnService.class);
        context.startForegroundService(serviceIntent);
        Log.d(TAG, "VPN service intent sent");
    }
    
    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == VPN_REQUEST_CODE && pendingResult != null) {
            Log.d(TAG, "VPN permission result: " + resultCode);
            
            if (resultCode == Activity.RESULT_OK) {
                // Permission granted, start VPN
                Log.i(TAG, "VPN permission granted");
                startVpnService();
                pendingResult.success("VPN service started");
            } else {
                // Permission denied
                Log.w(TAG, "VPN permission denied");
                pendingResult.error("PERMISSION_DENIED", "VPN permission denied by user", null);
            }
            
            pendingResult = null;
            return true;
        }
        
        return false;
    }
    
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        Log.d(TAG, "VpnManager plugin detached from engine");
    }
    
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
        Log.d(TAG, "VpnManager attached to activity");
    }
    
    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
        Log.d(TAG, "VpnManager detached from activity for config changes");
    }
    
    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
        Log.d(TAG, "VpnManager reattached to activity after config changes");
    }
    
    @Override
    public void onDetachedFromActivity() {
        activity = null;
        Log.d(TAG, "VpnManager detached from activity");
    }
}