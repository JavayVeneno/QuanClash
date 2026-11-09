import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/dashboard/widgets/dashboard_style.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tracker_list.dart';

class RequestsView extends ConsumerStatefulWidget {
  const RequestsView({super.key});

  @override
  ConsumerState<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<RequestsView> {
  final _requestsStateNotifier = ValueNotifier<TrackerInfosState>(
    const TrackerInfosState(),
  );
  List<TrackerInfo> _requests = [];
  late final ScrollController _scrollController;

  void _onSearch(String value) {
    _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
      query: value,
    );
  }

  @override
  void initState() {
    super.initState();
    _requests = ref.read(requestsProvider).list;
    _scrollController = ScrollController(initialScrollOffset: double.maxFinite);
    _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
      trackerInfos: _requests,
    );
    ref.listenManual(requestsProvider.select((state) => VM(state.list)), (
      prev,
      next,
    ) {
      _requests = next.a;
      updateRequestsThrottler();
    });
  }

  @override
  void dispose() {
    _requestsStateNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void updateRequestsThrottler() {
    throttler.call(FunctionTag.requests, () {
      if (!mounted) {
        return;
      }
      final isEquality = trackerInfoListEquality.equals(
        _requests,
        _requestsStateNotifier.value.trackerInfos,
      );
      if (isEquality) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
            trackerInfos: _requests,
          );
        }
      });
    }, duration: commonDuration);
  }

  void _toggleAutoScroll() {
    _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
      autoScrollToEnd: !_requestsStateNotifier.value.autoScrollToEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final surface = DashboardPalette.surface(context);
    final quanX = context.quanX;
    return CommonScaffold(
      hideAppBar: true,
      hideTitle: true,
      title: appLocalizations.requests,
      backgroundColor: surface,
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _requestsStateNotifier,
        builder: (context, state, _) {
          return Column(
            children: [
              PageSearchToolbar(
                query: state.query,
                onQueryChanged: _onSearch,
                actions: [
                  IconButton(
                    tooltip: appLocalizations.autoScroll,
                    onPressed: _toggleAutoScroll,
                    icon: Icon(
                      state.autoScrollToEnd
                          ? QuanXIcons.ban
                          : QuanXIcons.arrowUpToLine,
                    ),
                  ),
                ],
              ),
              Divider(height: 1, color: quanX.separator),
              Expanded(
                child: TrackerInfoList(
                  items: state.list,
                  controller: _scrollController,
                  reverse: true,
                  autoScrollToEnd: state.autoScrollToEnd,
                  onCancelAutoScroll: () {
                    _requestsStateNotifier.value = _requestsStateNotifier.value
                        .copyWith(autoScrollToEnd: false);
                  },
                  detailTitle: appLocalizations.details(
                    appLocalizations.request,
                  ),
                  emptyLabel: appLocalizations.nullTip(
                    appLocalizations.requests,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
