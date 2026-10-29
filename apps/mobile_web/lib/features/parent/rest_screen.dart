import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import '../common/app_status.dart';
import '../common/status_message.dart';

class RestScreen extends ConsumerWidget {
  const RestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                text.sessionEndedTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const StatusMessage(status: AppStatus.sessionEnded),
              const SizedBox(height: 16),
              BigButton(
                key: const Key('rest-home'),
                focusOrder: 1,
                label: text.goHome,
                icon: Icons.home,
                onPressed: () {
                  ref.read(playReminderProvider.notifier).acknowledge();
                  context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
