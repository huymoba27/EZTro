import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox.shrink() 
        : (icon != null ? Icon(icon, color: Colors.white, size: 20) : const SizedBox.shrink()),
      label: isLoading
        ? const SizedBox(
            height: 20, width: 20, 
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          )
        : Text(
            label.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        minimumSize: const Size(double.infinity, 48), // Chiều cao mới 48
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        disabledBackgroundColor: (color ?? AppColors.primary).withAlpha(153),
      ),
    );
  }
}