import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/views/dashboard/widgets/dashboard_style.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 连接 / 请求页的全宽列表。
class TrackerInfoList extends StatefulWidget {
  final List<TrackerInfo> items;
  final String detailTitle;
  final String emptyLabel;
  final Widget? emptyIllustration;
  final ScrollController? controller;
  final bool reverse;
  final bool autoScrollToEnd;
  final VoidCallback? onCancelAutoScroll;
  final ValueChanged<String>? onBlock;

  const TrackerInfoList({
    super.key,
    required this.items,
    required this.detailTitle,
    required this.emptyLabel,
    this.emptyIllustration,
    this.controller,
    this.reverse = false,
    this.autoScrollToEnd = true,
    this.onCancelAutoScroll,
    this.onBlock,
  });

  @override
  State<TrackerInfoList> createState() => _TrackerInfoListState();
}

class _TrackerInfoListState extends State<TrackerInfoList> {
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
        final trackerInfo = widget.items[index];
        return TrackerInfoRow(
          key: ValueKey(trackerInfo.id),
          trackerInfo: trackerInfo,
          onBlock: widget.onBlock,
          onTap: () {
            showTrackerInfoDetail(context, trackerInfo, widget.detailTitle);
          },
        );
      },
    );
    if (widget.reverse) {
      list = ScrollToEndBox<TrackerInfo>(
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

/// 48px 的全宽连接 / 请求行。
class TrackerInfoRow extends StatefulWidget {
  final TrackerInfo trackerInfo;
  final ValueChanged<String>? onBlock;
  final VoidCallback onTap;

  const TrackerInfoRow({
    super.key,
    required this.trackerInfo,
    required this.onTap,
    this.onBlock,
  });

  @override
  State<TrackerInfoRow> createState() => _TrackerInfoRowState();
}

class _TrackerInfoRowState extends State<TrackerInfoRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final trackerInfo = widget.trackerInfo;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final hoverColor = isDark
        ? DashboardPalette.primary.withValues(alpha: 0.16)
        : const Color(0xFFF5F3FF);
    final metadata = trackerInfo.metadata;
    final host = metadata.host;
    final ip = metadata.destinationIP;
    final port = metadata.destinationPort;
    final destination = ip.isEmpty
        ? ''
        : '$ip${port.isEmpty ? '' : ':$port'}';
    final title = host.isNotEmpty
        ? host
        : (ip.isNotEmpty ? ip : trackerInfo.desc);
    final subtitle = host.isNotEmpty
        ? destination
        : [
            if (port.isNotEmpty) port,
            if (metadata.network.isNotEmpty) metadata.network,
          ].join(' · ');
    final process = metadata.process;
    final chains = trackerInfo.chains;
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
              border: Border(
                bottom: BorderSide(color: quanX.separator),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: quanX.textPrimary,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            color: quanX.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: quanX.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          QuanXIcons.monitor,
                          size: 13,
                          color: quanX.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          process.isEmpty ? '—' : process,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: quanX.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            for (final chain in chains.take(3))
                              _RowTag(label: chain),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TrafficInfo(
                        upload: trackerInfo.upload,
                        download: trackerInfo.download,
                      ),
                    ],
                  ),
                ),
                if (widget.onBlock != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: () => widget.onBlock!(trackerInfo.id),
                      icon: const Icon(QuanXIcons.ban),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      color: quanX.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowTag extends StatelessWidget {
  final String label;

  const _RowTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: quanX.surfaceElevated,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelSmall?.copyWith(
          fontSize: 9.5,
          color: quanX.textSecondary,
        ),
      ),
    );
  }
}

class _TrafficInfo extends StatelessWidget {
  final int upload;
  final int download;

  const _TrafficInfo({required this.upload, required this.download});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final style = context.textTheme.labelSmall?.copyWith(
      fontFamily: 'JetBrainsMono',
      fontSize: 10,
      color: quanX.textSecondary,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(QuanXIcons.arrowUp, size: 10, color: quanX.textTertiary),
        const SizedBox(width: 1),
        Text(upload.traffic.show, style: style),
        const SizedBox(width: 6),
        Icon(QuanXIcons.arrowDown, size: 10, color: quanX.textTertiary),
        const SizedBox(width: 1),
        Text(download.traffic.show, style: style),
      ],
    );
  }
}

