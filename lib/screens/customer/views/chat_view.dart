import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ChatView extends StatelessWidget {
  final UserModel user;
  final List<AgentProfileModel> agents;
  final Function(AgentProfileModel) onOpenChat;

  const ChatView({
    super.key,
    required this.user,
    required this.agents,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chat with Travel Agents', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        agents.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No active agents available', style: TextStyle(color: Colors.white38))))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: agents.length,
                itemBuilder: (context, idx) {
                  final ag = agents[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00D4FF),
                        child: Text(ag.companyName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(ag.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(ag.location, style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00D4FF)),
                      onTap: () => onOpenChat(ag),
                    ),
                  );
                },
              )
      ],
    );
  }
}
