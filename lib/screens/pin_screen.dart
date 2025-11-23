import 'package:flutter/material.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const String _correctPin = "666666";
  String _enteredPin = "";

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
      });

      // Auto-validate when 6 digits are entered
      if (_enteredPin.length == 6) {
        _validatePin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _validatePin() {
    if (_enteredPin == _correctPin) {
      // PIN is correct, navigate to home screen
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // PIN is incorrect, show alert and reset
      _showIncorrectPinAlert();
      setState(() {
        _enteredPin = "";
      });
    }
  }

  void _showIncorrectPinAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incorrect PIN'),
        content: const Text('The code is incorrect. Please enter the correct PIN code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length ? Colors.blue : Colors.grey[300],
            border: Border.all(
              color: index < _enteredPin.length ? Colors.blue : Colors.grey[400]!,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => _onNumberPressed(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            minimumSize: const Size(70, 70),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: _onDeletePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            minimumSize: const Size(70, 70),
          ),
          child: const Icon(
            Icons.backspace_outlined,
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // App icon or logo space
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              const Text(
                'Please enter your 6-digit PIN to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // PIN dots
              _buildPinDots(),
              
              const SizedBox(height: 48),
              
              // Numeric keypad
              Column(
                children: [
                  // Row 1: 1, 2, 3
                  Row(
                    children: [
                      _buildNumberButton('1'),
                      _buildNumberButton('2'),
                      _buildNumberButton('3'),
                    ],
                  ),
                  // Row 2: 4, 5, 6
                  Row(
                    children: [
                      _buildNumberButton('4'),
                      _buildNumberButton('5'),
                      _buildNumberButton('6'),
                    ],
                  ),
                  // Row 3: 7, 8, 9
                  Row(
                    children: [
                      _buildNumberButton('7'),
                      _buildNumberButton('8'),
                      _buildNumberButton('9'),
                    ],
                  ),
                  // Row 4: empty, 0, delete
                  Row(
                    children: [
                      const Expanded(child: SizedBox()), // Empty space
                      _buildNumberButton('0'),
                      _buildDeleteButton(),
                    ],
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
} 