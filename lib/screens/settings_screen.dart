import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PreferencesService _prefs;
  String _mediaType = PreferencesService.mediaTypeVideo;
  bool _doNotAsk = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await PreferencesService.getInstance();
    setState(() {
      _mediaType = _prefs.getMediaType();
      _doNotAsk = _prefs.getDoNotAsk();
      _isLoading = false;
    });
  }

  Future<void> _updateMediaType(String type) async {
    await _prefs.setMediaType(type);
    setState(() {
      _mediaType = type;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default capture method set to ${type == PreferencesService.mediaTypeVideo ? 'Video' : 'Image'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateDoNotAsk(bool value) async {
    await _prefs.setDoNotAsk(value);
    setState(() {
      _doNotAsk = value;
    });
  }

  Future<void> _resetPreferences() async {
    await _prefs.resetPreferences();
    setState(() {
      _mediaType = PreferencesService.mediaTypeVideo;
      _doNotAsk = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences reset to defaults'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Capture Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Video option
                RadioListTile<String>(
                  title: const Row(
                    children: [
                      Icon(Icons.videocam, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Video (Recommended)'),
                    ],
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(left: 40.0),
                    child: Text(
                      'Live camera stream with real-time OCR processing',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  value: PreferencesService.mediaTypeVideo,
                  groupValue: _mediaType,
                  onChanged: (value) {
                    if (value != null) {
                      _updateMediaType(value);
                    }
                  },
                ),

                const Divider(),

                // Image option
                RadioListTile<String>(
                  title: const Row(
                    children: [
                      Icon(Icons.photo_camera, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Image'),
                    ],
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(left: 40.0),
                    child: Text(
                      'Take a photo or upload from gallery for OCR',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  value: PreferencesService.mediaTypeImage,
                  groupValue: _mediaType,
                  onChanged: (value) {
                    if (value != null) {
                      _updateMediaType(value);
                    }
                  },
                ),

                const Divider(height: 32),

                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Prompt Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Do not ask again toggle
                SwitchListTile(
                  title: const Text('Skip selection dialog'),
                  subtitle: const Text(
                    'Always use the default capture method without asking',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _doNotAsk,
                  onChanged: _updateDoNotAsk,
                ),

                const Divider(height: 32),

                // Reset preferences button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset Preferences'),
                          content: const Text(
                            'This will reset all settings to their default values. Are you sure?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _resetPreferences();
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset to Defaults'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'About Capture Methods',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Video Mode: Provides real-time text recognition as you move the camera. Best for capturing multiple medications quickly.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Image Mode: Take a single photo or select from gallery. Best for clear, static images of medication labels.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
