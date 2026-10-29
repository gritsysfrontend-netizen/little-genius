import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'lesson_interaction.dart';
import 'widgets.dart';

class SingleChoiceView extends StatefulWidget {
  const SingleChoiceView({
    super.key,
    required this.interaction,
    required this.locale,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.onSolved,
    required this.onRetry,
    required this.onHome,
    required this.onBack,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.onReplayOther,
    this.audioMissing = false,
  });

  final SingleChoice interaction;
  final String locale;
  final String instruction;
  final String? secondaryTitle;
  final String? feedback;
  final VoidCallback onSolved;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback? onReplayOther;
  final bool audioMissing;

  @override
  State<SingleChoiceView> createState() => _SingleChoiceViewState();
}

class _SingleChoiceViewState extends State<SingleChoiceView> {
  var _solved = false;

  void _choose(String id) {
    if (_solved) return;
    if (id == widget.interaction.answerId) {
      setState(() => _solved = true);
      widget.onSolved();
      return;
    }
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    return ActivityChrome(
      instruction: widget.instruction,
      secondaryTitle: widget.secondaryTitle,
      feedback: widget.feedback,
      audioMissing: widget.audioMissing,
      onHome: widget.onHome,
      onBack: widget.onBack,
      onPlay: widget.onPlay,
      onPause: widget.onPause,
      onReplay: widget.onReplay,
      onReplayOther: widget.onReplayOther,
      body: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final choice in widget.interaction.choices)
            if (choice.label.forLocale(widget.locale) case final label?)
              BigButton(
                key: Key('choice-${choice.id}'),
                label: label,
                onPressed: () => _choose(choice.id),
              ),
        ],
      ),
    );
  }
}

class MatchingView extends StatefulWidget {
  const MatchingView({
    super.key,
    required this.interaction,
    required this.locale,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.onSolved,
    required this.onRetry,
    required this.onHome,
    required this.onBack,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.onReplayOther,
    this.audioMissing = false,
  });

  final MatchingPairs interaction;
  final String locale;
  final String instruction;
  final String? secondaryTitle;
  final String? feedback;
  final VoidCallback onSolved;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback? onReplayOther;
  final bool audioMissing;

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  String? _selected;
  final _matched = <String>{};
  var _solved = false;

  void _pickPrompt(String id) {
    if (_solved || _matched.contains(id)) return;
    setState(() => _selected = id);
  }

