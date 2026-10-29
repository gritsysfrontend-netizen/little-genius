import 'package:flutter/material.dart';

import '../../content/widgets.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
    this.onBack,
    this.onHome,
    this.orderedFocus = false,
  });

  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final bool orderedFocus;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        if (onHome != null)
          ChildBar(
            onBack: onBack,
            onHome: onHome!,
            backOrder: orderedFocus ? 1 : null,
            homeOrder: orderedFocus ? (onBack == null ? 1 : 2) : null,
          ),
        Expanded(child: child),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: orderedFocus
            ? FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: column,
              )
            : column,
      ),
    );
  }
}
