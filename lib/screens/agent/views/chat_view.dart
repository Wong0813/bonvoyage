import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/chat_service.dart';
import 'chat_page.dart';

class ChatView extends StatefulWidget {
  final UserModel user;

  const ChatView({
    super.key,
    required this.user,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await ChatService.instance.getContactsForUser(widget.user.id);
      setState(() {
        _contacts = c;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Customer Conversations Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF00D4FF)), onPressed: _load),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_contacts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text('No active client chats found.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            ),
          )
        else
          ..._contacts.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                    child: Text(
                      c['username'].toString().isNotEmpty ? c['username'].toString()[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(c['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Click to open active conversation log', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        currentUser: widget.user,
                        otherUserId: c['userId'] as int,
                        title: c['username'] as String,
                      ),
                    ),
                  ).then((_) => _load()),
                ),
              )),
      ],
    );
  }
}
