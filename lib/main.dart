import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rnd_game/auth/auth_screen.dart';
import 'package:rnd_game/cached_user_repository.dart';
import 'package:rnd_game/landing_page.dart';
import 'package:rnd_game/lobby/lobby_screen.dart';
import 'package:rnd_game/exploding_atoms_view.dart';
import 'package:rnd_game/firebase_options.dart';
import 'package:rnd_game/temp/display_name_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await CachedUserRepository.init();
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exploding Atoms',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Utilisation de onGenerateRoute pour gérer les paramètres dynamiques
      onGenerateRoute: (settings) {
        // Extraction des paramètres de l'URL pour /game/:id
        if (settings.name?.startsWith('/game/') ?? false) {
          final pathSegments = settings.name?.split('/');

          // Vérifie qu'on a bien un ID après /game/
          if (pathSegments != null && pathSegments.length > 2) {
            final gameId = pathSegments[2];
            return MaterialPageRoute(
              builder: (context) => ExplodingAtomsView(gameId: gameId),
              settings: settings,
            );
          }
        }

        // Routes statiques
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const LandingPage(),
              settings: settings,
            );
          case '/lobby':
            return MaterialPageRoute(
              builder: (context) => const LobbyScreen(),
              settings: settings,
            );
          case '/display-name':
            return MaterialPageRoute(
              builder: (context) => const DisplayNameScreen(),
              settings: settings,
            );
          case '/login':
            return MaterialPageRoute(
              builder: (context) => AuthScreen(authMode: AuthMode.signIn),
              settings: settings,
            );

          case '/register':
            return MaterialPageRoute(
              builder: (context) => AuthScreen(authMode: AuthMode.signUp),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text('Page not found'),
                ),
              ),
              settings: settings,
            );
        }
      },
      // Redirection initiale vers l'auth screen
      initialRoute: '/',
    );
  }
}

// Extension pour faciliter la navigation
extension NavigationExtension on BuildContext {
  void navigateToGame(String gameId) {
    Navigator.pushReplacementNamed(this, '/game/$gameId');
  }

  void navigateToLobby() {
    Navigator.pushReplacementNamed(this, '/lobby');
  }

  void navigateToDisplayNameCreation() {
    Navigator.pushReplacementNamed(this, '/display-name');
  }

  void navigateToLandingPage() {
    Navigator.pushReplacementNamed(this, '/');
  }

  void navigateToLogin() {
    Navigator.pushNamed(this, '/login');
  }

  void navigateToRegister() {
    Navigator.pushNamed(this, '/register');
  }
}
