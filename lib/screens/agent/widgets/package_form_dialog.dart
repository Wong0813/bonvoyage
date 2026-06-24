import 'dart:convert' show base64Encode;
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/travel_package_service.dart';
import '../../../utils/app_theme.dart';

class PackageFormDialog extends StatefulWidget {
  final TravelPackageModel? pkg;
  final AgentProfileModel profile;
  final VoidCallback onSaved;

  const PackageFormDialog({
    super.key,
    this.pkg,
    required this.profile,
    required this.onSaved,
  });

  @override
  State<PackageFormDialog> createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<PackageFormDialog> {
  late final TextEditingController _destCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _attCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _promoCtrl;

  late String _tripType;
  late String _category;
  late DateTime _travelDate;
  String? _schedulePath;
  final List<Map<String, String>> _imagePaths = [];
  final Set<int> _deletedImageIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _destCtrl = TextEditingController(text: widget.pkg?.destination);
    _descCtrl = TextEditingController(text: widget.pkg?.description);
    _attCtrl = TextEditingController(text: widget.pkg?.attractions);
    _maxCtrl = TextEditingController(text: widget.pkg?.maxPeople.toString() ?? '10');
    _priceCtrl = TextEditingController(text: widget.pkg?.pricePerPerson.toString() ?? '');
    _promoCtrl = TextEditingController(text: widget.pkg?.promoPrice?.toString() ?? '');
    _tripType = widget.pkg?.tripType ?? 'group';
    _category = widget.pkg?.category ?? 'Beach';
    _travelDate = widget.pkg?.travelDate ?? DateTime.now().add(const Duration(days: 30));
    _schedulePath = widget.pkg?.scheduleFilePath;
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    _descCtrl.dispose();
    _attCtrl.dispose();
    _maxCtrl.dispose();
    _priceCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (_destCtrl.text.isEmpty || price <= 0) {
      showAppSnackBar(context, 'Please fill in a destination and valid price.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.pkg == null) {
        await TravelPackageService.instance.createPackage(
          agentProfileId: widget.profile.id,
          destination: _destCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          attractions: _attCtrl.text.trim(),
          tripType: _tripType,
          maxPeople: int.tryParse(_maxCtrl.text) ?? 10,
          travelDate: _travelDate,
          pricePerPerson: price,
          promoPrice: double.tryParse(_promoCtrl.text),
          promoEnd: _promoCtrl.text.isNotEmpty ? _travelDate : null,
          scheduleFilePath: _schedulePath,
          images: _imagePaths,
          category: _category,
        );
      } else {
        await TravelPackageService.instance.updatePackage(
          id: widget.pkg!.id,
          agentProfileId: widget.profile.id,
          destination: _destCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          attractions: _attCtrl.text.trim(),
          tripType: _tripType,
          maxPeople: int.tryParse(_maxCtrl.text),
          travelDate: _travelDate,
          pricePerPerson: price,
          promoPrice: double.tryParse(_promoCtrl.text),
          promoEnd: _promoCtrl.text.isNotEmpty ? _travelDate : null,
          scheduleFilePath: _schedulePath,
          category: _category,
        );
        if (_imagePaths.isNotEmpty) {
          await TravelPackageService.instance.addPackageImages(widget.pkg!.id, _imagePaths);
        }
        for (final imageId in _deletedImageIds) {
          await TravelPackageService.instance.deletePackageImage(imageId);
        }
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppSnackBar(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16162A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      title: Text(
        widget.pkg == null ? 'Add Travel Package' : 'Edit Package Details',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _destCtrl,
                decoration: AppTheme.input('Destination (e.g. Bali Island)'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: AppTheme.input('Package Description'),
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _attCtrl,
                decoration: AppTheme.input('Attractions (one per line)'),
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tripType,
                dropdownColor: const Color(0xFF16162A),
                decoration: AppTheme.input('Trip Type'),
                items: const [
                  DropdownMenuItem(value: 'solo', child: Text('Solo Travel', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'group', child: Text('Group Tour', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setState(() => _tripType = v ?? 'group'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: const Color(0xFF16162A),
                decoration: AppTheme.input('Category *'),
                items: const [
                  DropdownMenuItem(value: 'Beach', child: Text('Beach 🏖️', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Mountains', child: Text('Mountains ⛰️', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'City', child: Text('City 🏙️', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Culture', child: Text('Culture 🏛️', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'Adventure', child: Text('Adventure 🧗', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Beach'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxCtrl,
                decoration: AppTheme.input('Max Group Size'),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceCtrl,
                decoration: AppTheme.input('Price Per Person (RM)'),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promoCtrl,
                decoration: AppTheme.input('Promo Discount Price (RM, optional)'),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Travel Date: ${_travelDate.year}-${_travelDate.month.toString().padLeft(2, '0')}-${_travelDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF00D4FF)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _travelDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (d != null) setState(() => _travelDate = d);
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Package Images', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (widget.pkg != null)
                      ...widget.pkg!.images.where((img) => !_deletedImageIds.contains(img.id)).map((img) {
                        return Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppTheme.imageFromPath(
                                  img.imagePath,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  cacheWidth: 150,
                                  errorWidget: Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 24),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _deletedImageIds.add(img.id);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, size: 12, color: Colors.redAccent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ..._imagePaths.map((img) {
                      final path = img['path']!;
                      return Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AppTheme.imageFromPath(
                                path,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                cacheWidth: 150,
                                errorWidget: Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 24),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _imagePaths.remove(img);
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, size: 12, color: Colors.redAccent),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    InkWell(
                      onTap: () async {
                        final r = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
                        if (r != null) {
                          for (final f in r.files) {
                            String? dataUrl;
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
                              _imagePaths.add({'path': dataUrl, 'type': 'attraction'});
                            }
                          }
                          setState(() {});
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Center(
                          child: Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF00D4FF), size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final r = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
                  );
                  if (r != null && r.files.single.path != null) {
                    setState(() => _schedulePath = r.files.single.path);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.schedule_rounded, size: 16),
                label: const Text('Attach Itinerary Document'),
              ),
              if (_schedulePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Attached Doc: ${_schedulePath!.split('/').last.split('\\').last}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: Colors.black,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('Save Package'),
        ),
      ],
    );
  }
}
