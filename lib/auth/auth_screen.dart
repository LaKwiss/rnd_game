import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rnd_game/app_theme.dart';
import 'package:rnd_game/auth/auth_repository.dart';
import 'package:rnd_game/main.dart';
import 'package:rnd_game/widgets/error_message.dart';
import 'package:rnd_game/widgets/moberly_text_field.dart';

// Enumération des modes d'authentification
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
  const AuthScreen({this.authMode = AuthMode.signIn, super.key});

  final AuthMode authMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  late AuthMode _authMode;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AuthRepository.logout();
    });

    super.initState();
    _authMode = widget.authMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // Méthodes de validation
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

  // Gestion des messages d'erreur
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      default:
        return 'Une erreur est survenue: $code';
    }
  }

  // Méthode de soumission du formulaire
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential;

      if (_authMode == AuthMode.signUp) {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await userCredential.user?.updateDisplayName(
          _displayNameController.text.trim(),
        );

        await auth.currentUser?.reload();
      } else {
        userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (userCredential.user?.uid != null) {
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

  // Méthode pour changer le mode d'authentification
  void _switchAuthMode() => _authMode == AuthMode.signIn
      ? context.navigateToRegister()
      : context.navigateToLogin();

  // Widget pour le titre principal
  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Text(
        _authMode.title.toUpperCase(),
        style: AppTheme.titleStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  // Widget pour le bouton principal
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
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
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              _authMode.submitButtonText.toUpperCase(),
              style: AppTheme.buttonTextStyle,
            ),
    );
  }

  // Widget pour le bouton de changement de mode
  Widget _buildSwitchModeButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 1,
        ),
      ),
      child: TextButton(
        onPressed: _isLoading ? null : _switchAuthMode,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
        child: Text(
          _authMode.switchButtonText.toUpperCase(),
          style: AppTheme.switchButtonTextStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/arc_de_triomphe.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 32),
                      // Container des champs de formulaire
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.whiteTransparent,
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadius),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Champ Email
                            Text('Email', style: AppTheme.labelStyle),
                            const SizedBox(height: 8),
                            MoberlyTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email,
                              validator: AuthRepository.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            // Champ Nom d'utilisateur (uniquement pour l'inscription)
                            if (_authMode == AuthMode.signUp) ...[
                              Text(
                                'Nom d\'utilisateur',
                                style: AppTheme.labelStyle,
                              ),
                              const SizedBox(height: 8),
                              MoberlyTextField(
                                controller: _displayNameController,
                                label: 'Username',
                                icon: Icons.person,
                                validator: _validateDisplayName,
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Champ Mot de passe
                            Text('Mot de passe', style: AppTheme.labelStyle),
                            const SizedBox(height: 8),
                            MoberlyTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock,
                              validator: _validatePassword,
                              isPassword: true,
                            ),
                          ],
                        ),
                      ),
                      ErrorMessage(errorMessage: _errorMessage),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildSwitchModeButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
