# Falcon Chat App - Complete Setup Guide

## 🚀 Quick Start Instructions

### Prerequisites
1. **Android Studio** with Android SDK installed
2. **Flutter SDK** (already working as confirmed by `flutter doctor`)
3. **MySQL Server** installed and running
4. **Node.js** and npm installed

### 📊 Database Setup

#### Option 1: Using MySQL Command Line
```bash
# Open MySQL command line
mysql -u root -p

# Run the setup script
source v:\falcon\database_setup.sql
```

#### Option 2: Using MySQL Workbench
1. Open MySQL Workbench
2. Connect to your local MySQL server
3. Open the file `v:\falcon\database_setup.sql`
4. Execute the script

#### Option 3: Manual Setup
```sql
CREATE DATABASE falcon_chat;
CREATE USER 'kt'@'localhost' IDENTIFIED BY 'thekt';
GRANT ALL PRIVILEGES ON falcon_chat.* TO 'kt'@'localhost';
FLUSH PRIVILEGES;
```

### 🖥️ Backend Server Setup

1. **Install dependencies** (already done):
```bash
cd v:\falcon\backend
npm install
```

2. **Start the backend server**:
```bash
cd v:\falcon\backend
npm start
```
The server will run on `http://localhost:3001`

### 📱 Android App Setup

1. **Open Android Studio**
2. **Open the project**: File → Open → Select `v:\falcon`
3. **Wait for Gradle sync** to complete
4. **Create/Start an Android emulator** or connect a physical device

### 🏃‍♂️ Running the App

#### Option 1: Using Android Studio
1. Click the "Run" button (green play icon)
2. Select your emulator/device
3. Wait for the app to build and install

#### Option 2: Using Flutter Command Line
```bash
cd v:\falcon
flutter run
```

#### Option 3: Install the APK directly
The debug APK has been built at: `v:\falcon\build\app\outputs\flutter-apk\app-debug.apk`
You can install this directly on any Android device.

### 🔧 Configuration

#### Backend Configuration
The backend is configured to use:
- **Database**: `falcon_chat`
- **Username**: `kt`
- **Password**: `thekt`
- **Host**: `localhost`
- **Port**: `3306`

#### App Configuration
The Flutter app is configured to connect to:
- **Backend URL**: `http://172.20.10.2:3001/api` (automatically works on same network)
- **WebSocket**: `ws://172.20.10.2:3001`

### 🌐 Hotspot Network Testing

When testing with multiple phones connected to the same hotspot:

1. **Laptop** (server) connected to **Phone 1's hotspot**
2. **Phone 2** connected to **Phone 1's hotspot** (same network)
3. **Phone 3** connected to **Phone 1's hotspot** (same network)

✅ **The app works across devices on the same network!**

To test with your specific setup:
1. Ensure your laptop's IP is `172.20.10.2` when connected to the hotspot
2. Run `add_firewall_rule.bat` as administrator to allow connections on port 3001
3. Start the server with `start_server_with_firewall.bat`
4. Install and run the app on your test phones

### 🔒 VPN and Network Considerations

When using VPN with local development:

- **VPN ON**: Works with local development thanks to proper network handling
- **VPN OFF**: Users list and chat work correctly
- **Production**: VPN works normally with remote servers

The app now handles VPN and local development seamlessly without complex split tunneling.

See `VPN_LOCAL_DEVELOPMENT_FIX.md` for detailed technical information.

### 🚀 Production Deployment

For production deployment, please refer to the detailed guide in [DEPLOYMENT.md](DEPLOYMENT.md).

Key steps include:
1. **Configure production server** with proper domain and SSL certificates
2. **Update mobile app** with production server URLs
3. **Set up reverse proxy** (Nginx recommended)
4. **Configure database** for production use
5. **Build production APK** with proper signing

### 🎯 Testing the App

1. **Start the backend server** first
2. **Launch the app** on your Android emulator
3. **Register a new user**:
   - Enter name, mobile number, and password
   - Scan the QR code with Google Authenticator
   - Complete registration
4. **Login**:
   - Enter mobile, password, and TOTP code from Google Authenticator
   - For testing, you can use demo codes: 123456, 000000, or 111111
   - VPN should automatically connect
5. **Test chat**:
   - Search for other users
   - Start conversations
   - Send messages (end-to-end encrypted)

### 🔒 Security Features

✅ **TOTP Authentication** with Google Authenticator
✅ **End-to-End Encryption** with AES-256-GCM
✅ **VPN Tunneling** with WireGuard protocol
✅ **Secure Database** with encrypted passwords
✅ **JWT Token** authentication
✅ **Audit Logging** for security monitoring

### 📁 Project Structure

```
v:\falcon\
├── lib/                    # Flutter Dart code
│   ├── screens/           # UI screens
│   ├── services/          # API and business logic
│   ├── widgets/          # Reusable UI components
│   └── theme/            # App theming
├── android/              # Android-specific code
│   └── app/src/main/java/ # Java VPN implementation
├── backend/              # Node.js backend server
└── database_setup.sql    # MySQL database setup
```

### 🛠️ Troubleshooting

#### Database Connection Issues
- Ensure MySQL server is running
- Verify user 'kt' has correct permissions
- Check if port 3306 is accessible

#### App Build Issues
- Run `flutter clean` then `flutter pub get`
- Ensure Android SDK is properly configured
- Check Android emulator is running

#### VPN Permission Issues
- Grant VPN permission when prompted
- Ensure the app has necessary Android permissions

#### Backend Connection Issues
- Verify backend server is running on port 3001
- Check firewall settings for localhost access
- Ensure the server is bound to 0.0.0.0 (accepts remote connections)
- Run `add_firewall_rule.bat` as administrator to allow connections on port 3001

#### Search Bar Text Visibility Issues
- Fixed in latest version with proper text color styling
- Search bar text is now clearly visible against the white background

#### Network Issues (Registered Users Not Showing)
- Run `add_firewall_rule.bat` as administrator
- Ensure all devices are on the same network
- Verify laptop IP is 172.20.10.2
- Restart the server after adding firewall rule

#### VPN Interference Issues
- The app now handles VPN and local development seamlessly
- If issues persist, temporarily disable VPN to diagnose
- See `VPN_LOCAL_DEVELOPMENT_FIX.md` for technical details

### 📞 Support

If you encounter any issues:
1. Check the terminal output for error messages
2. Verify all services (MySQL, backend) are running
3. Ensure Android emulator has network connectivity
4. Check Android Studio's logcat for detailed error logs

## 🎉 You're Ready!

Your Falcon Chat app is now fully configured with:
- ✅ Secure TOTP authentication
- ✅ End-to-end encrypted messaging
- ✅ VPN protection with local development support
- ✅ MySQL database backend
- ✅ Beautiful animated UI
- ✅ Remote access capability (no network dependency)
- ✅ Fixed search bar text visibility
- ✅ Enhanced error handling and timeouts
- ✅ Production deployment ready
- ✅ Hotspot network testing support
- ✅ VPN and chat screen issue fixes
- ✅ Simplified VPN/local development handling

Start the backend server, launch the app, and enjoy secure chatting with VPN active! 🚀