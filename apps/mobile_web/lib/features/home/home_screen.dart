import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import 'catalog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    final profile = ref.watch(sessionProvider).value;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              text.helloName(profile?.nickname ?? ''),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            BigButton(
              key: const Key('animals-button'),
              label: text.animalsTitle,
              icon: Icons.pets,
              onPressed: () => context.go('/c/$animalsCategoryId'),
            ),
            const SizedBox(height: 12),
            BigButton(
              key: const Key('grown-ups'),
              label: text.parentArea,
              icon: Icons.lock_outline,
              onPressed: () => context.go('/parent'),
            ),
          ],
        ),
      ),
    );
  }
}
