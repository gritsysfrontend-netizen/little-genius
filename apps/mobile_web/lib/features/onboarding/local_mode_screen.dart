import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';

class LocalModeScreen extends StatelessWidget {
  const LocalModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              text.localTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(text.localBody, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(text.caregiverPurpose),
            const SizedBox(height: 12),
            Text(text.caregiverPrivacy),
            const SizedBox(height: 12),
            Text(text.caregiverAccount),
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              Text(text.webStorageNote),
            ],
            const SizedBox(height: 24),
            BigButton(
              label: text.continueAction,
              icon: Icons.arrow_forward,
              onPressed: () => context.go('/profile'),
            ),
            const SizedBox(height: 12),
            BigButton(
              label: text.back,
              icon: Icons.arrow_back,
              onPressed: () => context.go('/language'),
            ),
          ],
        ),
      ),
    );
  }
}
