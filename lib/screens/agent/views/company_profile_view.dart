import 'dart:convert' show base64Encode;
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../../models/models.dart';
import '../../../services/agent_profile_service.dart';
import '../../../utils/app_theme.dart';

class CompanyProfileView extends StatefulWidget {
  final AgentProfileModel profile;
  final VoidCallback onLoad;

  const CompanyProfileView({
    super.key,
    required this.profile,
    required this.onLoad,
  });

  @override
  State<CompanyProfileView> createState() => _CompanyProfileViewState();
}

class _CompanyProfileViewState extends State<CompanyProfileView> {
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _fbCtrl;
  late final TextEditingController _igCtrl;
  late final TextEditingController _webCtrl;
  String? _logoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _companyNameCtrl = TextEditingController(text: widget.profile.companyName);
    _phoneCtrl = TextEditingController(text: widget.profile.phone);
    _locationCtrl = TextEditingController(text: widget.profile.location);
    _fbCtrl = TextEditingController(text: widget.profile.socialFacebook ?? '');
    _igCtrl = TextEditingController(text: widget.profile.socialInstagram ?? '');
    _webCtrl = TextEditingController(text: widget.profile.socialWebsite ?? '');
    _logoPath = widget.profile.logoPath;
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _fbCtrl.dispose();
    _igCtrl.dispose();
    _webCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Edit Company Profile Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text('Agent Identifier: ${widget.profile.agentId}', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.bold)),
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
              if (_logoPath != null && AppTheme.imageProviderFromPath(_logoPath!) != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00D4FF), width: 1.5),
                      image: DecorationImage(
                        image: AppTheme.imageProviderFromPath(_logoPath!)!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () async {
                  final r = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (r != null) {
                    String? dataUrl;
                    final f = r.files.single;
                    if (kIsWeb) {
                      if (f.bytes != null) {
                        final base64Data = base64Encode(f.bytes!);
                        dataUrl = 'data:image/png;base64,$base64Data';
                      }
                    } else {
                      if (f.path != null) {
                        try {
                          final file = File(f.path!);
                          if (file.existsSync()) {
                            final bytes = file.readAsBytesSync();
                            final base64Data = base64Encode(bytes);
                            dataUrl = 'data:image/png;base64,$base64Data';
                          }
                        } catch (e) {
                          debugPrint('Error reading file for base64: $e');
                        }
                      }
                    }
                    if (dataUrl != null) {
                      setState(() => _logoPath = dataUrl);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Upload Business Logo'),
              ),
              const SizedBox(height: 20),
              TextField(controller: _companyNameCtrl, decoration: AppTheme.input('Registered Company Name'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, decoration: AppTheme.input('Corporate Contact Phone'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(controller: _locationCtrl, decoration: AppTheme.input('Office Business Address'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(controller: _fbCtrl, decoration: AppTheme.input('Facebook Business Page Link'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(controller: _igCtrl, decoration: AppTheme.input('Instagram Account Page Link'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              TextField(controller: _webCtrl, decoration: AppTheme.input('Corporate Website URL Link'), style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() => _saving = true);
                        try {
                          await AgentProfileService.instance.updateProfile(
                            agentProfileId: widget.profile.id,
                            companyName: _companyNameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            location: _locationCtrl.text.trim(),
                            logoPath: _logoPath,
                            socialFacebook: _fbCtrl.text.trim(),
                            socialInstagram: _igCtrl.text.trim(),
                            socialWebsite: _webCtrl.text.trim(),
                          );
                          widget.onLoad();
                          if (mounted) showAppSnackBar(context, 'Company profile details updated successfully!');
                        } catch (e) {
                          if (mounted) showAppSnackBar(context, '$e', isError: true);
                        } finally {
                          setState(() => _saving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Company Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
