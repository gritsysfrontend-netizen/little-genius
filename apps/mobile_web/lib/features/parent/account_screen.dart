import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/pkce.dart';
import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import '../common/page_frame.dart';
import 'account_conversion.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.web, this.onLeave});

  final bool? web;
  final VoidCallback? onLeave;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _consent = false;
  String? _notice;

  bool get _web => widget.web ?? kIsWeb;

  void _leave() {
    final leave = widget.onLeave;
    if (leave != null) {
      leave();
      return;
    }
    context.go('/parent');
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final profile = ref.watch(sessionProvider).value;
    return PageFrame(
      onBack: _leave,
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            text.accountTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          if (_web) ...[
            Text(text.webStaysLocal, key: const Key('web-local-mode')),
            const SizedBox(height: 12),
            Text(text.accountNotAvailable),
          ] else ...[
            Text(text.consentNotLegal, key: const Key('consent-not-legal')),
            const SizedBox(height: 12),
            Text(text.uploadExplain, key: const Key('upload-explain')),
            const SizedBox(height: 12),
            Text(text.cancelLeavesDevice),
            if (profile != null) ...[
              const SizedBox(height: 12),
              Text(profile.profileId, key: const Key('client-profile-id')),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              key: const Key('consent-checkbox'),
              value: _consent,
              onChanged: (value) => setState(() => _consent = value ?? false),
              title: Text(text.consentNotLegal),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            BigButton(
              key: const Key('account-continue'),
              label: text.continueAction,
              icon: Icons.arrow_forward,
              onPressed: () {
                final current = profile;
                if (current == null) return;
                if (!_consent) {
                  setState(() => _notice = text.consentRequired);
                  return;
                }
                final plan = buildAccountUpload(
                  consentGranted: true,
                  cognitoConfigured: settingsFromEnvironment().configured,
                  profile: current,
                  events: const [],
                );
                setState(() {
                  _notice = text.cognitoNotConfigured;
                  assert(
                    plan == null || plan.clientProfileId == current.profileId,
                  );
                });
              },
            ),
            const SizedBox(height: 12),
            BigButton(
              key: const Key('account-delete'),
              label: text.requestDeletion,
              icon: Icons.delete_outline,
              onPressed: () {
                final attempt = requestDeletion(online: false);
                setState(() {
                  _notice = attempt.showsFinished
                      ? text.deletionFinished
                      : text.deletionNeedsNetwork;
                });
              },
            ),
          ],
          const SizedBox(height: 12),
          BigButton(
            key: const Key('account-cancel'),
            label: text.cancel,
            icon: Icons.close,
            onPressed: _leave,
          ),
          if (_notice != null) ...[
            const SizedBox(height: 12),
            Text(_notice!, key: const Key('account-notice')),
          ],
        ],
      ),
    );
  }
}
