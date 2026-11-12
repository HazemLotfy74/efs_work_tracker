import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../notifications/presentation/inbox_cubit.dart';

/// Shell with the bottom navigation bar: Home, History, Alerts, Profile.
class MainLayoutView extends StatelessWidget {
  const MainLayoutView({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<InboxCubit?>();
    final unread = inbox?.state.unread ?? 0;
    Widget alertIcon(IconData icon) => Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: Icon(icon),
    );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) inbox?.refresh();
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_outlined),
            label: context.l10n.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_outlined),
            label: context.l10n.history,
          ),
          NavigationDestination(
            icon: alertIcon(Icons.notifications_outlined),
            selectedIcon: alertIcon(Icons.notifications_rounded),
            label: context.l10n.alerts,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: context.l10n.profile,
          ),
        ],
      ),
    );
  }
}
