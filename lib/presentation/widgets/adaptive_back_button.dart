import 'package:flutter/material.dart';

class AdaptiveBackButton extends StatelessWidget {
  const AdaptiveBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
