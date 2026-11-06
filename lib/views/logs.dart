import 'dart:ui' as ui;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/dashboard_style.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogsView extends ConsumerStatefulWidget {
  const LogsView({super.key});

  @override
  ConsumerState<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends ConsumerState<LogsView> {
  final _logsStateNotifier = ValueNotifier<LogsState>(const LogsState());
  late ScrollController _scrollController;

  List<Log> _logs = [];

  @override
  void initState() {
    super.initState();
    _logs = ref.read(logsProvider).list;
    _scrollController = ScrollController(initialScrollOffset: double.maxFinite);
    _logsStateNotifier.value = _logsStateNotifier.value.copyWith(logs: _logs);
    ref.listenManual(logsProvider.select((state) => VM(state.list)), (
      prev,
      next,
    ) {
      if (prev != next) {
        final isEquality = logListEquality.equals(prev?.a, next.a);
        if (!isEquality) {
          _logs = next.a;
          updateLogsThrottler();
        }
      }
    });
  }

  void _onSearch(String value) {
    _logsStateNotifier.value = _logsStateNotifier.value.copyWith(query: value);
  }

  @override
  void dispose() {
    _logsStateNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.safeRun<bool>(() async {
      return globalState.container.read(logsProvider.notifier).exportLogs();
    }, title: appLocalizations.exportLogs);
    if (res != true) return;
    globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.exportSuccess),
    );
  }

  void _toggleAutoScroll() {
    _logsStateNotifier.value = _logsStateNotifier.value.copyWith(
      autoScrollToEnd: !_logsStateNotifier.value.autoScrollToEnd,
    );
  }

  void updateLogsThrottler() {
    throttler.call(FunctionTag.logs, () {
      if (!mounted) {
        return;
      }
      final isEquality = logListEquality.equals(
        _logs,
        _logsStateNotifier.value.logs,
      );
      if (isEquality) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _logsStateNotifier.value = _logsStateNotifier.value.copyWith(
            logs: _logs,
          );
        }
      });
    }, duration: commonDuration);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final surface = DashboardPalette.surface(context);
    final quanX = context.quanX;
    return CommonScaffold(
      hideAppBar: true,
      hideTitle: true,
      title: appLocalizations.logs,
      backgroundColor: surface,
      body: ValueListenableBuilder<LogsState>(
        valueListenable: _logsStateNotifier,
        builder: (context, state, _) {
          return Column(
            children: [
              PageSearchToolbar(
                query: state.query,
                onQueryChanged: _onSearch,
                actions: [
                  IconButton(
                    tooltip: appLocalizations.exportLogs,
                    onPressed: _handleExport,
                    icon: const Icon(QuanXIcons.save),
                  ),
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
                child: LogList(
                  items: state.list,
                  controller: _scrollController,
                  reverse: true,
                  autoScrollToEnd: state.autoScrollToEnd,
                  onCancelAutoScroll: () {
                    _logsStateNotifier.value = _logsStateNotifier.value
                        .copyWith(autoScrollToEnd: false);
                  },
                  emptyLabel: appLocalizations.nullTip(appLocalizations.logs),
                  emptyIllustration: const LogEmptyIllustration(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 全宽日志列表，行样式与连接/请求页一致。
class LogList extends StatefulWidget {
  final List<Log> items;
  final String emptyLabel;
  final Widget? emptyIllustration;
  final ScrollController? controller;
  final bool reverse;
  final bool autoScrollToEnd;
  final VoidCallback? onCancelAutoScroll;

  const LogList({
    super.key,
    required this.items,
    required this.emptyLabel,
    this.emptyIllustration,
    this.controller,
    this.reverse = false,
    this.autoScrollToEnd = true,
    this.onCancelAutoScroll,
  });

  @override
  State<LogList> createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  late final ScrollController _listController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _listController = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _listController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyIllustration == null
          ? NullStatus(label: widget.emptyLabel)
          : NullStatus(
              label: widget.emptyLabel,
              illustration: widget.emptyIllustration!,
            );
    }
    Widget list = ListView.builder(
      controller: _listController,
      reverse: widget.reverse,
      itemExtent: 48,
      padding: EdgeInsets.zero,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final log = widget.items[index];
        return LogRow(
          key: ValueKey('${log.dateTime}-$index'),
          log: log,
          onTap: () => showLogDetail(context, log),
        );
      },
    );
    if (widget.reverse) {
      list = ScrollToEndBox<Log>(
        controller: _listController,
        dataSource: widget.items,
        enable: widget.autoScrollToEnd,
        onCancelToEnd: widget.onCancelAutoScroll,
        child: list,
      );
    }
    return CommonScrollBar(controller: _listController, child: list);
  }
}

class LogRow extends StatefulWidget {
  final Log log;
  final VoidCallback onTap;

  const LogRow({super.key, required this.log, required this.onTap});

  @override
  State<LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<LogRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final hoverColor = isDark
        ? DashboardPalette.primary.withValues(alpha: 0.16)
        : const Color(0xFFF5F3FF);
    final levelColor = _levelColor(context, log.logLevel);
    final payloadColor =
        log.logLevel.color(context) ?? quanX.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _hovered ? hoverColor : Colors.transparent,
              border: Border(bottom: BorderSide(color: quanX.separator)),
            ),
            child: Row(
              children: [
                _LevelPill(label: log.logLevel.name, color: levelColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.payload,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: payloadColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  log.dateTime,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    color: quanX.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    tooltip: context.appLocalizations.copy,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _logText(log)),
                      );
                      if (context.mounted) {
                        context.showNotifier(
                          context.appLocalizations.copySuccess,
                        );
                      }
                    },
                    icon: const Icon(QuanXIcons.copy),
                    iconSize: 15,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    color: quanX.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final String label;
  final Color color;

  const _LevelPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelSmall?.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

Color _levelColor(BuildContext context, LogLevel level) {
  final quanX = context.quanX;
  return switch (level) {
    LogLevel.info => DashboardPalette.blue,
    LogLevel.warning => DashboardPalette.orange,
    LogLevel.error => quanX.danger,
    LogLevel.debug || LogLevel.silent => quanX.textTertiary,
  };
}

String _logText(Log log) {
  return '${log.dateTime} [${log.logLevel.name}] ${log.payload}';
}

Future<void> showLogDetail(BuildContext context, Log log) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: log.logLevel.name,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Center(child: _LogDetailModal(log: log)),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _LogDetailModal extends StatelessWidget {
  final Log log;

  const _LogDetailModal({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final surface = DashboardPalette.surface(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final levelColor = _levelColor(context, log.logLevel);
    final payloadColor = log.logLevel.color(context) ?? quanX.textPrimary;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DashboardPalette.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      log.logLevel.name.toUpperCase(),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: DashboardPalette.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(QuanXIcons.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Icon(
                    QuanXIcons.clock,
                    size: 13,
                    color: quanX.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    log.dateTime,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10.5,
                      color: quanX.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: levelColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: quanX.separator),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: SelectionArea(
                  child: Text(
                    log.payload,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: payloadColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: quanX.separator),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _logText(log)),
                    );
                    if (context.mounted) {
                      context.showNotifier(l10n.copySuccess);
                    }
                  },
                  icon: const Icon(QuanXIcons.copy, size: 15),
                  label: Text(l10n.copyInfo),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: quanX.textSecondary,
                    side: BorderSide(color: quanX.separator),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
