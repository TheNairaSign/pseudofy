import 'package:flutter/material.dart';
import 'package:pseudofy/widgets/app_sidebar.dart';
import 'package:pseudofy/widgets/workspace.dart';

/// IDE/playground layout: a collapsible sidebar (algorithm/paradigm
/// dropdowns + library browser) on the left, and a workspace on the right
/// with the Pseudocode/Flowchart/Code view-mode tabs on top and the problem
/// input docked at the bottom.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            AppSidebar(),
            VerticalDivider(width: 1),
            Expanded(child: MainWorkspace()),
          ],
        ),
      ),
    );
  }
}
