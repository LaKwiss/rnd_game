import 'package:flutter/material.dart';
import 'package:rnd_game/app_theme.dart';

class ErrorMessage extends StatelessWidget {
  final String? errorMessage;
  // Ajout d'un callback pour gérer la fermeture
  final VoidCallback? onClose;

  const ErrorMessage({
    super.key,
    required this.errorMessage,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Ajout du bouton de fermeture
            if (onClose != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.red[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
