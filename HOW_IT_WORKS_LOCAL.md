# Falcon Chat - How It Works (Local Development)

This document explains the complete flow of how the Falcon Chat application works when running on your local network with your phone connected to your laptop's hotspot.

## 🏗️ Architecture Overview

The Falcon Chat application follows a client-server architecture:

```
[Mobile Device] ←→ [Network] ←→ [Laptop Backend Server]
     ↑                                ↑
Flutter App                      Node.js + MySQL
```

## 📱 Mobile App (Flutter/Dart)

### Entry Point: `lib/main.dart`
This is the starting point of the application:
- Initializes all services (authentication, chat, VPN, etc.)
- Sets up the main app widget with proper providers
- Handles splash screen and initial navigation
- Configures network settings for local development

### Network Configuration: `lib/services/network_config_service.dart`
This service manages all network-related settings:
- Sets the backend IP to `172.20.10.2:3001` for local development
- Provides base API URL: `http://172.20.10.2:3001/api`
- Provides WebSocket URL: `ws://172.20.10.2:3001`
- Handles VPN-aware connection logic

### Authentication Flow

1. **Registration**: `lib/screens/registration_screen.dart`
   - User enters mobile number, name, and password
   - Password is salted and hashed using bcrypt
   - TOTP secret is generated for 2FA
   - Data sent to `/api/register` endpoint
   - Backend creates user in MySQL database

2. **Login**: `lib/screens/login_screen.dart`
   - User enters mobile, password, and TOTP code
   - Credentials sent to `/api/login` endpoint
   - Backend validates credentials and TOTP code
   - JWT token generated and returned
   - Token stored securely on device

3. **Biometric Auth**: `lib/services/biometric_service.dart`
   - Checks if device supports biometrics
   - Attempts biometric authentication first
   - Falls back to PIN/pattern/password if needed
   - On success, uses stored JWT token for automatic login

### Chat Functionality

1. **Message Sending**: `lib/services/chat_service.dart`
   - Messages first sent via WebSocket for real-time delivery
   - If WebSocket fails, falls back to HTTP POST
   - Messages encrypted before sending (see encryption section)
   - Temporary message shown in UI immediately

2. **Message Display**: `lib/screens/chat_screen.dart` + `lib/widgets/chat_bubble.dart`
   - Fetches conversation history from `/api/chats/{userId}/messages`
   - Displays messages with proper alignment (sent=right, received=left)
   - Shows delivery status indicators
   - Handles message forwarding and deletion

3. **Real-time Updates**: WebSocket connection
   - Maintains persistent connection to backend
   - Receives new messages instantly
   - Updates UI in real-time without polling

## 🔧 Backend Server (Node.js)

### Entry Point: `backend/index.js`
- Sets up Express.js HTTP server on port 3001
- Configures WebSocket (Socket.IO) for real-time communication
- Initializes database connection
- Removes demo users on startup
- Starts server listening on all interfaces (0.0.0.0)

### Database: MySQL
- **Users Table**: Stores user accounts, passwords (hashed), TOTP secrets
- **Messages Table**: Stores encrypted messages with metadata
- **Sessions Table**: Tracks active user sessions
- **Audit Logs Table**: Records security events

### API Endpoints

1. **Authentication**:
   - `POST /api/register` - Create new user account
   - `POST /api/login` - Authenticate user and generate JWT
   - `GET /api/validate-session` - Check if session is still valid

2. **Messaging**:
   - `GET /api/chats/{userId}/messages` - Get message history
   - `POST /api/chats/{userId}/messages` - Send message (HTTP fallback)
   - `GET /api/conversations` - Get list of contacts

3. **User Management**:
   - `GET /api/users/search` - Search for users by name/mobile

### Security Features

1. **Message Encryption**: `backend/index.js` EncryptionService
   - AES-256-GCM encryption for all messages
   - Unique encryption key from environment variables
   - Each message encrypted with random IV and auth tag
   - Message hash for integrity verification

2. **Authentication**: JWT tokens with 24-hour expiry
   - Tokens stored in secure HTTP-only cookies
   - Session validation against database
   - TOTP for two-factor authentication

3. **Network Security**:
   - Rate limiting to prevent abuse
   - Helmet.js for HTTP security headers
   - CORS configuration for mobile app access
   - Input validation and sanitization

