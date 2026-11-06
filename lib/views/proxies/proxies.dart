import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/models/state.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/dashboard_style.dart';
import 'package:fl_clash/views/proxies/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common.dart' as proxies_common;
import 'node_quality.dart';
import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key});

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<CommonScaffoldState> _scaffoldKey = GlobalKey();
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();
  bool _hasProviders = false;

  Widget _buildSearchAction(BuildContext context) {
    return IconButton(
      tooltip: context.appLocalizations.search,
      onPressed: () {
        _scaffoldKey.currentState?.handleToSearch();
      },
      icon: const Icon(QuanXIcons.search),
    );
  }

  Widget _buildViewModeAction(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final mode = ref.watch(proxiesViewModeProvider);
    return CommonPopupBox(
      targetBuilder: (open) {
        return IconButton(
          tooltip: appLocalizations.proxiesViewMode,
          onPressed: () {
            final isMobile = ref.read(isMobileViewProvider);
            open(offset: Offset(0, isMobile ? 0 : 20));
          },
          icon: const Icon(QuanXIcons.eye),
        );
      },
      popup: CommonPopupMenu(
        minWidth: 180,
        items: [
          PopupMenuItemData(
            icon: mode == ProxiesGroupMode.all
                ? QuanXIcons.check
                : QuanXIcons.list,
            label: appLocalizations.proxiesViewAll,
            onPressed: () {
              ref
                  .read(proxiesViewModeProvider.notifier)
                  .updateMode(ProxiesGroupMode.all);
            },
          ),
          PopupMenuItemData(
            icon: mode == ProxiesGroupMode.region
                ? QuanXIcons.check
                : QuanXIcons.globe,
            label: appLocalizations.proxiesViewRegion,
            onPressed: () {
              ref
                  .read(proxiesViewModeProvider.notifier)
                  .updateMode(ProxiesGroupMode.region);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLeadingActions(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return [
      _buildSearchAction(context),
      IconButton(
        tooltip: appLocalizations.proxiesLocateSelected,
        onPressed: () {
          _proxiesTabKey.currentState?.scrollToGroupSelected();
        },
        icon: const Icon(QuanXIcons.locate),
      ),
      _buildViewModeAction(context),
      CommonPopupBox(
        targetBuilder: (open) {
          return IconButton(
            onPressed: () {
              final isMobile = ref.read(isMobileViewProvider);
              open(offset: Offset(0, isMobile ? 0 : 20));
            },
            icon: const Icon(QuanXIcons.ellipsisVertical),
          );
        },
        popup: CommonPopupMenu(
          items: [
            PopupMenuItemData(
              icon: Icons.policy_outlined,
              label: appLocalizations.nodeQualityTitle,
              onPressed: () {
                _openNodeQuality(context);
              },
            ),
            PopupMenuItemData(
              icon: QuanXIcons.slidersHorizontal,
              label: appLocalizations.settings,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const ProxiesSettingDialog(),
                );
              },
            ),
            if (_hasProviders)
              PopupMenuItemData(
                icon: QuanXIcons.listChecks,
                label: appLocalizations.providers,
                onPressed: () {
                  showExtend(
                    context,
                    builder: (_) {
                      return const ProvidersView();
                    },
                  );
                },
              ),
          ],
        ),
      ),
    ];
  }

  void _openNodeQuality(BuildContext context) {
    final groupName = proxies_common.getCurrentGroupName();
    final selectedName = groupName == null
        ? null
        : ref.read(selectedProxyNameProvider(groupName));
    final proxyName = selectedName == null || selectedName.isEmpty
        ? ''
        : ref.read(realSelectedProxyStateProvider(selectedName)).proxyName;
    if (proxyName.isEmpty) {
      globalState.showNotifier(context.appLocalizations.nodeQualityPickNode);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => NodeQualityDialog(proxyName: proxyName),
    );
  }

  Widget? _buildFAB() {
    return DelayTestButton(
      onClick: () async {
        await _proxiesTabKey.currentState?.delayTestCurrentGroup();
      },
    );
  }

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(providersProvider.select((state) => state.isNotEmpty), (
      prev,
      next,
    ) {
      if (prev != next) {
        setState(() {
          _hasProviders = next;
        });
      }
    }, fireImmediately: true);
    ref.listenManual(
      currentPageLabelProvider.select((state) => state == PageLabel.proxies),
      (prev, next) {
        if (prev != next && next == false) {
          _scaffoldKey.currentState?.handleExitSearching();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxiesType = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.type),
    );
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    final background = DashboardPalette.background(context);
    return CommonScaffold(
      hideTitle: true,
      key: _scaffoldKey,
      isLoading: isLoading,
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      appBarBackgroundColor: background,
      showAppBarDivider: false,
      floatingActionButton: _buildFAB(),
      leadingActions: _buildLeadingActions(context),
      title: context.appLocalizations.proxies,
      searchState: AppBarSearchState(onSearch: _onSearch, autoAddSearch: false),
      body: ProxiesTabView(
        key: _proxiesTabKey,
        listMode: proxiesType == ProxiesType.list,
      ),
    );
  }
}
