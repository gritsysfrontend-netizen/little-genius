import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';

class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key});

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  final _answer = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_answer.text.trim() == '7') {
      ref.read(parentGateProvider.notifier).unlock();
      context.go('/parent');
      return;
    }
    setState(() => _wrong = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              text.gateTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(text.gateBody),
            const SizedBox(height: 16),
            Text(
              text.gateQuestion,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextField(
              key: const Key('gate-answer'),
              controller: _answer,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: text.gateQuestion),
            ),
            if (_wrong) ...[const SizedBox(height: 8), Text(text.gateWrong)],
            const SizedBox(height: 16),
            BigButton(
              key: const Key('gate-continue'),
              label: text.continueAction,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            BigButton(
              label: text.goHome,
              icon: Icons.home,
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}
