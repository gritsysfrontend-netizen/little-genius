import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                text.welcomeTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                text.welcomeBody,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              BigButton(
                label: text.continueAction,
                icon: Icons.arrow_forward,
                onPressed: () => context.go('/language'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
