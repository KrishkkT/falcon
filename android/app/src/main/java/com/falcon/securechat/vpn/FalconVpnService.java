package com.falcon.securechat.vpn;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.net.VpnService;
import android.os.Build;
import android.os.Handler;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.content.pm.ServiceInfo;
import androidx.annotation.Nullable;

import com.falcon.securechat.MainActivity;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class FalconVpnService extends VpnService {
    private static final String TAG = "FalconVpnService";
    private static final String CHANNEL_ID = "falcon_vpn_channel";
    private static final int NOTIFICATION_ID = 1337;
    
    // WireGuard Configuration
    private static final String VPN_SERVER_IP = "45.32.153.168"; // Replace with actual VPN server
    private static final int VPN_SERVER_PORT = 51820;
    private static final String VPN_LOCAL_IP = "10.8.0.2";
    private static final String VPN_DNS = "8.8.8.8";
    
    private ParcelFileDescriptor vpnInterface;
    private ExecutorService executorService;
    private DatagramChannel vpnChannel;
    private WireGuardConfig wireGuardConfig;
    private boolean isConnected = false;
    private Thread tunnelThread;
    
    public static class VpnConnectionResult {
        public final boolean success;
        public final String message;
        
        public VpnConnectionResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }
    
    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        executorService = Executors.newFixedThreadPool(2);
        wireGuardConfig = new WireGuardConfig();
        Log.i(TAG, "FalconVpnService created");
    }
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;
        
        if ("STOP_VPN".equals(action)) {
            stopVpnConnection();
            return START_NOT_STICKY;
        }
        
        Log.i(TAG, "Starting Falcon VPN service...");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, createNotification("Connecting...", false), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);
        } else {
            startForeground(NOTIFICATION_ID, createNotification("Connecting...", false));
        }
        
        executorService.execute(() -> {
            VpnConnectionResult result = establishVpnConnection();
            
            if (result.success) {
                Log.i(TAG, "VPN connection established successfully");
                updateNotification("Connected securely", true);
                isConnected = true;
                startDataTransmission();
            } else {
                Log.e(TAG, "Failed to establish VPN connection: " + result.message);
                updateNotification("Connection failed", false);
                stopSelf();
            }
        });
        
        return START_STICKY;
    }
    
    private VpnConnectionResult establishVpnConnection() {
        try {
            // Initialize WireGuard configuration
            if (!wireGuardConfig.initialize()) {
                return new VpnConnectionResult(false, "Failed to initialize WireGuard configuration");
            }
            
            // Create VPN interface
            Builder builder = new Builder();
            builder.setSession("Falcon VPN")
                   .addAddress(VPN_LOCAL_IP, 24)
                   .addDnsServer(VPN_DNS)
                   .setMtu(1420)
                   .setBlocking(false);
            
            // For local development, route most traffic through VPN but exclude local networks
            // This is a simpler approach that works across all Android versions
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // Route all traffic through VPN by default
                builder.addRoute("0.0.0.0", 0);
                
                // Note: We're not using excludeRoute because it requires IpPrefix which has compatibility issues
                // Instead, we'll handle local traffic at the application level in Flutter
            } else {
                // For older Android versions
                builder.addRoute("0.0.0.0", 0);
            }
            
            vpnInterface = builder.establish();
            
            if (vpnInterface == null) {
                return new VpnConnectionResult(false, "Failed to establish VPN interface");
            }
            
            // Create UDP channel for WireGuard communication
            vpnChannel = DatagramChannel.open();
            vpnChannel.connect(new InetSocketAddress(VPN_SERVER_IP, VPN_SERVER_PORT));
            vpnChannel.configureBlocking(false);
            
            Log.i(TAG, "VPN interface and channel established");
            return new VpnConnectionResult(true, "VPN connection established");
            
        } catch (Exception e) {
            Log.e(TAG, "Error establishing VPN connection", e);
            return new VpnConnectionResult(false, "Connection error: " + e.getMessage());
        }
    }
    
    private void startDataTransmission() {
        if (vpnInterface == null || vpnChannel == null) {
            Log.e(TAG, "Cannot start data transmission - interface or channel is null");
            return;
        }
        
        tunnelThread = new Thread(() -> {
            Log.i(TAG, "Starting VPN data transmission");
            
            FileInputStream inputStream = new FileInputStream(vpnInterface.getFileDescriptor());
            FileOutputStream outputStream = new FileOutputStream(vpnInterface.getFileDescriptor());
            
            ByteBuffer packet = ByteBuffer.allocate(32767);
            
            try {
                while (isConnected && !Thread.currentThread().isInterrupted()) {
                    // Read from VPN interface
                    packet.clear();
                    int length = inputStream.read(packet.array());
                    
                    if (length > 0) {
                        // For split tunneling, we would check if this packet is for a local address
                        // and handle it differently, but for simplicity we'll process all packets
                        
                        // Encrypt and send through WireGuard tunnel
                        packet.limit(length);
                        byte[] encryptedData = wireGuardConfig.encryptPacket(packet.array(), length);
                        
                        if (encryptedData != null) {
                            ByteBuffer encryptedPacket = ByteBuffer.wrap(encryptedData);
                            vpnChannel.write(encryptedPacket);
                        }
                    }
                    
                    // Read from WireGuard tunnel
                    packet.clear();
                    int receivedLength = vpnChannel.read(packet);
                    
                    if (receivedLength > 0) {
                        // Decrypt and write to VPN interface
                        byte[] decryptedData = wireGuardConfig.decryptPacket(packet.array(), receivedLength);
                        
                        if (decryptedData != null) {
                            outputStream.write(decryptedData);
                        }
                    }
                    
                    // Small delay to prevent CPU spinning
                    Thread.sleep(1);
                }
            } catch (IOException | InterruptedException e) {
                if (isConnected) {
                    Log.e(TAG, "Error in data transmission", e);
                }
            } finally {
                try {
                    inputStream.close();
                    outputStream.close();
                } catch (IOException e) {
                    Log.e(TAG, "Error closing streams", e);
                }
            }
            
            Log.i(TAG, "VPN data transmission stopped");
        });
        
        tunnelThread.start();
    }
    
    private void stopVpnConnection() {
        Log.i(TAG, "Stopping VPN connection");
        isConnected = false;
        
        if (tunnelThread != null) {
            tunnelThread.interrupt();
            try {
                tunnelThread.join(5000); // Wait up to 5 seconds
            } catch (InterruptedException e) {
                Log.w(TAG, "Interrupted while waiting for tunnel thread to stop");
            }
        }
        
        if (vpnChannel != null) {
            try {
                vpnChannel.close();
            } catch (IOException e) {
                Log.e(TAG, "Error closing VPN channel", e);
            }
            vpnChannel = null;
        }
        
        if (vpnInterface != null) {
            try {
                vpnInterface.close();
            } catch (IOException e) {
                Log.e(TAG, "Error closing VPN interface", e);
            }
            vpnInterface = null;
        }
        
        stopForeground(true);
        stopSelf();
    }
    
    @Override
    public void onDestroy() {
        super.onDestroy();
        stopVpnConnection();
        
        if (executorService != null) {
            executorService.shutdown();
        }
        
        Log.i(TAG, "FalconVpnService destroyed");
    }
    
    @Nullable
    @Override
    public android.os.IBinder onBind(Intent intent) {
        return null;
    }
    
    private Notification createNotification(String contentText, boolean connected) {
        Intent stopIntent = new Intent(this, FalconVpnService.class);
        stopIntent.setAction("STOP_VPN");
        PendingIntent stopPendingIntent = PendingIntent.getService(this, 0, stopIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        
        Intent mainIntent = new Intent(this, MainActivity.class);
        PendingIntent mainPendingIntent = PendingIntent.getActivity(this, 0, mainIntent, 
            PendingIntent.FLAG_IMMUTABLE);
        
        Notification.Builder builder = new Notification.Builder(this)
                .setContentTitle("Falcon VPN")
                .setContentText(contentText)
                .setContentIntent(mainPendingIntent)
                .setSmallIcon(connected ? android.R.drawable.presence_online : android.R.drawable.presence_busy)
                .addAction(android.R.drawable.ic_delete, "Disconnect", stopPendingIntent)
                .setOngoing(true);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(CHANNEL_ID);
        }
        
        return builder.build();
    }
    
    private void updateNotification(String contentText, boolean connected) {
        NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.notify(NOTIFICATION_ID, createNotification(contentText, connected));
        }
    }
    
    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Falcon VPN",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Secure VPN tunnel for Falcon Chat");
            channel.setShowBadge(false);
            
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(channel);
            }
        }
    }
    
    // Public method to check VPN status
    public boolean isVpnConnected() {
        return isConnected && vpnInterface != null;
    }
    
    // Public method to get connection statistics
    public String getConnectionStatus() {
        if (isConnected) {
            return "Connected to " + VPN_SERVER_IP + ":" + VPN_SERVER_PORT;
        } else {
            return "Disconnected";
        }
    }
}