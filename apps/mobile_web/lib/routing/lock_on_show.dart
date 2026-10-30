import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routing/providers.dart';

class LockOnShow extends ConsumerStatefulWidget {
  const LockOnShow({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockOnShow> createState() => _LockOnShowState();
}

class _LockOnShowState extends ConsumerState<LockOnShow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(parentGateProvider.notifier).lock();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
