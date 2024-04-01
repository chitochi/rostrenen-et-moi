import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rostrenen et moi'),
        scrolledUnderElevation: null,
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: location == '/create' ? 0 : 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/create');
          } else if (index == 1) {
            context.go('/drafts');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.create),
            label: 'Signaler une anomalie',
          ),
          NavigationDestination(
            icon: Icon(Icons.pending),
            label: 'Brouillons',
          )
        ],
      ),
    );
  }
}
