# Falcon Chat - Complete Setup Guide

This comprehensive guide covers everything you need to know to get the Falcon Chat application working, from initial setup to troubleshooting network issues.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Mobile App Configuration](#mobile-app-configuration)
4. [Network Configuration](#network-configuration)
5. [Testing and Verification](#testing-and-verification)
6. [Troubleshooting](#troubleshooting)
7. [Production Deployment](#production-deployment)

## 📋 Prerequisites

### System Requirements
- **Laptop**: Windows 10/11 with at least 8GB RAM
- **Phone**: Android or iOS device
- **Network**: Ability to create mobile hotspot
- **Software**:
  - Node.js v16+ installed
  - Flutter SDK installed
  - MySQL 8.0+ installed
  - Git (optional but recommended)

### Installation Verification

Check that required software is installed:

```bash
node --version
npm --version
flutter --version
mysql --version
```

## 🔧 Backend Setup

### 1. Database Configuration

Ensure MySQL is running and create the database:

```sql
CREATE DATABASE falcon_chat;
CREATE USER 'kt'@'localhost' IDENTIFIED BY 'thekt';
GRANT ALL PRIVILEGES ON falcon_chat.* TO 'kt'@'localhost';
FLUSH PRIVILEGES;
```

### 2. Environment Configuration

Check `backend/.env` file:

```env
PORT=3001
JWT_SECRET=d7QkV9wN2sH1aP0jX5zR8uL3cF6yB4oM7gJ2tE1xV6kC9nU3qW8rY0fA5mZ2dS4p
NODE_ENV=development
SERVER_DOMAIN=172.20.10.2

# MySQL Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=falcon_chat
DB_USER=kt
DB_PASSWORD=thekt
DB_CONNECTION_LIMIT=20

# TOTP Configuration
TOTP_ISSUER=Falcon Chat
TOTP_SERVICE_NAME=Falcon

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Security
BCRYPT_ROUNDS=12
TOKEN_EXPIRY=24h

# WebSocket Configuration
WS_CORS_ORIGIN=*
WS_MAX_CONNECTIONS=1000

# Logging
LOG_LEVEL=info

# Encryption
ENCRYPTION_KEY=X4mR7pV2tJ9cL6yB1zH8qD5sK0fN3uW7
AES_KEY_LENGTH=32

# Demo Users Removal
REMOVE_DEMO_USERS=true
```

### 3. Install Dependencies

```bash
cd V:\falcon\backend
npm install
```

### 4. Start Backend Server

```bash
npm start
```

Expected output:
```
🚀 Initializing Falcon Chat Server...
🗄️  Initializing database connection...
✅ Database connection established
✅ Database "falcon_chat" ready
📋 Creating database tables...
✅ All database tables created successfully
🎉 Database fully initialized and ready!
🗑️  Removing demo users as requested...
🎯 Falcon Chat Server running on http://0.0.0.0:3001
🌐 Health check: http://0.0.0.0:3001/api/health
✅ Production ready - all systems operational!
```

## 📱 Mobile App Configuration

### 1. Flutter Dependencies

```bash
cd V:\falcon
flutter pub get
```

### 2. Network Configuration

Check `lib/services/network_config_service.dart`:

```dart
class NetworkConfigService {
  // Local network configuration (laptop connected to phone hotspot)
  static String _serverIp =
      '172.20.10.2'; // Your laptop's IP when connected to phone hotspot
  static int _serverPort = 3001; // Default port
  // ... rest of configuration
}
```

### 3. Main Application Initialization

Check `lib/main.dart` network initialization:

```dart
Future<void> _initializeNetworkConfig() async {
  try {
    // For your current setup: laptop connected to phone hotspot
    if (kDebugMode) {
      // For development/testing, use local server
      NetworkConfigService.updateForLocalNetwork('172.20.10.2', 3001);
      NetworkConfigService.setProductionMode(false);
      NetworkConfigService.setVpnStatus(false); // Start with VPN off
      debugPrint('🔧 Development mode: Using local server 172.20.10.2:3001');
    } else {
      // For production, use AWS server
      NetworkConfigService.updateForRealDevice('15.206.75.65', 443);
      NetworkConfigService.setProductionMode(true);
      debugPrint('🚀 Production mode: Using AWS server 15.206.75.65:443');
    }
    // ... rest of initialization
  }
}
```

## 🌐 Network Configuration

### 1. Identify Your Hotspot IP

```bash
cd V:\falcon\backend
node find_ip.js
```

Look for output like:
```
Interface: Wi-Fi
  IPv4 Address: 172.20.10.2
  🎯 Potential hotspot IP: 172.20.10.2
  📱 Use this IP on your mobile device
```

### 2. Configure Windows Firewall

Allow Node.js through Windows Firewall:

1. Open Windows Security
2. Go to Firewall & network protection
3. Click "Allow an app through firewall"
4. Click "Change settings"
5. Find "Node.js" or add `C:\Program Files\nodejs\node.exe`
6. Check both "Private" and "Public" networks

### 3. Verify Phone Connection

1. Turn on mobile hotspot on your laptop
2. Connect your phone to the hotspot
3. On your phone, check that it has an IP in the same subnet (e.g., 172.20.10.x)

## 🧪 Testing and Verification

### 1. Backend Health Check

```bash
curl http://localhost:3001/api/health
```

Should return:
```json
{
  "status": "ok",
  "timestamp": "2023-05-15T10:30:45.123Z",
  "version": "1.0.0",
  "database": "MySQL",
  "encryption": "AES-256-GCM"
}
```

### 2. IP Connectivity Test

```bash
curl http://172.20.10.2:3001/api/health
```

Should return the same response as localhost test.

### 3. Mobile App Test

```bash
cd V:\falcon
flutter run
```

### 4. Complete Functionality Test

Once the app is running:

1. **Registration**: Create a new account
2. **Login**: Use biometric authentication
3. **Messaging**: Send a test message to yourself
4. **File Sharing**: Try sending an image
5. **Message Forwarding**: Select and forward a message
6. **Message Deletion**: Delete a message permanently
7. **Security Features**: Test screenshot protection

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Network connection failed" Error

**Diagnosis Steps**:
1. Check if backend server is running
2. Verify IP address configuration
3. Test local and IP connectivity
4. Check Windows Firewall settings

**Solutions**:
- See [TROUBLESHOOTING_NETWORK.md](file:///V:/falcon/TROUBLESHOOTING_NETWORK.md) for detailed steps

#### Issue 2: Biometric Authentication Not Working

**Diagnosis Steps**:
1. Check device biometric capabilities
2. Verify app permissions
3. Test fallback to PIN/pattern

**Solution**:
The app should automatically fall back to device credentials if biometrics fail.

#### Issue 3: Messages Not Aligning Properly

**Diagnosis Steps**:
1. Check that user IDs are being properly set
2. Verify message sender/receiver identification

**Solution**:
Messages should appear on the right for sent messages and left for received messages.

### Advanced Debugging

#### Enable Detailed Logging

Add debug prints in key files:

In `lib/services/chat_service.dart`:
```dart
debugPrint('Connecting to: $_wsUrl');
debugPrint('Auth token: $_authToken');
```

#### Mobile App Logs

```bash
flutter logs
```

#### Backend Server Logs

Check the terminal where you ran `npm start` for detailed logs.

## ☁️ Production Deployment

### AWS Deployment Steps

1. **Prepare AWS Instance**:
   - Launch Ubuntu 20.04 EC2 instance
   - Assign Elastic IP: 15.206.75.65
   - Configure security groups to allow ports 22 and 443

2. **Install Dependencies**:
   ```bash
   sudo apt update
   sudo apt install nodejs npm mysql-server
   ```

3. **Configure SSL Certificates**:
   - Obtain SSL certificate for 15.206.75.65
   - Upload to `/home/ubuntu/certs/`
   - Set permissions: `chmod 600 private.key`

4. **Update Environment Variables**:
   ```env
   PORT=443
   USE_HTTPS=true
   SSL_CERT_PATH=/home/ubuntu/certs/falcon.crt
   SSL_KEY_PATH=/home/ubuntu/certs/falcon.key
   ```

5. **Deploy Application**:
   ```bash
   npm install
   npm install -g pm2
   pm2 start index.js --name "falcon-backend" --env production
   pm2 startup
   pm2 save
   ```

6. **Configure Mobile App for Production**:
   Update `lib/services/network_config_service.dart`:
   ```dart
   static String _serverIp = '15.206.75.65';
   static int _serverPort = 443;
   ```

7. **Build Release Version**:
   ```bash
   flutter build apk --release
   # or
   flutter build ios --release
   ```

## 📚 Documentation References

- [HOW_IT_WORKS_LOCAL.md](file:///V:/falcon/HOW_IT_WORKS_LOCAL.md) - How the app works in local development
- [HOW_IT_WORKS_AWS.md](file:///V:/falcon/HOW_IT_WORKS_AWS.md) - How the app works in production
- [LOCAL_VS_AWS_COMPARISON.md](file:///V:/falcon/LOCAL_VS_AWS_COMPARISON.md) - Differences between environments
- [TROUBLESHOOTING_NETWORK.md](file:///V:/falcon/TROUBLESHOOTING_NETWORK.md) - Network issue resolution
- [LOCAL_TESTING_GUIDE.md](file:///V:/falcon/LOCAL_TESTING_GUIDE.md) - Testing procedures
- [VERIFY_ALL_FEATURES.md](file:///V:/falcon/VERIFY_ALL_FEATURES.md) - Feature verification
- [DEPLOYMENT_CHECKLIST.md](file:///V:/falcon/DEPLOYMENT_CHECKLIST.md) - Production deployment checklist

## 🎯 Success Criteria

When everything is working properly, you should be able to:

1. ✅ Start the backend server without errors
2. ✅ Access health endpoint locally and via IP
3. ✅ Register and login with biometric authentication
4. ✅ Send and receive messages with proper alignment
5. ✅ Forward messages to other users
6. ✅ Permanently delete messages
7. ✅ Share files that are viewable but not downloadable
8. ✅ Use security features like screenshot protection
9. ✅ Connect via VPN with split tunneling
10. ✅ Experience smooth UI/UX with animations

## 🛠️ Common Build Issues

### File Locking Issue

If you encounter this error:
```
java.nio.file.FileSystemException: ... The process cannot access the file because it is being used by another process
```

Run the `fix_build.bat` script in the project root directory, or follow these steps:

1. Close all terminals and IDEs
2. Run `flutter clean`
3. Run `flutter pub get`
4. Navigate to the `android` directory and run `gradlew --stop`
5. Try building again

### Font Tree-Shaking Warning

The warning about MaterialIcons tree-shaking is normal and actually beneficial as it reduces app size. You can disable it with `--no-tree-shake-icons` if needed.

## 📞 Support

If you encounter persistent issues:

1. Provide detailed error messages
2. Include output from diagnostic commands
3. Share your network configuration
4. Mention your system specifications

This complete setup guide should help you successfully deploy and run the Falcon Chat application in both local development and production environments.