Future<void> showTrackerInfoDetail(
  BuildContext context,
  TrackerInfo trackerInfo,
  String detailTitle,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: detailTitle,
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
          Center(
            child: _TrackerInfoModal(
              trackerInfo: trackerInfo,
              detailTitle: detailTitle,
            ),
          ),
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

class _DetailFieldData {
  final String label;
  final String value;
  final bool full;

  const _DetailFieldData(this.label, this.value, {this.full = false});
}

class _TrackerInfoModal extends StatelessWidget {
  final TrackerInfo trackerInfo;
  final String detailTitle;

  const _TrackerInfoModal({
    required this.trackerInfo,
    required this.detailTitle,
  });

  String get _host => trackerInfo.metadata.host;

  String get _destination {
    final ip = trackerInfo.metadata.destinationIP;
    final port = trackerInfo.metadata.destinationPort;
    if (ip.isEmpty) {
      return '';
    }
    return '$ip${port.isEmpty ? '' : ':$port'}';
  }

  String get _source {
    final ip = trackerInfo.metadata.sourceIP;
    final port = trackerInfo.metadata.sourcePort;
    if (ip.isEmpty) {
      return '';
    }
    return '$ip${port.isEmpty ? '' : ':$port'}';
  }

  String get _process {
    final process = trackerInfo.metadata.process;
    final uid = trackerInfo.metadata.uid;
    if (uid != 0) {
      return '$process($uid)';
    }
    return process;
  }

  String get _rule {
    final payload = trackerInfo.rulePayload;
    if (payload.isNotEmpty) {
      return '${trackerInfo.rule}($payload)';
    }
    return trackerInfo.rule;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final surface = DashboardPalette.surface(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final network = trackerInfo.metadata.network;
    final capsule = network.isNotEmpty
        ? network.toUpperCase()
        : detailTitle;
    final title = _host.isNotEmpty
        ? _host
        : (_destination.isNotEmpty ? _destination : trackerInfo.desc);
    final subtitle = [
      if (_destination.isNotEmpty) _destination,
      if (network.isNotEmpty) network.toUpperCase(),
    ].join(' · ');
    final networkFields = <_DetailFieldData>[
      if (_host.isNotEmpty) _DetailFieldData(l10n.host, _host, full: true),
      if (_destination.isNotEmpty)
        _DetailFieldData(l10n.destination, _destination),
      if (network.isNotEmpty)
        _DetailFieldData(l10n.networkType, network),
      if (_rule.isNotEmpty) _DetailFieldData(l10n.rule, _rule, full: true),
      if (_process.isNotEmpty) _DetailFieldData(l10n.process, _process),
      if (_source.isNotEmpty) _DetailFieldData(l10n.source, _source),
      _DetailFieldData(l10n.creationTime, trackerInfo.start.showFull, full: true),
    ];
    final trafficFields = <_DetailFieldData>[
      _DetailFieldData(l10n.upload, trackerInfo.upload.traffic.show),
      _DetailFieldData(l10n.download, trackerInfo.download.traffic.show),
      if (trackerInfo.uploadSpeed != null)
        _DetailFieldData(
          l10n.uploadSpeed,
          '${trackerInfo.uploadSpeed!.traffic.show}/s',
        ),
      if (trackerInfo.downloadSpeed != null)
        _DetailFieldData(
          l10n.downloadSpeed,
          '${trackerInfo.downloadSpeed!.traffic.show}/s',
        ),
    ];
    final copyText = [
      for (final field in [...networkFields, ...trafficFields])
        '${field.label}: ${field.value}',
      if (trackerInfo.chains.isNotEmpty)
        '${l10n.proxyChains}: ${trackerInfo.chains.join(' -> ')}',
    ].join('\n');
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
                  _Capsule(label: capsule),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10.5,
                        color: quanX.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: quanX.separator),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailGroup(
                        title: l10n.network,
                        icon: QuanXIcons.globe,
                        fields: networkFields,
                      ),
                      _DetailGroup(
                        title: l10n.traffic,
                        icon: QuanXIcons.chartLine,
                        fields: trafficFields,
                      ),
                      if (trackerInfo.chains.isNotEmpty)
                        _ChainSection(
                          chains: trackerInfo.chains,
                          title: l10n.proxyChains,
                        ),
                    ],
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
                    await Clipboard.setData(ClipboardData(text: copyText));
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

class _Capsule extends StatelessWidget {
  final String label;

  const _Capsule({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardPalette.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelSmall?.copyWith(
          color: DashboardPalette.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_DetailFieldData> fields;

  const _DetailGroup({
    required this.title,
    required this.icon,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }
    final quanX = context.quanX;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: quanX.textTertiary),
              const SizedBox(width: 6),
              Text(
                title,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: quanX.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final half = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: field.full ? constraints.maxWidth : half,
                      child: _DetailField(data: field),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final _DetailFieldData data;

  const _DetailField({required this.data});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.label,
          style: context.textTheme.labelSmall?.copyWith(
            fontSize: 9.5,
            color: quanX.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.value,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: quanX.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ChainSection extends StatelessWidget {
  final List<String> chains;
  final String title;

  const _ChainSection({required this.chains, required this.title});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: DashboardPalette.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DashboardPalette.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: quanX.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < chains.length; i++) ...[
                if (i != 0)
                  Icon(
                    QuanXIcons.chevronRight,
                    size: 12,
                    color: quanX.textTertiary,
                  ),
                _ChainTag(label: chains[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChainTag extends StatelessWidget {
  final String label;

  const _ChainTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DashboardPalette.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: DashboardPalette.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
