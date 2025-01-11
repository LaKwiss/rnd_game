import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/auth/auth_repository.dart';
import 'package:rnd_game/cached_user_repository.dart';
import 'package:rnd_game/current_player_provider.dart';
import 'package:rnd_game/data/statistics_repository.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';
import 'package:rnd_game/lobby/lobby_controller.dart';
import 'package:rnd_game/lobby/lobby_game_card.dart';
import 'package:rnd_game/main.dart';
import 'package:rnd_game/shared_preferences_repository.dart';
import 'package:rnd_game/widgets/error_message.dart';
import 'package:rnd_game/widgets/moberly_text_field.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? username = await AuthRepository.getCurrentUsername();
      if (username == null || username.isEmpty) {
        if (mounted) {
          context.navigateToDisplayNameCreation();
        }
        return;
      }

      final uid = await AuthRepository.getUid();
      if (uid != null) {
        await CachedUserRepository.updateDisplayName(uid, username);
        final DateTime? lastConnection =
            await SharedPreferencesRepository.getLastConnection();
        if (lastConnection != null) {
          final difference =
              DateTime.now().difference(lastConnection).inSeconds;
          await StatisticsRepository.incTimePlayed(
              Duration(seconds: difference));
        }
        await StatisticsRepository.setLastConnection(DateTime.now());
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(currentPlayerProvider);
    final gamesAsync = ref.watch(explodingAtomsStreamProvider);
    final lobbyState = ref.watch(lobbyControllerProvider);

    return playerAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/');
        });
        return const _LoadingScreen();
      },
      data: (playerId) {
        if (playerId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/');
          });
          return const _LoadingScreen();
        }

        return gamesAsync.when(
          loading: () => const _LoadingScreen(),
          error: (error, stack) {
            log('Error: $error \n $stack');
            return _ErrorScreen(error: error);
          },
          data: (games) {
            final activeGames = games
                .where((game) => game.status != GameStatus.finished)
                .toList();

            return _LobbyContent(
              games: activeGames,
              playerId: playerId,
              isLoading: lobbyState is AsyncLoading,
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/lake_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                SizedBox(height: 16),
                Text(
                  'Chargement...',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/lake_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              padding: const EdgeInsets.all(AppTheme.padding),
              decoration: BoxDecoration(
                color: AppTheme.whiteTransparent,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade700),
                  const SizedBox(height: 16),
                  Text(
                    'Une erreur est survenue:\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retour à l\'accueil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyContent extends ConsumerWidget {
  final List<ExplodingAtoms> games;
  final String playerId;
  final bool isLoading;

  const _LobbyContent({
    required this.games,
    required this.playerId,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/lake_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            title: Text(
              'Exploding Atoms',
              style: AppTheme.titleStyle,
            ),
            automaticallyImplyLeading: false,
          ),
          body: Stack(
            children: [
              if (games.isEmpty)
                _EmptyLobby(playerId: playerId)
              else
                _GamesList(
                  games: games,
                  playerId: playerId,
                  onRefresh: () => ref.invalidate(explodingAtomsStreamProvider),
                ),
              if (isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TitleButton extends StatelessWidget {
  const TitleButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
      icon: Icon(
        Icons.menu,
        color: Colors.white,
      ),
    );
  }
}

class _EmptyLobby extends StatelessWidget {
  final String playerId;

  const _EmptyLobby({required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.padding),
        padding: const EdgeInsets.all(AppTheme.padding),
        decoration: BoxDecoration(
          color: AppTheme.whiteTransparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_esports,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune partie en cours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _CreateGameButton(playerId: playerId),
          ],
        ),
      ),
    );
  }
}

class _GamesList extends ConsumerStatefulWidget {
  final List<ExplodingAtoms> games;
  final String playerId;
  final VoidCallback onRefresh;

  const _GamesList({
    required this.games,
    required this.playerId,
    required this.onRefresh,
  });

  @override
  ConsumerState<_GamesList> createState() => _GamesListState();
}

class _GamesListState extends ConsumerState<_GamesList> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      // Nous utilisons un CustomScrollView pour combiner plusieurs widgets défilables
      child: CustomScrollView(
        slivers: [
          // En-tête avec le bouton de création
          SliverToBoxAdapter(
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0)
                        .copyWith(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(lobbyControllerProvider.notifier)
                          .createGame(widget.playerId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Créer une nouvelle partie',
                        style: AppTheme.buttonTextStyle,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0)
                        .copyWith(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => showDialog(
                          context: context,
                          builder: (context) =>
                              JoinGameDialog(playerId: widget.playerId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Rejoindre une partie',
                        style: AppTheme.buttonTextStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Liste des parties
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.whiteTransparent,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: GameCard(
                        game: widget.games[index],
                        playerId: widget.playerId,
                      ),
                    ),
                  );
                },
                childCount: widget.games.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGameButton extends ConsumerWidget {
  final String playerId;

  const _CreateGameButton({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () =>
          ref.read(lobbyControllerProvider.notifier).createGame(playerId),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
      icon: const Icon(Icons.add),
      label: Text(
        'Créer une partie',
        style: AppTheme.buttonTextStyle.copyWith(
          color: AppTheme.white,
        ),
      ),
    );
  }
}

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
      final game =
          await ref.read(explodingAtomsStreamProvider).value?.firstWhere(
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
              Text(
                'Rejoindre une partie',
                style: AppTheme.titleStyle.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              MoberlyTextField(
                controller: _gameIdController,
                label: 'ID de la partie',
                icon: Icons.tag,
                validator: _validateGameId,
                isLoading: _isLoading,
              ),
              ErrorMessage(errorMessage: _errorMessage),
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
