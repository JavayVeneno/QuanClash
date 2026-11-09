import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/providers/providers.dart' hide NetworkDetection;
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/start_button.dart';
import 'widgets/widgets.dart';

typedef _IsEditWidgetBuilder = Widget Function(bool isEdit);

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final key = GlobalKey<SuperGridState>();
  final _isEditNotifier = ValueNotifier<bool>(false);
  final _addedWidgetsNotifier = ValueNotifier<List<GridItem>>([]);

  @override
  void dispose() {
    _isEditNotifier.dispose();
    _addedWidgetsNotifier.dispose();
    super.dispose();
  }

  Widget _buildIsEdit(_IsEditWidgetBuilder builder) {
    return ValueListenableBuilder(
      valueListenable: _isEditNotifier,
      builder: (_, isEdit, _) {
        return builder(isEdit);
      },
    );
  }


  List<Widget> _buildActions(bool isEdit) {
    return [
      if (isEdit)
        ValueListenableBuilder(
          valueListenable: _addedWidgetsNotifier,
          builder: (_, addedChildren, child) {
            if (addedChildren.isEmpty) {
              return Container();
            }
            return child!;
          },
          child: IconButton(
            onPressed: () {
              _showAddWidgetsModal();
            },
            icon: const Icon(QuanXIcons.circlePlus),
          ),
        ),
      FadeRotationScaleBox(
        child: isEdit
            ? IconButton(
                key: const ValueKey(true),
                icon: const Icon(QuanXIcons.save, key: ValueKey('save-icon')),
                onPressed: _handleUpdateIsEdit,
              )
            : IconButton(
                key: const ValueKey(false),
                icon: const Icon(QuanXIcons.pencil, key: ValueKey('edit-icon')),
                onPressed: _handleUpdateIsEdit,
              ),
      ),
    ];
  }

  void _showAddWidgetsModal() {
    showSheet(
      builder: (_) {
        return ValueListenableBuilder(
          valueListenable: _addedWidgetsNotifier,
          builder: (_, value, _) {
            return AdaptiveSheetScaffold(
              body: _AddDashboardWidgetModal(
                items: value,
                onAdd: (gridItem) {
                  key.currentState?.handleAdd(gridItem);
                },
              ),
              title: context.appLocalizations.add,
            );
          },
        );
      },
      context: context,
    );
  }

  Future<void> _handleUpdateIsEdit() async {
    if (_isEditNotifier.value == true) {
      await _handleSave();
    }
    _isEditNotifier.value = !_isEditNotifier.value;
  }

  Future<void> _handleSave() async {
    final currentState = key.currentState;
    if (currentState == null) {
      return;
    }
    if (mounted && currentState.children.isNotEmpty) {
      await currentState.isTransformCompleter;
      final dashboardWidgets = currentState.children
          .map((item) => DashboardWidget.getDashboardWidget(item))
          .toList();
      ref
          .read(appSettingProvider.notifier)
          .update(
            (state) => state.copyWith(dashboardWidgets: dashboardWidgets),
          );
    }
  }

  Widget _buildDesktopView(BuildContext context) {
    const spacing = 10.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: DashboardPalette.background(context),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 运行概览
                  const ConnectionBar(),
                  const SizedBox(height: spacing),
                  // 2. 可用节点 / 覆盖地区 / 节点更新 / 稳定运行
                  const DashboardStats(),
                  const SizedBox(height: spacing),
                  // 3. 网速 7 : 流量 3
                  if (isWide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: NetworkSpeed()),
                        SizedBox(width: spacing),
                        Expanded(flex: 3, child: TrafficUsage()),
                      ],
                    )
                  else ...[
                    const NetworkSpeed(),
                    const SizedBox(height: spacing),
                    const TrafficUsage(),
                  ],
                  const SizedBox(height: spacing),
                  // 4. 系统代理 / 虚拟网卡 / 出站模式
                  if (isWide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: SystemProxyButton()),
                        SizedBox(width: spacing),
                        Expanded(child: TUNButton()),
                        SizedBox(width: spacing),
                        Expanded(flex: 2, child: OutboundModeV2()),
                      ],
                    )
                  else ...[
                    const SystemProxyButton(),
                    const SizedBox(height: spacing),
                    const TUNButton(),
                    const SizedBox(height: spacing),
                    const OutboundModeV2(),
                  ],
                  const SizedBox(height: spacing),
                  // 5. 网络检测 / 风险指数 / 内存 / 内网 IP
                  if (isWide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: NetworkDetection()),
                        SizedBox(width: spacing),
                        Expanded(child: RiskIndex()),
                        SizedBox(width: spacing),
                        Expanded(child: MemoryInfo()),
                        SizedBox(width: spacing),
                        Expanded(child: IntranetIP()),
                      ],
                    )
                  else ...[
                    const Row(
                      children: [
                        Expanded(child: NetworkDetection()),
                        SizedBox(width: spacing),
                        Expanded(child: RiskIndex()),
                      ],
                    ),
                    const SizedBox(height: spacing),
                    const Row(
                      children: [
                        Expanded(child: MemoryInfo()),
                        SizedBox(width: spacing),
                        Expanded(child: IntranetIP()),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardStateProvider);
    final columns = max(4 * ((dashboardState.contentWidth / 280).ceil()), 8);
    final spacing = 14.mAp;
    final children = [
      ...dashboardState.dashboardWidgets
          .where(
            (item) => item.platforms.contains(SupportPlatform.currentPlatform),
          )
          .map((item) => item.widget),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addedWidgetsNotifier.value = DashboardWidget.values
          .where(
            (item) =>
                !children.contains(item.widget) &&
                item.platforms.contains(SupportPlatform.currentPlatform),
          )
          .map((item) => item.widget)
          .toList();
    });
    if (system.isDesktop) {
      return _buildDesktopView(context);
    }
    return _buildIsEdit(
      (isEdit) => CommonScaffold(
        title: context.appLocalizations.dashboard,
        actions: _buildActions(isEdit),
        floatingActionButton: const StartButton(),
        body: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16).copyWith(bottom: 88),
            child: isEdit
                ? SystemBackBlock(
                    child: CommonPopScope(
                      child: SuperGrid(
                        key: key,
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        children: children,
                        onUpdate: () {
                          _handleSave();
                        },
                      ),
                      onPop: (context) {
                        _handleUpdateIsEdit();
                        return false;
                      },
                    ),
                  )
                : Grid(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    children: children,
                  ),
          ),
        ),
      ),
    );
  }
}

class _AddDashboardWidgetModal extends StatelessWidget {
  final List<GridItem> items;
  final Function(GridItem item) onAdd;

  const _AddDashboardWidgetModal({required this.items, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return DeferredPointerHandler(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Grid(
          crossAxisCount: 8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: items
              .map(
                (item) => item.wrap(
                  builder: (child) {
                    return _AddedContainer(
                      onAdd: () {
                        onAdd(item);
                      },
                      child: child,
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _AddedContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onAdd;

  const _AddedContainer({required this.child, required this.onAdd});

  @override
  State<_AddedContainer> createState() => _AddedContainerState();
}

class _AddedContainerState extends State<_AddedContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(_AddedContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {}
  }

  Future<void> _handleAdd() async {
    widget.onAdd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActivateBox(child: widget.child),
        Positioned(
          top: -8,
          right: -8,
          child: DeferPointer(
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton.filled(
                iconSize: 20,
                padding: const EdgeInsets.all(2),
                onPressed: _handleAdd,
                icon: const Icon(QuanXIcons.plus),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
