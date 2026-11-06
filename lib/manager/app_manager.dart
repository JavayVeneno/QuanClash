import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'window_manager.dart';

class AppStateManager extends ConsumerStatefulWidget {
  final Widget child;

  const AppStateManager({super.key, required this.child});

  @override
  ConsumerState<AppStateManager> createState() => _AppStateManagerState();
}

class _AppStateManagerState extends ConsumerState<AppStateManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(checkIpProvider, (prev, next) {
      if (prev != next && next.a && next.c) {
        ref.read(networkDetectionProvider.notifier).startCheck();
      }
    });
    ref.listenManual(configProvider, (prev, next) {
      if (prev != next) {
        globalState.container
            .read(storeActionProvider.notifier)
            .savePreferencesDebounce();
      }
    });
    ref.listenManual(needUpdateGroupsProvider, (prev, next) {
      if (prev != next) {
        globalState.container
            .read(proxiesActionProvider.notifier)
            .updateGroupsDebounce();
      }
    });
    ref.listenManual(suspendProvider, (prev, next) {
      final isStart = ref.read(isStartProvider);
      if (prev != next && isStart) {
        debouncer.call(FunctionTag.suspend, () async {
          if (next == true) {
            await coreController.stopListener();
          } else {
            await coreController.startListener();
          }
          ref.read(checkIpNumProvider.notifier).add();
        });
      }
    });
    if (system.isMacOS) {
      ref.listenManual(autoSetSystemDnsStateProvider, (prev, next) async {
        if (prev == next) {
          return;
        }
        if (next.a == true && next.b == true) {
          macOS?.updateDns(false);
        } else {
          macOS?.updateDns(true);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    commonPrint.log('$state');
    if (state == AppLifecycleState.resumed) {
      permissions.check();
      render?.resume();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ref = globalState.container;
        ref.read(setupActionProvider.notifier).tryCheckIp();
        if (system.isAndroid) {
          ref.read(coreActionProvider.notifier).tryStartCore();
        }
      });
    }
  }

  @override
  void didChangePlatformBrightness() {
    globalState.container.read(themeActionProvider.notifier).updateBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (_) {
        render?.resume();
      },
      child: widget.child,
    );
  }
}

class AppEnvManager extends StatelessWidget {
  final Widget child;

  const AppEnvManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      if (globalState.isPre) {
        return Banner(
          message: 'DEBUG',
          location: BannerLocation.topEnd,
          child: child,
        );
      }
    }
    if (globalState.isPre) {
      return Banner(
        message: 'PRE',
        location: BannerLocation.topEnd,
        child: child,
      );
    }
    return child;
  }
}

class AppTopNavContainer extends ConsumerStatefulWidget {
  final Widget child;

  const AppTopNavContainer({super.key, required this.child});

  @override
  ConsumerState<AppTopNavContainer> createState() => _AppTopNavContainerState();
}

class _AppTopNavContainerState extends ConsumerState<AppTopNavContainer> {
  void _handleToPage(PageLabel pageLabel) {
    globalState.container
        .read(currentPageLabelProvider.notifier)
        .toPage(pageLabel);
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationStateProvider);
    final navigationItems = navigationState.navigationItems;
    final isMobileView = navigationState.viewMode == ViewMode.mobile;
    if (isMobileView) {
      return widget.child;
    }
    final currentIndex = navigationState.currentIndex;
    // 最大化时导航切到左侧，否则保留顶部导航。
    final useSideNav =
        system.isDesktop && ref.watch(isMaximizedProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetWidth = useSideNav ? _sideNavWidth : 0.0;
      if (ref.read(sideWidthProvider) != targetWidth) {
        ref.read(sideWidthProvider.notifier).value = targetWidth;
      }
    });
    // 根结构保持 Row + 固定槽位，最大化切换时只替换槽位内容，
    // 避免把带 GlobalKey 的页面子树在 Column/Row 之间重新挂载。
    return Row(
      children: [
        if (useSideNav)
          _SideNavBar(
            items: navigationItems,
            currentIndex: currentIndex,
            onSelected: (index) {
              _handleToPage(navigationItems[index].label);
            },
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: Column(
            children: [
              if (!useSideNav)
                _TopNavBar(
                  items: navigationItems,
                  currentIndex: currentIndex,
                  onSelected: (index) {
                    _handleToPage(navigationItems[index].label);
                  },
                )
              else
                const SizedBox.shrink(),
              Expanded(child: ClipRect(child: widget.child)),
            ],
          ),
        ),
      ],
    );
  }
}

const _sideNavWidth = 208.0;

/// 导航选中态使用设计稿的靛蓝，避免跟随动态取色偏离 mockup。
const _navAccent = Color(0xFF6C5CE7);

class _SideNavBar extends StatelessWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _SideNavBar({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Container(
      width: _sideNavWidth,
      decoration: BoxDecoration(
        color: glass.tintStrong,
        border: Border(right: BorderSide(color: glass.divider)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _SideNavBrand(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                children: _buildItems(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionOf(BuildContext context, PageLabel label) {
    final appLocalizations = context.appLocalizations;
    return switch (label) {
      PageLabel.dashboard || PageLabel.proxies || PageLabel.profiles =>
        appLocalizations.sectionMain,
      PageLabel.tools || PageLabel.settings =>
        appLocalizations.sectionSystem,
      _ => appLocalizations.sectionMonitor,
    };
  }

  List<Widget> _buildItems(BuildContext context) {
    final children = <Widget>[];
    String? currentSection;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final section = _sectionOf(context, item.label);
      if (section != currentSection) {
        if (currentSection != null) {
          children.add(const SizedBox(height: 6));
        }
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              section,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: context.quanX.textTertiary,
              ),
            ),
          ),
        );
        currentSection = section;
      }
      children.add(
        _SideNavItem(
          icon: item.icon,
          label: Intl.message(item.label.name),
          selected: i == currentIndex,
          onPressed: () {
            onSelected(i);
          },
        ),
      );
    }
    return children;
  }
}

class _SideNavBrand extends StatelessWidget {
  const _SideNavBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppIcon(size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final foreground = selected
        ? _navAccent
        : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? _navAccent.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(size: 18, color: foreground),
                    child: icon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _TopNavBar({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: glass.tintStrong,
            border: Border(
              bottom: BorderSide(color: glass.divider),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  _TopNavItem(
                    icon: items[i].icon,
                    label: Intl.message(items[i].label.name),
                    selected: i == currentIndex,
                    onPressed: () {
                      onSelected(i);
                    },
                  ),
              ],
            ),
          ),
        );
  }
}

class _TopNavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _TopNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: selected
              ? _navAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            hoverColor: colorScheme.onSurface.opacity10,
            child: SizedBox(
              width: 112,
              height: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        size: 16,
                        color: selected
                            ? _navAccent
                            : context.quanX.textSecondary,
                      ),
                      child: icon,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? _navAccent
                              : context.quanX.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
