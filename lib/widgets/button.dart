import 'package:flutter/material.dart';
import 'package:percent/widgets/ui/app_button.dart';

/// Deprecated: kept for backwards compatibility. Use [AppButton] directly.
///
/// Delegates to the shared [AppButton] so any remaining call sites render the
/// canonical primary button.
@Deprecated('Use AppButton from widgets/ui/ui.dart')
class Button extends StatelessWidget {
  const Button({Key? key, required this.onPressed, required this.text})
      : super(key: key);
  final Function() onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AppButton(label: text, onPressed: onPressed),
    );
  }
}
