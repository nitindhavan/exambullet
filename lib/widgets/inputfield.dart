import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

class InputField extends StatelessWidget {
  const InputField({
    Key? key,
    required this.controller,
    required this.hint,
    this.icon,
  }) : super(key: key);

  final TextEditingController controller;
  final String hint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      height: 58,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.normal,
          ),
          icon: icon != null
              ? Icon(
                  icon,
                  color: AppTheme.textSecondary,
                  size: 22,
                )
              : null,
        ),
      ),
    );
  }
}
