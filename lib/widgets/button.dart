import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

class Button extends StatelessWidget {
  const Button({Key? key, required this.onPressed, required this.text}) : super(key: key);
  final Function() onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.softShadow,
        ),
        height: 58,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
