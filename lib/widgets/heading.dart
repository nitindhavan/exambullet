import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';

class Heading extends StatelessWidget {
  const Heading({Key? key, required this.heading}) : super(key: key);

  final String heading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        heading,
        style: AppTheme.displayLg.copyWith(fontSize: 22),
      ),
    );
  }
}
