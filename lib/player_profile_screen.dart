import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/auth/auth_repository.dart';
import 'package:rnd_game/main.dart';

class PlayerProfileScreen extends ConsumerStatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen> {
  Future<Map<String, dynamic>> _loadPlayerData() async {
    final uid = await AuthRepository.getUid();
    if (uid == null) {
      context.navigateToLandingPage();
      return {};
    }

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return doc.data() ?? {};
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

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
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            title: Text('Profil Joueur', style: AppTheme.titleStyle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _loadPlayerData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucune donnée disponible'));
              }

              final data = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.padding),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.padding),
                      decoration: BoxDecoration(
                        color: AppTheme.whiteTransparent,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(Icons.person,
                                size: 50, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data['displayName'] ?? 'Joueur Anonyme',
                            style: AppTheme.titleStyle.copyWith(
                              color: AppTheme.primaryColor,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.padding),
                      decoration: BoxDecoration(
                        color: AppTheme.whiteTransparent,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistiques',
                            style: AppTheme.titleStyle.copyWith(
                              color: AppTheme.primaryColor,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            icon: Icons.sports_esports,
                            label: 'Parties jouées',
                            value: (data['gamesPlayed'] ?? 0).toString(),
                          ),
                          _buildStatRow(
                            icon: Icons.emoji_events,
                            label: 'Parties gagnées',
                            value: (data['gamesWon'] ?? 0).toString(),
                          ),
                          _buildStatRow(
                            icon: Icons.timer,
                            label: 'Temps de jeu',
                            value: _formatDuration(data['timePlayed'] ?? 0),
                          ),
                          _buildStatRow(
                            icon: Icons.percent,
                            label: 'Ratio de victoires',
                            value: data['gamesPlayed'] != null &&
                                    data['gamesPlayed'] > 0
                                ? '${(((data['gamesWon'] ?? 0) / data['gamesPlayed']) * 100).toStringAsFixed(1)}%'
                                : '0%',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
