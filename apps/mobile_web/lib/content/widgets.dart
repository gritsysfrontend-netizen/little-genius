import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'lesson_parser.dart';

class SafeFallback extends StatelessWidget {
  const SafeFallback({super.key, required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text.contentUnavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            BigButton(label: text.goHome, onPressed: onHome, icon: Icons.home),
          ],
        ),
      ),
    );
  }
}

class LessonRenderer extends StatelessWidget {
  const LessonRenderer({
    super.key,
    required this.lesson,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.imageBytes,
    required this.imageLabel,
    required this.onTarget,
    required this.onHome,
    required this.onBack,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.onReplayOther,
    this.audioMissing = false,
  });

  final ParsedLesson lesson;
  final String instruction;
  final String? secondaryTitle;
  final String? feedback;
  final Uint8List? imageBytes;
  final String imageLabel;
  final VoidCallback onTarget;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback? onReplayOther;
  final bool audioMissing;

  @override
  Widget build(BuildContext context) {
    return switch (lesson) {
      SupportedLesson(:final document)
          when document.interaction.type == 'tap_to_learn' =>
        TapToLearnView(
          instruction: instruction,
          secondaryTitle: secondaryTitle,
          feedback: feedback,
          imageBytes: imageBytes,
          imageLabel: imageLabel,
          onTarget: onTarget,
          onHome: onHome,
          onBack: onBack,
          onPlay: onPlay,
          onPause: onPause,
          onReplay: onReplay,
          onReplayOther: onReplayOther,
          audioMissing: audioMissing,
        ),
      _ => SafeFallback(onHome: onHome),
    };
  }
}

class TapToLearnView extends StatelessWidget {
  const TapToLearnView({
    super.key,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.imageBytes,
    required this.imageLabel,
    required this.onTarget,
    required this.onHome,
    required this.onBack,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.onReplayOther,
    this.audioMissing = false,
  });

  final String instruction;
  final String? secondaryTitle;
  final String? feedback;
  final Uint8List? imageBytes;
  final String imageLabel;
  final VoidCallback onTarget;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback? onReplayOther;
  final bool audioMissing;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Column(
      children: [
        ChildBar(onBack: onBack, onHome: onHome),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                instruction,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (secondaryTitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  secondaryTitle!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: imageLabel,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    key: const Key('tap-target'),
                    borderRadius: BorderRadius.circular(28),
                    onTap: onTarget,
                    child: SizedBox(
                      height: 280,
                      child: imageBytes == null
                          ? const Icon(Icons.image_not_supported, size: 72)
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.contain,
                                semanticLabel: imageLabel,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.image_not_supported,
                                      size: 72,
                                    ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  BigButton(
                    label: text.playAudio,
                    icon: Icons.volume_up,
                    onPressed: onPlay,
                  ),
                  BigButton(
                    label: text.pause,
                    icon: Icons.pause,
                    onPressed: onPause,
                  ),
                  BigButton(
                    label: text.replay,
                    icon: Icons.replay,
                    onPressed: onReplay,
                  ),
                  if (onReplayOther != null)
                    BigButton(
                      label: text.hearOtherLanguage,
                      icon: Icons.translate,
                      onPressed: onReplayOther,
                    ),
                ],
              ),
              if (audioMissing) ...[
                const SizedBox(height: 12),
                Text(text.audioMissing),
              ],
              if (feedback != null) ...[
                const SizedBox(height: 20),
                Text(
                  feedback!,
                  key: const Key('feedback'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ChildBar extends StatelessWidget {
  const ChildBar({
    super.key,
    required this.onHome,
    this.onBack,
    this.backOrder,
    this.homeOrder,
  });

  final VoidCallback onHome;
  final VoidCallback? onBack;
  final double? backOrder;
  final double? homeOrder;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          if (onBack != null)
            BigButton(
              label: text.back,
              icon: Icons.arrow_back,
              focusOrder: backOrder,
              onPressed: onBack,
            ),
          BigButton(
            key: const Key('home-button'),
            label: text.goHome,
            icon: Icons.home,
            focusOrder: homeOrder,
            onPressed: onHome,
          ),
        ],
      ),
    );
  }
}

class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.focusOrder,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? focusOrder;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          ExcludeSemantics(child: Icon(icon ?? Icons.circle)),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
    if (focusOrder == null) return button;
    return FocusTraversalOrder(
      order: NumericFocusOrder(focusOrder!),
      child: button,
    );
  }
}
