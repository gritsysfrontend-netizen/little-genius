import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../domain/profile.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nickname = TextEditingController();
  String _avatar = avatarIds.first;
  String _band = '2-3';
  bool _bilingual = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = AppLocalizations.of(context);
    if (normalizeNickname(_nickname.text) == null) {
      setState(() => _error = text.nicknameInvalid);
      return;
    }
    final profile = await ref
        .read(repositoryProvider)
        .createProfile(
          ProfileDraft(
            nickname: _nickname.text,
            avatarId: _avatar,
            ageBand: _band,
            preferredLocale: ref.read(draftLocaleProvider),
            bilingualMode: _bilingual,
          ),
        );
    await ref.read(sessionProvider.notifier).adopt(profile);
    if (mounted) context.go('/');
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
              text.createProfile,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(text.nicknameLabel),
            TextField(
              key: const Key('nickname-field'),
              controller: _nickname,
              decoration: InputDecoration(hintText: text.nicknameHint),
            ),
            if (_error != null) ...[const SizedBox(height: 8), Text(_error!)],
            const SizedBox(height: 16),
            Text(text.avatarLabel),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in avatarIds)
                  BigButton(
                    key: Key('avatar-$id'),
                    label: _avatar == id
                        ? '${_avatarLabel(text, id)} *'
                        : _avatarLabel(text, id),
                    onPressed: () => setState(() => _avatar = id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(text.ageBandLabel),
            BigButton(
              label: _band == '1-2' ? '${text.band12} *' : text.band12,
              onPressed: () => setState(() => _band = '1-2'),
            ),
            BigButton(
              label: _band == '2-3' ? '${text.band23} *' : text.band23,
              onPressed: () => setState(() => _band = '2-3'),
            ),
            BigButton(
              label: _band == '3-4' ? '${text.band34} *' : text.band34,
              onPressed: () => setState(() => _band = '3-4'),
            ),
            BigButton(
              label: _band == '4-5' ? '${text.band45} *' : text.band45,
              onPressed: () => setState(() => _band = '4-5'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(text.bilingualLabel),
              value: _bilingual,
              onChanged: (value) => setState(() => _bilingual = value),
            ),
            const SizedBox(height: 12),
            BigButton(
              key: const Key('profile-save'),
              label: text.save,
              icon: Icons.check,
              onPressed: _save,
            ),
            const SizedBox(height: 12),
            BigButton(
              label: text.back,
              icon: Icons.arrow_back,
              onPressed: () => context.go('/local'),
            ),
          ],
        ),
      ),
    );
  }
}

String _avatarLabel(AppLocalizations text, String id) {
  return switch (id) {
    'star' => text.avatarStar,
    'sun' => text.avatarSun,
    'leaf' => text.avatarLeaf,
    'moon' => text.avatarMoon,
    'bird' => text.avatarBird,
    'fish' => text.avatarFish,
    _ => id,
  };
}
