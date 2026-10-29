import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../data/records.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import 'catalog.dart';
import 'category_titles.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<String, StoredDocument> _local = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final documents = await ref.read(repositoryProvider).listDocuments();
    if (!mounted) return;
    final local = <String, StoredDocument>{};
    for (final document in documents) {
      final current = local[document.contentId];
      if (current == null || document.contentVersion > current.contentVersion) {
        local[document.contentId] = document;
      }
    }
    setState(() => _local = local);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final profile = ref.watch(sessionProvider).value;
    ref.listen(sessionProvider, (previous, next) => _load());
    final categories = categoriesFor(
      ageBand: profile?.ageBand ?? '2-3',
      locale: profile?.preferredLocale ?? 'en',
      localById: _local,
    );
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
            for (final categoryId in categories) ...[
              BigButton(
                key: Key(
                  categoryId == animalsCategoryId
                      ? 'animals-button'
                      : 'category-$categoryId',
                ),
                label: categoryLabel(text, categoryId),
                icon: categoryIcon(categoryId),
                onPressed: () => context.go('/c/$categoryId'),
              ),
              const SizedBox(height: 12),
            ],
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
