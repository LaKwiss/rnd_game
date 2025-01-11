import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';
import 'package:rnd_game/lobby/lobby_controller.dart';
import 'package:rnd_game/widgets/error_message.dart';
import 'package:rnd_game/widgets/moberly_text_field.dart';

class JoinGameDialog extends ConsumerStatefulWidget {
  final String playerId;

  const JoinGameDialog({
    super.key,
    required this.playerId,
  });

  @override
  ConsumerState<JoinGameDialog> createState() => _JoinGameDialogState();
}

class _JoinGameDialogState extends ConsumerState<JoinGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gameIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _gameIdController.dispose();
    super.dispose();
  }

  // Validation de l'ID de la partie
  String? _validateGameId(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'ID de la partie est requis';
    }
    // Vous pouvez ajouter d'autres validations si nécessaire
    return null;
  }

  Future<void> _joinGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // On récupère d'abord la partie pour vérifier son état
      final game = ref.read(explodingAtomsStreamProvider).value?.firstWhere(
            (game) => game.id == _gameIdController.text.trim(),
            orElse: () => throw Exception('not_found'),
          );

      // Si la partie n'accepte plus de joueurs
      if (game != null && !game.canJoin) {
        throw Exception('game_full');
      }

      // Si la partie est déjà terminée
      if (game != null && game.status == GameStatus.finished) {
        throw Exception('game_finished');
      }

      // On essaie de rejoindre la partie
      await ref
          .read(lobbyControllerProvider.notifier)
          .joinGame(_gameIdController.text.trim(), widget.playerId);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        // Messages d'erreur personnalisés selon le type d'erreur
        if (e is Exception && e.toString().contains('not_found')) {
          _errorMessage = 'Cette partie n\'existe pas';
        } else if (e is Exception && e.toString().contains('game_full')) {
          _errorMessage = 'Cette partie n\'accepte plus de joueurs';
        } else if (e is Exception && e.toString().contains('game_finished')) {
          _errorMessage = 'Cette partie est déjà terminée';
        } else {
          _errorMessage =
              'Impossible de rejoindre la partie. Vérifiez l\'ID et réessayez.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nouveau: Ajout d'un Stack pour superposer le titre et le bouton de fermeture
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Rejoindre une partie',
                    style: AppTheme.titleStyle.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Le reste du contenu reste inchangé...
              MoberlyTextField(
                controller: _gameIdController,
                label: 'ID de la partie',
                icon: Icons.tag,
                validator: _validateGameId,
                isLoading: _isLoading,
              ),
              ErrorMessage(
                errorMessage: _errorMessage,
                onClose: _errorMessage != null
                    ? () => setState(() => _errorMessage = null)
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Rejoindre',
                        style: AppTheme.buttonTextStyle
                            .copyWith(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
