import 'package:quanclash/common/common.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 移动端的「更多」页：设置已迁移到独立的设置页。
class ToolsView extends ConsumerStatefulWidget {
  const ToolsView({super.key});

  @override
  ConsumerState<ToolsView> createState() => _ToolViewState();
}

class _ToolViewState extends ConsumerState<ToolsView> {
  Widget _buildNavigationMenuItem(NavigationItem navigationItem) {
    return ListItem.open(
      leading: navigationItem.icon,
      title: Text(Intl.message(navigationItem.label.name)),
      subtitle: navigationItem.description != null
          ? Text(Intl.message(navigationItem.description!))
          : null,
      delegate: OpenDelegate(
        widget: navigationItem.builder(context),
        maxWidth: 400,
        forceFull: false,
      ),
    );
  }

  Widget _buildNavigationMenu(List<NavigationItem> navigationItems) {
    return Column(
      children: [
        for (final navigationItem in navigationItems) ...[
          _buildNavigationMenuItem(navigationItem),
          if (navigationItems.last != navigationItem)
            const Divider(height: 0)
          else
            const SizedBox.shrink(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      hideTitle: true,
      title: context.appLocalizations.tools,
      body: ListView(
        key: toolsStoreKey,
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Consumer(
            builder: (_, ref, _) {
              final state = ref.watch(moreToolsSelectorStateProvider);
              if (state.navigationItems.isEmpty) {
                return NullStatus(
                  label: context.appLocalizations.nullTip(
                    context.appLocalizations.tools,
                  ),
                );
              }
              return Column(
                children: [
                  ListHeader(title: context.appLocalizations.more),
                  _buildNavigationMenu(state.navigationItems),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
