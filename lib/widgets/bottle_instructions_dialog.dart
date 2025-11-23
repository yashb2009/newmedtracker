import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class BottleInstructionsDialog extends StatefulWidget {
  const BottleInstructionsDialog({super.key});

  @override
  State<BottleInstructionsDialog> createState() => _BottleInstructionsDialogState();
}

class _BottleInstructionsDialogState extends State<BottleInstructionsDialog> {
  bool _doNotShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Bottle Scanning Instructions',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Position the bottle in the middle of the frame. Click the start button and rotate the bottle without moving the phone. Click the stop button when you have reached the end of the label.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _doNotShowAgain,
                  onChanged: (value) {
                    setState(() {
                      _doNotShowAgain = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'Do not show again',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // Save preference if "Do not show again" is checked
            if (_doNotShowAgain) {
              final prefs = await PreferencesService.getInstance();
              await prefs.setDoNotShowBottleInstructions(true);
            }

            // Return true to indicate user wants to proceed
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Got it',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
