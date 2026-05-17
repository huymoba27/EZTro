import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'test_tool_config.dart';

class DevAutofillButton extends StatelessWidget {
  final FutureOr<void> Function() onPressed;
  final String label;

  const DevAutofillButton({
    super.key,
    required this.onPressed,
    this.label = 'Auto Fill',
  });

  @override
  Widget build(BuildContext context) {
    if (!TestToolConfig.enabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const ValueKey('dev_autofill_button'),
          onPressed: () => onPressed(),
          icon: const Icon(Icons.bolt_outlined, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
