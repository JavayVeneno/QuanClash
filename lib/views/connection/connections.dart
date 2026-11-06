import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/dashboard/widgets/dashboard_style.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tracker_list.dart';

class ConnectionsView extends ConsumerStatefulWidget {
  const ConnectionsView({super.key});

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView> {
  final _connectionsStateNotifier = ValueNotifier<TrackerInfosState>(
    const TrackerInfosState(),
  );

  Timer? timer;

  void _onSearch(String value) {
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      query: value,
    );
  }

  Future<void> _updateConnectionsTask() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _updateConnections();
        timer = Timer(const Duration(seconds: 1), () async {
          _updateConnectionsTask();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateConnectionsTask();
  }

  Future<void> _updateConnections() async {
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      trackerInfos: await coreController.getConnections(),
    );
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
