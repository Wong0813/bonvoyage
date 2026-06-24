import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/chat_service.dart';
import '../../../utils/app_theme.dart';

class ChatPage extends StatefulWidget {
  final UserModel user;
  final int agentUserId;
  final String agentName;
  const ChatPage({super.key, required this.user, required this.agentUserId, required this.agentName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtrl = TextEditingController();
  List<ChatMessageModel> _messages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ChatService.instance.getConversation(widget.user.id, widget.agentUserId);
      if (mounted) {
        setState(() {
          _messages = msgs;
        });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    try {
      await ChatService.instance.sendMessage(
        senderId: widget.user.id,
        receiverId: widget.agentUserId,
        message: _msgCtrl.text.trim(),
      );
      _msgCtrl.clear();
      _loadMessages();
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E38),
        title: Text(widget.agentName, style: const TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final m = _messages[idx];
                final isMe = m.senderId == widget.user.id;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF00D4FF) : const Color(0xFF1E1E38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.message, style: TextStyle(color: isMe ? Colors.black : Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E1E38),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF00D4FF)), onPressed: _send),
              ],
            ),
          )
        ],
      ),
    );
  }
}
