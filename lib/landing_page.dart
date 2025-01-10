import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rnd_game/main.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static final registerButton = ButtonStyle();

  static final loginButton = ButtonStyle();

  static final registerButtonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Welcome to'),
        Text('Moberly Lake'),
        Row(
          children: [
            TextButton(
              style: registerButton,
              onPressed: () => context.navigateToRegister(),
              child: Text(
                'REGISTER',
                style: registerButtonText,
              ),
            ),
            TextButton(
              onPressed: () => context.navigateToLogin(),
              child: Text('LOGIN'),
            ),
          ],
        ),
      ],
    );
  }
}
