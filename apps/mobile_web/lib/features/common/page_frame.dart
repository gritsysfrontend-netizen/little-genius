import 'package:flutter/material.dart';

import '../../content/widgets.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.onBack, this.onHome});

  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (onHome != null) ChildBar(onBack: onBack, onHome: onHome!),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
