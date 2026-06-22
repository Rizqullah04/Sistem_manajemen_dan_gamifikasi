import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/core/providers/app_providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _receiverController = TextEditingController();
  var _isLoading = true;
  var _errorMessage = '';
  var _items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadChats);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await ref.read(dioProvider).get<Map<String, dynamic>>('/chats');
      final data = response.data?['data'];
      setState(() {
        _items = data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
        _isLoading = false;
      });
    } on DioException catch (error) {
      setState(() {
        _errorMessage = _messageFrom(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _send() async {
    final receiver = _receiverController.text.trim();
    final message = _messageController.text.trim();
    if (receiver.isEmpty || message.isEmpty) return;

    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/chats',
        data: {
          'id_penerima': receiver,
          'pesan': message,
        },
      );
      _messageController.clear();
      await _loadChats();
    } on DioException catch (error) {
      setState(() => _errorMessage = _messageFrom(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _receiverController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID penerima',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadChats,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final sender = item['pengirim'];
                        final receiver = item['penerima'];
                        final senderName = sender is Map ? sender['nama']?.toString() : null;
                        final receiverName = receiver is Map ? receiver['nama']?.toString() : null;
                        return ListTile(
                          leading: CircleAvatar(child: Text(_initial(senderName))),
                          title: Text('${senderName ?? item['id_pengirim']} -> ${receiverName ?? item['id_penerima']}'),
                          subtitle: Text(item['pesan']?.toString() ?? ''),
                          trailing: Text(item['status_baca']?.toString() ?? ''),
                        );
                      },
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _send,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Gagal terhubung ke API chat.';
  }

  String _initial(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return '?';
    return text.substring(0, 1).toUpperCase();
  }
}
