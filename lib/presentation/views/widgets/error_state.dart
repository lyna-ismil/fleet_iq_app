import 'package:flutter/material.dart';
import '../../../constants/theme.dart';

/// A reusable error state widget with icon, message, and retry button.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const ErrorState({
    Key? key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.danger, size: 48),
            ),
            SizedBox(height: 24),
            Text(
              "Something went wrong",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text("Retry"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
