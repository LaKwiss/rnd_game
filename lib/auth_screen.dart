import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

// Enum pour gérer les différents états d'authentification
enum AuthMode {
  signIn,
  signUp;

  String get title => this == AuthMode.signIn ? 'Connexion' : 'Inscription';
  String get switchButtonText => this == AuthMode.signIn
      ? 'Pas de compte ? Inscrivez-vous'
      : 'Déjà un compte ? Connectez-vous';
  String get submitButtonText =>
      this == AuthMode.signIn ? 'Se connecter' : 'S\'inscrire';
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs de formulaire
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  // États du formulaire
  var _authMode = AuthMode.signIn;
  var _isLoading = false;
  String? _errorMessage;

  // Validateurs pour les champs
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (_authMode == AuthMode.signUp && value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? _validateDisplayName(String? value) {
    if (_authMode == AuthMode.signUp) {
      if (value == null || value.isEmpty) {
        return 'Veuillez entrer votre nom d\'utilisateur';
      }
      if (value.length < 3) {
        return 'Le nom doit contenir au moins 3 caractères';
      }
    }
    return null;
  }

  // Gestion des erreurs Firebase
  String _getErrorMessage(String code) {
    return switch (code) {
      'user-not-found' => 'Aucun utilisateur trouvé avec cet email',
      'wrong-password' => 'Mot de passe incorrect',
      'email-already-in-use' => 'Cet email est déjà utilisé',
      'invalid-email' => 'Email invalide',
      'weak-password' => 'Le mot de passe doit contenir au moins 6 caractères',
      _ => 'Une erreur est survenue: $code',
    };
  }

  // Soumission du formulaire
  Future<void> _submit() async {
    // Validation du formulaire
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (_authMode == AuthMode.signUp) {
        // Création du compte
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Mise à jour du profil avec le nom d'utilisateur
        await userCredential.user?.updateDisplayName(
          _displayNameController.text.trim(),
        );

        // Attendre que le displayName soit bien mis à jour
        await auth.currentUser?.reload();
      } else {
        // Connexion
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (userCredential.user?.uid != null) {
        // Sauvegarde de l'UID dans les préférences
        await SharedPreferencesRepository.setUid(userCredential.user!.uid);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/lobby');
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur d\'authentification';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Changement de mode (connexion/inscription)
  void _switchAuthMode() {
    setState(() {
      _authMode =
          _authMode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titre
                Text(
                  _authMode.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Champ email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Champ displayName (uniquement en mode inscription)
                if (_authMode == AuthMode.signUp) ...[
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom d\'utilisateur',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validateDisplayName,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                ],

                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  obscureText: true,
                  validator: _validatePassword,
                  enabled: !_isLoading,
                ),

                // Message d'erreur
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Bouton de soumission
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_authMode.submitButtonText),
                ),

                // Bouton de changement de mode
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _switchAuthMode,
                  child: Text(_authMode.switchButtonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