## 🔐 Message Flow & Encryption

### 1. Sending a Message

```
[Mobile App]                    [Backend Server]                 [Database]
     |                                |                                |
     | Message text                  |                                |
     |------------------------------->|                                |
     |                                |                                |
     |                                | Generate random IV            |
     |                                | Encrypt with AES-256-GCM     |
     |                                | Create auth tag              |
     |                                |------------------------------->|
     |                                |                                | Store encrypted:
     |                                |                                | - Encrypted content
     |                                |                                | - IV
     |                                |                                | - Auth tag
     |                                |                                | - Message hash
     |                                | Send to recipient via WS     |
     |                                | Or store for later delivery  |
     |<-------------------------------|                                |
     | Show delivery status           |                                |
```

### 2. Receiving a Message

```
[Backend Server]                 [Mobile App]
       |                              |
       | WebSocket message event     |
       |----------------------------->|
       |                              |
       |                              | Decrypt with AES-256-GCM
       |                              | Verify auth tag
       |                              | Display in chat bubble
       |                              | Update UI
```

## 🌐 Network Flow

### Local Development Connection

1. **Your Phone's Network Journey**:
   ```
   Phone (172.20.10.3) → Hotspot → Laptop (172.20.10.2:3001)
   ```

2. **API Request Flow**:
   ```
   Mobile App                        Backend Server
        |                                 |
        | GET http://172.20.10.2:3001/api/health
        |-------------------------------->|
        |                                 |
        |         HTTP 200 OK             |
        |<--------------------------------|
   ```

3. **WebSocket Connection Flow**:
   ```
   Mobile App                        Backend Server
        |                                 |
        | WebSocket ws://172.20.10.2:3001
        |-------------------------------->|
        |                                 |
        |         Connection ACK          |
        |<--------------------------------|
        |                                 |
        |         Auth with JWT           |
        |-------------------------------->|
        |                                 |
        |         Auth Success            |
        |<--------------------------------|
   ```

## 🔧 Troubleshooting Common Issues

### "Network Connection Failed" Error

This typically happens when:
1. Phone isn't on the same network as laptop
2. Firewall blocking port 3001
3. Backend server not running or bound to wrong interface
4. Incorrect IP address in app configuration

### Verification Steps

1. **Check Backend Server**:
   ```bash
   # On laptop, verify server is running
   curl http://localhost:3001/api/health
   ```

2. **Check Network Configuration**:
   ```bash
   # On laptop, find correct IP
   ipconfig
   ```

3. **Test from Phone**:
   - Use mobile browser to visit `http://172.20.10.2:3001/api/health`
   - Should see JSON response with "status": "ok"

4. **Check Firewall**:
   - Windows Defender Firewall → Allow Node.js through firewall
   - Ensure port 3001 is not blocked

## 📊 Data Flow Summary

| Component | File | Function |
|-----------|------|----------|
| App Entry | `lib/main.dart` | App initialization and routing |
| Network | `lib/services/network_config_service.dart` | Manage backend connection settings |
| Auth UI | `lib/screens/login_screen.dart`, `lib/screens/registration_screen.dart` | User authentication interface |
| Auth Logic | `lib/services/auth_service.dart` | Handle authentication requests |
| Biometric | `lib/services/biometric_service.dart` | Device biometric integration |
| Chat UI | `lib/screens/chat_screen.dart` | Main chat interface |
| Messages | `lib/widgets/chat_bubble.dart` | Individual message display |
| Chat Logic | `lib/services/chat_service.dart` | Message sending/receiving |
| Backend | `backend/index.js` | Server logic and API endpoints |
| Database | `backend/database.js` | MySQL connection and setup |
| Security | `backend/index.js` (EncryptionService) | Message encryption/decryption |

## 🔒 Security Implementation

1. **At Rest**: Messages stored encrypted in database
2. **In Transit**: HTTPS/WSS encryption (HTTP/WS for local dev)
3. **Authentication**: JWT tokens + TOTP + Biometric
4. **Session Management**: Secure token storage and validation
5. **Access Control**: Role-based permissions
6. **Audit Trail**: All actions logged for security review

This local development setup allows you to test all features of the Falcon Chat application using your phone connected to your laptop's hotspot.