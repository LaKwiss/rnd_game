import 'package:flutter/material.dart';
import 'package:rnd_game/app_theme.dart';

class MoberlyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final bool isPassword;
  final bool isLoading;

  const MoberlyTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.isPassword = false,
    this.isLoading = false,
  });

  @override
  State<MoberlyTextField> createState() => _MoberlyTextFieldState();
}

class _MoberlyTextFieldState extends State<MoberlyTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    // On initialise la variable obscureText en fonction de l’option isPassword
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, color: AppTheme.primaryColor),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        obscureText: _obscureText,
        validator: widget.validator,
        enabled: !widget.isLoading,
        style: const TextStyle(color: AppTheme.primaryColor),
      ),
    );
  }
}
