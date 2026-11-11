import 'dart:async';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/controller.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/dashboard/widgets/dashboard_style.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tracker_list.dart';

class ConnectionsView extends ConsumerStatefulWidget {
  const ConnectionsView({super.key});

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView>
    with WidgetsBindingObserver {
  final _connectionsStateNotifier = ValueNotifier<TrackerInfosState>(
    const TrackerInfosState(),
  );

  Timer? timer;
  bool _active = false;
  bool _updating = false;

  void _onSearch(String value) {
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      query: value,
    );
  }

  Future<void> _updateConnectionsTask() async {
    timer?.cancel();
    if (!mounted || !_active) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_active) {
        return;
      }
      try {
        await _updateConnections();
      } catch (_) {
        // Keep the next tick scheduled; a stopped core can recover.
      }
      if (!mounted || !_active) {
        return;
      }
      timer = Timer(const Duration(seconds: 1), _updateConnectionsTask);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _active = ref.read(currentPageLabelProvider) == PageLabel.connections;
    ref.listenManual(currentPageLabelProvider, (prev, next) {
      final active = next == PageLabel.connections;
      if (active == _active) {
        return;
      }
      _active = active;
      if (active) {
        _updateConnectionsTask();
      } else {
        timer?.cancel();
        timer = null;
      }
    });
    if (_active) {
      _updateConnectionsTask();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_active) {
        _updateConnectionsTask();
      }
      return;
    }
    timer?.cancel();
    timer = null;
  }

  Future<void> _updateConnections() async {
    if (_updating) {
      return;
    }
    _updating = true;
    try {
      final infos = await coreController.getConnections();
      if (!mounted) {
        return;
      }
      _connectionsStateNotifier.value = _connectionsStateNotifier.value
          .copyWith(trackerInfos: infos);
    } finally {
      _updating = false;
    }
  }

  Future<void> _handleCloseAll() async {
    coreController.closeConnections();
    await _updateConnections();
  }

  Future<void> _handleBlockConnection(String id) async {
    await coreController.closeConnection(id);
    await _updateConnections();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    _connectionsStateNotifier.dispose();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final surface = DashboardPalette.surface(context);
    final quanX = context.quanX;
    return CommonScaffold(
      hideAppBar: true,
      hideTitle: true,
      title: appLocalizations.connections,
      backgroundColor: surface,
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _connectionsStateNotifier,
        builder: (context, state, _) {
          return Column(
            children: [
              PageSearchToolbar(
                query: state.query,
                onQueryChanged: _onSearch,
                actions: [
                  IconButton(
                    tooltip: appLocalizations.closeAllConnections,
                    onPressed: _handleCloseAll,
                    icon: const Icon(QuanXIcons.trash2),
                  ),
                ],
              ),
              Divider(height: 1, color: quanX.separator),
              Expanded(
                child: TrackerInfoList(
                  items: state.list,
                  detailTitle: appLocalizations.details(
                    appLocalizations.connection,
                  ),
                  emptyLabel: appLocalizations.nullTip(
                    appLocalizations.connections,
                  ),
                  emptyIllustration: const ConnectionEmptyIllustration(),
                  onBlock: _handleBlockConnection,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
