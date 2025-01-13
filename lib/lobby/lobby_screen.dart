import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/auth/auth_repository.dart';
import 'package:rnd_game/current_player_provider.dart';
import 'package:rnd_game/data/statistics_repository.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';
import 'package:rnd_game/lobby/create_game_button.dart';
import 'package:rnd_game/lobby/join_game_dialog.dart';
import 'package:rnd_game/lobby/lobby_controller.dart';
import 'package:rnd_game/lobby/lobby_game_card.dart';

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
          log('Navigating to display name creation');
          //context.navigateToDisplayNameCreation();
          return;
        }
      }

      final uid = await AuthRepository.getUid();
      if (uid != null) {
        final DateTime? lastConnection =
            await AuthRepository.getLastConnection(uid);
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
          log('Navigating to login screen: $error \n $stack');
          //Navigator.of(context).pushReplacementNamed('/');
        });
        return const _LoadingScreen();
      },
      data: (playerId) {
        log('PlayerId: $playerId');
        if (playerId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            log('Navigating to login screen');
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

            return LobbyContent(
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

class LobbyContent extends ConsumerWidget {
  final List<ExplodingAtoms> games;
  final String playerId;
  final bool isLoading;

  const LobbyContent({
    required this.games,
    required this.playerId,
    required this.isLoading,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

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
          key: scaffoldKey,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            title: Text('Exploding Atoms', style: AppTheme.titleStyle),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
                icon: const Icon(Icons.grid_view_sharp, color: Colors.white),
              ),
            ],
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
              if (isLoading) const LoadingOverlay(),
            ],
          ),
          endDrawer: Drawer(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            backgroundColor: Color(0xFF0000FF),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        height: 150,
                        color: Colors.white,
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 40,
                              left: 16,
                              child: Text(
                                'Moderly',
                                style: AppTheme.secondTitleStyle,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 16,
                              child: Text(
                                'Lake',
                                style: AppTheme.secondTitleStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.person,
                        title: 'Player Profile',
                        route: '/profile',
                      ),
                      _buildDrawerItem(
                        context: context,
                        icon: Icons.settings,
                        title: 'Settings',
                        route: '/settings',
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Logout',
                  route: '/',
                  replace: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    bool replace = false,
    Function? onTap,
  }) {
    return GestureDetector(
      onTap: onTap as void Function()?,
      child: ListTile(
        minTileHeight: 60.0,
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        onTap: () {
          if (replace) {
            Navigator.of(context).pushReplacementNamed(route);
          } else {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
            CreateGameButton(playerId: playerId),
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
