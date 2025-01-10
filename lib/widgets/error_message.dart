import 'package:flutter/material.dart';
import 'package:rnd_game/app_theme.dart';

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    super.key,
    required String? errorMessage,
  }) : _errorMessage = errorMessage;

  final String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          _errorMessage,
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
