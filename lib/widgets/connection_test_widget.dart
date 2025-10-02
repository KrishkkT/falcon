import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/network_config_service.dart';

class ConnectionTestWidget extends StatefulWidget {
  const ConnectionTestWidget({super.key});

  @override
  State<ConnectionTestWidget> createState() => _ConnectionTestWidgetState();
}

class _ConnectionTestWidgetState extends State<ConnectionTestWidget> {
  bool _isConnected = false;
  String _connectionStatus = 'Not connected';
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testConnection();
    });
  }

  Future<void> _testConnection() async {
    try {
      setState(() {
        _connectionStatus = 'Testing connection...';
      });

      // Get WebSocket URL
      final wsUrl = NetworkConfigService.getWebSocketUrl();
      print('Testing WebSocket connection to: $wsUrl');

      // Create a simple test connection
      _socket = IO.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
      });

      _socket!.onConnect((_) {
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected successfully!';
        });
        print('✅ WebSocket connected successfully');
      });

      _socket!.onDisconnect((_) {
        setState(() {
          _isConnected = false;
          _connectionStatus = 'Disconnected';
        });
        print('❌ WebSocket disconnected');
      });

      _socket!.onError((error) {
        setState(() {
          _connectionStatus = 'Connection error: $error';
        });
        print('❌ WebSocket error: $error');
      });

      // Try to connect
      _socket!.connect();
      
      // Auto disconnect after 5 seconds for testing
      Future.delayed(const Duration(seconds: 5), () {
        _socket?.disconnect();
        _socket?.dispose();
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Test failed: $e';
      });
      print('❌ Connection test failed: $e');
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'WebSocket Connection Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(_connectionStatus),
            const SizedBox(height: 16),
            Icon(
              _isConnected ? Icons.check_circle : Icons.error,
              color: _isConnected ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}