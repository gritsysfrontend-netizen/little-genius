import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    final selected = ref.watch(draftLocaleProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              text.chooseLanguage,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _LanguageButton(
              code: 'en',
              label: text.languageEnglish,
              selected: selected == 'en',
            ),
            _LanguageButton(
              code: 'hi',
              label: text.languageHindi,
              selected: selected == 'hi',
            ),
            _LanguageButton(
              code: 'ta',
              label: text.languageTamil,
              selected: selected == 'ta',
            ),
            const SizedBox(height: 24),
            BigButton(
              label: text.continueAction,
              icon: Icons.arrow_forward,
              onPressed: () => context.go('/local'),
            ),
            const SizedBox(height: 12),
            BigButton(
              label: text.back,
              icon: Icons.arrow_back,
              onPressed: () => context.go('/welcome'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends ConsumerWidget {
  const _LanguageButton({
    required this.code,
    required this.label,
    required this.selected,
  });

  final String code;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BigButton(
        key: Key('language-$code'),
        label: selected ? '$label *' : label,
        icon: Icons.language,
        onPressed: () => ref.read(draftLocaleProvider.notifier).setLocale(code),
      ),
    );
  }
}