  void _pickMatch(String id) {
    if (_solved || _matched.contains(id)) return;
    final selected = _selected;
    if (selected == null) return;
    if (selected != id) {
      setState(() => _selected = null);
      widget.onRetry();
      return;
    }
    var done = false;
    setState(() {
      _matched.add(id);
      _selected = null;
      if (_matched.length == widget.interaction.pairs.length) {
        _solved = true;
        done = true;
      }
    });
    if (done) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.interaction.pairs.reversed.toList();
    return ActivityChrome(
      instruction: widget.instruction,
      secondaryTitle: widget.secondaryTitle,
      feedback: widget.feedback,
      audioMissing: widget.audioMissing,
      onHome: widget.onHome,
      onBack: widget.onBack,
      onPlay: widget.onPlay,
      onPause: widget.onPause,
      onReplay: widget.onReplay,
      onReplayOther: widget.onReplayOther,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final pair in widget.interaction.pairs)
                if (pair.prompt.forLocale(widget.locale) case final label?)
                  BigButton(
                    key: Key('prompt-${pair.id}'),
                    label: label,
                    onPressed: _matched.contains(pair.id)
                        ? null
                        : () => _pickPrompt(pair.id),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final pair in matches)
                if (pair.match.forLocale(widget.locale) case final label?)
                  BigButton(
                    key: Key('match-${pair.id}'),
                    label: label,
                    onPressed: _matched.contains(pair.id)
                        ? null
                        : () => _pickMatch(pair.id),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class SortingView extends StatefulWidget {
  const SortingView({
    super.key,
    required this.interaction,
    required this.locale,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.onSolved,
    required this.onRetry,
    required this.onHome,
    required this.onBack,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.onReplayOther,
    this.audioMissing = false,
  });

  final SortingActivity interaction;
  final String locale;
  final String instruction;
  final String? secondaryTitle;
  final String? feedback;
  final VoidCallback onSolved;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback? onReplayOther;
  final bool audioMissing;

  @override
  State<SortingView> createState() => _SortingViewState();
}

class _SortingViewState extends State<SortingView> {
  String? _selected;
  final _placed = <String>{};
  var _solved = false;

  void _pickItem(String id) {
    if (_solved || _placed.contains(id)) return;
    setState(() => _selected = id);
  }

  void _pickBin(String binId) {
    final itemId = _selected;
    if (_solved || itemId == null) return;
    final item = widget.interaction.items.firstWhere((row) => row.id == itemId);
    if (item.binId != binId) {
      setState(() => _selected = null);
      widget.onRetry();
      return;
    }
    var done = false;
    setState(() {
      _placed.add(itemId);
      _selected = null;
      if (_placed.length == widget.interaction.items.length) {
        _solved = true;
        done = true;
      }
    });
    if (done) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    return ActivityChrome(
      instruction: widget.instruction,
      secondaryTitle: widget.secondaryTitle,
      feedback: widget.feedback,
      audioMissing: widget.audioMissing,
      onHome: widget.onHome,
      onBack: widget.onBack,
      onPlay: widget.onPlay,
      onPause: widget.onPause,
      onReplay: widget.onReplay,
      onReplayOther: widget.onReplayOther,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in widget.interaction.items)
                if (item.label.forLocale(widget.locale) case final label?)
                  BigButton(
                    key: Key('item-${item.id}'),
                    label: label,
                    onPressed: _placed.contains(item.id)
                        ? null
                        : () => _pickItem(item.id),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final bin in widget.interaction.bins)
                if (bin.label.forLocale(widget.locale) case final label?)
                  BigButton(
                    key: Key('bin-${bin.id}'),
                    label: label,
                    onPressed: () => _pickBin(bin.id),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class CountingView extends StatefulWidget {
  const CountingView({
    super.key,
    required this.interaction,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.onSolved,
    required this.onRetry,
    required this.onHome,
    required this.onBack,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.onReplayOther,
    this.audioMissing = false,
  });

  final CountingActivity interaction;
  final String instruction;
  final String? secondaryTitle;
  final String? feedback;
  final VoidCallback onSolved;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback? onReplayOther;
  final bool audioMissing;

  @override
  State<CountingView> createState() => _CountingViewState();
}

class _CountingViewState extends State<CountingView> {
  var _count = 0;
  var _solved = false;

  void _more() {
    if (_solved || _count >= widget.interaction.maxCount) return;
    setState(() => _count += 1);
  }

  void _less() {
    if (_solved || _count <= 0) return;
    setState(() => _count -= 1);
  }

  void _done() {
    if (_solved) return;
    if (_count == widget.interaction.targetCount) {
      setState(() => _solved = true);
      widget.onSolved();
      return;
    }
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ActivityChrome(
      instruction: widget.instruction,
      secondaryTitle: widget.secondaryTitle,
      feedback: widget.feedback,
      audioMissing: widget.audioMissing,
      onHome: widget.onHome,
      onBack: widget.onBack,
      onPlay: widget.onPlay,
      onPause: widget.onPause,
      onReplay: widget.onReplay,
      onReplayOther: widget.onReplayOther,
      body: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          BigButton(
            key: const Key('count-less'),
            label: text.countLess,
            icon: Icons.remove,
            onPressed: _less,
          ),
          Text(
            '$_count',
            key: const Key('count-value'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          BigButton(
            key: const Key('count-more'),
            label: text.countMore,
            icon: Icons.add,
            onPressed: _more,
          ),
          BigButton(
            key: const Key('count-done'),
            label: text.countDone,
            icon: Icons.check,
            onPressed: _done,
          ),
        ],
      ),
    );
  }
}

class SequencingView extends StatefulWidget {
  const SequencingView({
    super.key,
    required this.interaction,
    required this.locale,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.onSolved,
    required this.onRetry,
    required this.onHome,
    required this.onBack,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.onReplayOther,
    this.audioMissing = false,
  });

  final SequencingActivity interaction;
  final String locale;
  final String instruction;
  final String? secondaryTitle;
  final String? feedback;
  final VoidCallback onSolved;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback? onReplayOther;
  final bool audioMissing;

  @override
  State<SequencingView> createState() => _SequencingViewState();
}

class _SequencingViewState extends State<SequencingView> {
  final _picked = <String>[];
  var _solved = false;

  void _tap(String id) {
    if (_solved || _picked.contains(id)) return;
    final expected = widget.interaction.steps[_picked.length].id;
    if (id != expected) {
      widget.onRetry();
      return;
    }
    var done = false;
    setState(() {
      _picked.add(id);
      if (_picked.length == widget.interaction.steps.length) {
        _solved = true;
        done = true;
      }
    });
    if (done) widget.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.interaction.steps.reversed.toList();
    return ActivityChrome(
      instruction: widget.instruction,
      secondaryTitle: widget.secondaryTitle,
      feedback: widget.feedback,
      audioMissing: widget.audioMissing,
      onHome: widget.onHome,
      onBack: widget.onBack,
      onPlay: widget.onPlay,
      onPause: widget.onPause,
      onReplay: widget.onReplay,
      onReplayOther: widget.onReplayOther,
      body: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final step in shown)
            if (step.label.forLocale(widget.locale) case final label?)
              BigButton(
                key: Key('step-${step.id}'),
                label: _picked.contains(step.id) ? '$label ✓' : label,
                onPressed: _picked.contains(step.id)
                    ? null
                    : () => _tap(step.id),
              ),
        ],
      ),
    );
  }
}

class ActivityChrome extends StatelessWidget {
  const ActivityChrome({
    super.key,
    required this.instruction,
    required this.secondaryTitle,
    required this.feedback,
    required this.body,
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
  final Widget body;
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
              body,
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
