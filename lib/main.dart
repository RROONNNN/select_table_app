import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WebSocketPage(),
    );
  }
}

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key});

  @override
  State<WebSocketPage> createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  late WebSocketChannel channel;
  bool isConnected = false;
  String? currentStatus;
  final TextEditingController _ipController = TextEditingController();
  String serverIP = "192.168.1.32";

  @override
  void initState() {
    super.initState();
    _ipController.text = serverIP;
    // Không tự động kết nối ngay, để người dùng nhập IP trước
  }

  void _connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://$serverIP:5000/'));

      // Send identification message
      channel.sink.add('flutter');
      setState(() {
        isConnected = true;
      });

      channel.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> jsonResponse = json.decode(message);

            // Handle success response
            if (jsonResponse.containsKey('status') &&
                jsonResponse['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gửi thành công: ${jsonResponse['keyword']}'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            // Handle car status response
            if (jsonResponse.containsKey('car_status')) {
              setState(() {
                currentStatus = jsonResponse['car_status'];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Trạng thái xe: ${jsonResponse['car_status']}'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          } catch (e) {
            print('Error parsing JSON: $e');
          }
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi kết nối: $error'),
              backgroundColor: Colors.red,
            ),
          );
          isConnected = false;
        },
        onDone: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mất kết nối với server'),
              backgroundColor: Colors.red,
            ),
          );
          isConnected = false;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
      isConnected = false;
    }
  }

  void _sendMessage(String message) {
    if (isConnected) {
      channel.sink.add(message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có kết nối với server'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      channel.sink.close();
    }
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (currentStatus != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Trạng thái xe: $currentStatus',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP Server',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      serverIP = _ipController.text;
                    });
                    _connectWebSocket();
                  },
                  child: Text(isConnected ? 'Đã kết nối' : 'Kết nối'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton('A1'),
                      const SizedBox(width: 20),
                      _buildButton('A2'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton('B1'),
                      const SizedBox(width: 20),
                      _buildButton('B2'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text) {
    return ElevatedButton(
      onPressed: () => _sendMessage(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 20)),
    );
  }
}
