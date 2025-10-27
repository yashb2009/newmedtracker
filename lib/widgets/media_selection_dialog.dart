import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class MediaSelectionDialog extends StatefulWidget {
  const MediaSelectionDialog({super.key});

  @override
  State<MediaSelectionDialog> createState() => _MediaSelectionDialogState();
}

class _MediaSelectionDialogState extends State<MediaSelectionDialog> {
  bool _doNotAskAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Choose Capture Method',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How would you like to capture your medication information?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Image option
          InkWell(
            onTap: () => _handleSelection(PreferencesService.mediaTypeImage),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo_camera, size: 32, color: Colors.blue.shade700),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Take a photo or upload from gallery',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Video option (recommended)
          InkWell(
            onTap: () => _handleSelection(PreferencesService.mediaTypeVideo),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green.shade50,
              ),
              child: Row(
                children: [
                  Icon(Icons.videocam, size: 32, color: Colors.green.shade700),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Video',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Chip(
                              label: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Live camera stream with OCR',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Do not ask me again checkbox
          Row(
            children: [
              Checkbox(
                value: _doNotAskAgain,
                onChanged: (value) {
                  setState(() {
                    _doNotAskAgain = value ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'Do not ask me again',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _handleSelection(String mediaType) async {
    // Save preferences if "Do not ask me again" is checked
    if (_doNotAskAgain) {
      final prefs = await PreferencesService.getInstance();
      await prefs.setDoNotAsk(true);
      await prefs.setMediaType(mediaType);
    }

    // Return the selected media type
    if (mounted) {
      Navigator.of(context).pop(mediaType);
    }
  }
}
