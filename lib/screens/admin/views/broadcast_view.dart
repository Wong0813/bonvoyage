import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../../utils/app_theme.dart';

class BroadcastView extends StatefulWidget {
  const BroadcastView({super.key});

  @override
  State<BroadcastView> createState() => _BroadcastViewState();
}

class _BroadcastViewState extends State<BroadcastView> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _broadcastTarget = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    if (title.isEmpty || msg.isEmpty) {
      showAppSnackBar(context, 'Please fill in title and message', isError: true);
      return;
    }

    setState(() => _sending = true);
    try {
      await NotificationService.instance.broadcast(
        targetRole: _broadcastTarget,
        title: title,
        message: msg,
      );
      _titleCtrl.clear();
      _msgCtrl.clear();
      if (mounted) showAppSnackBar(context, 'Push announcement sent successfully!');
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Broadcast System Announcements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text('Send push system notifications directly to customers and travel companies.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: AppTheme.input('Notice Title (e.g. App Maintenance Alert)'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _msgCtrl,
                decoration: AppTheme.input('Notice Message Body'),
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _broadcastTarget,
                dropdownColor: const Color(0xFF16162A),
                decoration: AppTheme.input('Audience Scope'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users & Agents', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'user', child: Text('All Customers Only', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'agent', child: Text('All Travel Companies Only', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setState(() => _broadcastTarget = v ?? 'all'),
              ),
              const SizedBox(height: 24),
              _sending
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send Broadcast Notice', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
