import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final UserModel currentUser;
  final int otherUserId;
  final String title;
  const ChatPage({super.key, required this.currentUser, required this.otherUserId, required this.title});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtrl = TextEditingController();
  List<ChatMessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs = await ChatService.instance.getConversation(widget.currentUser.id, widget.otherUserId);
      if (mounted) {
        setState(() => _messages = msgs);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m.senderId == widget.currentUser.id;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF00D4FF) : const Color(0xFF16162A),
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      m.message,
                      style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 13, fontWeight: isMe ? FontWeight.w600 : FontWeight.normal),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF111126),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMsg(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMsg,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF00D4FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMsg() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    try {
      await ChatService.instance.sendMessage(
        senderId: widget.currentUser.id,
        receiverId: widget.otherUserId,
        message: _msgCtrl.text.trim(),
      );
      _msgCtrl.clear();
      _load();
    } catch (_) {}
  }
}
