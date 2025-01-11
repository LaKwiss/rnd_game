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
          floatingActionButton: games.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(lobbyControllerProvider.notifier)
                          .createGame(playerId),
                  backgroundColor: AppTheme.primaryColor,
                  icon: const Icon(Icons.add, color: AppTheme.white),
                  label: Text(
                    'Nouvelle partie',
                    style: AppTheme.buttonTextStyle.copyWith(
                      color: AppTheme.white,
                    ),
                  ),
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

class _GamesList extends StatelessWidget {
  final List<ExplodingAtoms> games;
  final String playerId;
  final VoidCallback onRefresh;

  const _GamesList({
    required this.games,
    required this.playerId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.whiteTransparent,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: GameCard(
                game: games[index],
                playerId: playerId,
              ),
            ),
          );
        },
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
