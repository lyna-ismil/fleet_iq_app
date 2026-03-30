import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({Key? key, required this.password})
      : super(key: key);

  // Improved Password Strength Logic
  String _getPasswordStrength() {
    if (password.isEmpty) return 'Enter Password';
    if (password.length < 6) return 'Weak';
    if (RegExp(r'^(?=.*[A-Z])(?=.*[0-9])').hasMatch(password) &&
        password.length >= 8) {
      return 'Strong';
    }
    return 'Medium';
  }

  // Improved Strength Color Logic
  Color _getPasswordStrengthColor() {
    switch (_getPasswordStrength()) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Convert Strength to Progress Value
  double _getStrengthValue() {
    switch (_getPasswordStrength()) {
      case 'Weak':
        return 0.3;
      case 'Medium':
        return 0.6;
      case 'Strong':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // Strength Bar UI
  Widget _buildStrengthBar() {
    double strength = _getStrengthValue();
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            height: 5,
            decoration: BoxDecoration(
              color: index < (strength * 4)
                  ? _getPasswordStrengthColor()
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Password Strength: ",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              _getPasswordStrength(),
              style: TextStyle(
                color: _getPasswordStrengthColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        _buildStrengthBar(), //Added strength bar here
      ],
    );
  }
}
