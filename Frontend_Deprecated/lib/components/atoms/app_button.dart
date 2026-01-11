// Atom: AppButton
// Single Functionality: Reusable button with consistent styling and single action callback

import 'package:flutter/material.dart';

enum AppButtonType { primary, secondary, text, icon }

class AppButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final String? tooltip;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.tooltip,
  });

  const AppButton.primary({
    super.key,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  })  : label = label,
        icon = null,
        onPressed = onPressed,
        type = AppButtonType.primary,
        isLoading = isLoading,
        tooltip = null;

  const AppButton.secondary({
    super.key,
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  })  : label = label,
        icon = icon,
        onPressed = onPressed,
        type = AppButtonType.secondary,
        isLoading = isLoading,
        tooltip = null;

  const AppButton.icon({
    super.key,
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
  })  : icon = icon,
        label = null,
        onPressed = onPressed,
        type = AppButtonType.icon,
        isLoading = false,
        tooltip = tooltip;

  const AppButton.text({
    super.key,
    required String label,
    required VoidCallback? onPressed,
  })  : label = label,
        icon = null,
        onPressed = onPressed,
        type = AppButtonType.text,
        isLoading = false,
        tooltip = null;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: onPressed,
          child: label != null ? Text(label!) : Icon(icon),
        );
      case AppButtonType.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          child: icon != null && label != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label!),
                ],
              )
            : (label != null ? Text(label!) : Icon(icon)),
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: onPressed,
          child: Text(label!),
        );
      case AppButtonType.icon:
        return IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: tooltip,
        );
    }
  }
}
