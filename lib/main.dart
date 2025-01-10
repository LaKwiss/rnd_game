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
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exploding Atoms',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Routes statiques définies ici
      routes: {
        '/': (context) => const LandingPage(),
        '/lobby': (context) => const LobbyScreen(),
        '/display-name': (context) => const DisplayNameScreen(),
        '/login': (context) => AuthScreen(authMode: AuthMode.signIn),
        '/register': (context) => AuthScreen(authMode: AuthMode.signUp),
      },
      // onGenerateRoute uniquement pour les routes dynamiques
      onGenerateRoute: (settings) => _handleDynamicRoutes(settings),
      // Pour les routes non trouvées
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const _NotFoundScreen(),
      ),
      initialRoute: '/',
    );
  }

  Route<dynamic>? _handleDynamicRoutes(RouteSettings settings) {
    // Gère uniquement les routes dynamiques avec paramètres
    final uri = Uri.parse(settings.name ?? '');

    // Route pour les jeux avec ID
    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'game') {
      final gameId = uri.pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => ExplodingAtomsView(gameId: gameId),
        settings: settings,
      );
    }

    return null; // Retourne null pour laisser le système utiliser onUnknownRoute
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page non trouvée'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Cette page n\'existe pas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.navigateToLandingPage(),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}

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
