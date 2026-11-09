import 'dart:async';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/core.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/dashboard/widgets/dashboard_style.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef NodeQualityLoader =
    Future<NodeQualityResult> Function(
      String proxyName, {
      required bool includeIpPure,
    });

/// 节点质量结果的展示有效期。超过后卡片和仪表盘都视为「未检测」。
const nodeQualityFreshness = Duration(minutes: 10);

bool isNodeQualityFresh(NodeQualityResult result, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toUtc();
  return current.difference(result.sampledAt) <= nodeQualityFreshness;
}

/// IPPure 风险分的颜色区间：低风险绿、中风险橙、高风险红。
Color nodeRiskColor(int score) {
  if (score <= 30) {
    return DashboardPalette.green;
  }
  if (score <= 60) {
    return DashboardPalette.orange;
  }
  return const Color(0xFFE03B41);
}

class NodeQualityDialog extends ConsumerStatefulWidget {
  const NodeQualityDialog({
    super.key,
    required this.proxyName,
    this.loadQuality,
    this.cooldown,
    this.autoCloseOnSuccess = true,
  });

  final String proxyName;
  final NodeQualityLoader? loadQuality;
  final NodeQualityCooldown? cooldown;

  /// 检测成功后自动关闭对话框，让用户直接看到节点卡片上的风险徽标。
  final bool autoCloseOnSuccess;

  @override
  ConsumerState<NodeQualityDialog> createState() => _NodeQualityDialogState();
}

class _NodeQualityDialogState extends ConsumerState<NodeQualityDialog> {
  NodeQualityResult? _result;
  bool _includeIpPure = false;
  bool _loading = false;
  bool _failed = false;
  bool _timedOut = false;
  int? _cooldownSeconds;
  int _revision = 0;

  bool get _available =>
      widget.proxyName.isNotEmpty &&
      ref.read(coreStatusProvider) == CoreStatus.connected &&
      ref.read(initProvider);

  @override
  void initState() {
    super.initState();
    final cached = ref.read(
      nodeQualityResultsProvider,
    )[widget.proxyName];
    if (cached != null && isNodeQualityFresh(cached)) {
      _result = cached;
      _includeIpPure = cached.quality.riskScore != null;
    }
    ref.listenManual(coreStatusProvider, (_, _) => _invalidate());
    ref.listenManual(initProvider, (_, _) => _invalidate());
    ref.listenManual(checkIpNumProvider, (_, _) => _invalidate());
    ref.listenManual(currentProfileIdProvider, (_, _) => _invalidate());
    ref.listenManual(selectedMapProvider, (_, _) => _invalidate());
  }

  void _invalidate() {
    _revision++;
    setState(() {
      _result = null;
      _failed = false;
      _timedOut = false;
      _loading = false;
      _includeIpPure = false;
      _cooldownSeconds = null;
    });
  }

  @override
  void didUpdateWidget(covariant NodeQualityDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proxyName != widget.proxyName) {
      _invalidate();
    }
  }

  Future<void> _run() async {
    if (!_available || _loading) {
      return;
    }
    final cooldown = widget.cooldown ?? _sharedNodeQualityCooldown;
    final includeIpPure = _includeIpPure;
    final remaining = _remainingCooldown(cooldown, includeIpPure);
    if (remaining > Duration.zero) {
      setState(() {
        _cooldownSeconds = (remaining.inMilliseconds / 1000).ceil();
        _loading = false;
        _failed = false;
        _timedOut = false;
      });
      return;
    }
    final revision = ++_revision;
    final name = widget.proxyName;
    cooldown.record(name, 'cloudflare');
    if (includeIpPure) {
      cooldown.record(name, 'ippure');
    }
    setState(() {
      _result = null;
      _loading = true;
      _failed = false;
      _timedOut = false;
      _cooldownSeconds = null;
    });
    try {
      final result =
          await (widget.loadQuality ?? coreController.testNodeQuality)(
            name,
            includeIpPure: includeIpPure,
          ).timeout(const Duration(seconds: 15));
      if (!mounted || revision != _revision || !_available) {
        return;
      }
      if (!result.matchesRequest(name, includeIpPure: includeIpPure)) {
        throw const FormatException('Unexpected node quality response');
      }
      ref.read(nodeQualityResultsProvider.notifier).put(result);
      setState(() {
        _result = result;
        _loading = false;
      });
      _scheduleAutoClose(result, revision);
    } catch (error) {
      if (!mounted || revision != _revision || !_available) {
        return;
      }
      setState(() {
        _failed = true;
        _timedOut = error is TimeoutException;
        _loading = false;
      });
    }
  }

  /// 成功后短暂停留，让用户看到「探测成功」，随后关闭对话框。
  Future<void> _scheduleAutoClose(NodeQualityResult result, int revision) async {
    if (!widget.autoCloseOnSuccess) {
      return;
    }
    final score = result.quality.riskScore;
    final message = score != null
        ? '${context.appLocalizations.nodeQualityRiskScore} · $score / 100'
        : context.appLocalizations.nodeQualityOk;
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || revision != _revision) {
      return;
    }
    Navigator.of(context).pop();
    globalState.showNotifier(message);
  }

  Duration _remainingCooldown(
    NodeQualityCooldown cooldown,
    bool includeIpPure,
  ) {
    var remaining = Duration.zero;
    for (final provider in ['cloudflare', if (includeIpPure) 'ippure']) {
      final providerRemaining = cooldown.remaining(widget.proxyName, provider);
      if (providerRemaining > remaining) {
        remaining = providerRemaining;
      }
    }
    return remaining;
  }

  @override
  void dispose() {
    _revision++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final surface = DashboardPalette.surface(context);
    final result = _result;
    final maxHeight = MediaQuery.sizeOf(context).height - 96;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxHeight > 320 ? maxHeight : 320,
        ),
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
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, l10n),
              Divider(height: 1, color: quanX.separator),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildScope(context, l10n),
                      const SizedBox(height: 12),
                      _buildConsent(context, l10n),
                      const SizedBox(height: 10),
                      Text(
                        l10n.nodeQualityProbeFootprint,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: quanX.textTertiary,
                          height: 1.4,
                        ),
                      ),
                      if (_cooldownSeconds != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.nodeQualityCooldown(_cooldownSeconds!),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: quanX.warning,
                          ),
                        ),
                      ],
                      if (!_available) ...[
                        const SizedBox(height: 10),
                        _MessageBox(
                          icon: QuanXIcons.info,
                          color: quanX.warning,
                          text: l10n.nodeQualityInactive,
                        ),
                      ],
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_failed) ...[
                        const SizedBox(height: 12),
                        _MessageBox(
                          icon: QuanXIcons.circleAlert,
                          color: quanX.danger,
                          text: _timedOut
                              ? l10n.nodeQualityTimeout
                              : l10n.nodeQualityFailed,
                        ),
                      ],
                      if (result != null) ...[
                        const SizedBox(height: 16),
                        if (result.egressMismatch) ...[
                          _MessageBox(
                            icon: QuanXIcons.triangleAlert,
                            color: quanX.warning,
                            text: l10n.nodeQualityMismatch,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _ProbeCard(
                          title: 'Cloudflare',
                          status: result.network.status,
                          l10n: l10n,
                          rows: [
                            if (result.network.egressIp != null)
                              _ProbeRow(
                                label: l10n.nodeQualityEgressIp,
                                value: result.network.egressIp!,
                                mono: true,
                                selectable: true,
                              ),
                            _ProbeRow(
                              label: l10n.nodeQualityEdge,
                              value:
                                  '${result.network.colo ?? l10n.unknown} / ${result.network.country ?? l10n.unknown}',
                            ),
                            _ProbeRow(
                              label: 'TTFB',
                              value: result.network.ttfbMs == null
                                  ? l10n.unknown
                                  : '${result.network.ttfbMs} ms',
                              mono: true,
                            ),
                            _ProbeRow(
                              label: l10n.nodeQualityCloudflareScore,
                              value: l10n.nodeQualityCloudflareScoreUnavailable,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ProbeCard(
                          title: 'IPPure (Beta)',
                          status: result.quality.status,
                          l10n: l10n,
                          riskScore: result.quality.riskScore,
                          rows: [
                            if (result.quality.egressIp != null)
                              _ProbeRow(
                                label: l10n.nodeQualityEgressIp,
                                value: result.quality.egressIp!,
                                mono: true,
                                selectable: true,
                              ),
                            _ProbeRow(
                              label: l10n.nodeQualityIpType,
                              value: switch (result.quality.isResidential) {
                                true => l10n.nodeQualityResidential,
                                false => l10n.nodeQualityNonResidential,
                                null => l10n.unknown,
                              },
                            ),
                          ],
                          footer: l10n.nodeQualityScoreScope,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.nodeQualitySampledAt(
                            result.sampledAt.toLocal().showFull,
                          ),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: quanX.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: quanX.separator),
              _buildActions(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final quanX = context.quanX;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      child: Row(
        children: [
          const DashboardIconTile(
            icon: QuanXIcons.shield,
            color: DashboardPalette.primary,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nodeQualityTitle,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                EmojiText(
                  widget.proxyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: quanX.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(QuanXIcons.x),
          ),
        ],
      ),
    );
  }

  Widget _buildScope(BuildContext context, AppLocalizations l10n) {
    final quanX = context.quanX;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardPalette.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        l10n.nodeQualityScope,
        style: context.textTheme.bodySmall?.copyWith(
          color: quanX.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildConsent(BuildContext context, AppLocalizations l10n) {
    final quanX = context.quanX;
    return Material(
      color: quanX.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: quanX.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        key: const ValueKey('node-quality-consent'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(
          l10n.nodeQualityOptIn,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          l10n.nodeQualityPrivacy,
          style: context.textTheme.bodySmall?.copyWith(
            color: quanX.textTertiary,
          ),
        ),
        value: _includeIpPure,
        onChanged: _loading || !_available
            ? null
            : (value) {
                setState(() {
                  _includeIpPure = value;
                  _result = null;
                  _failed = false;
                  _timedOut = false;
                  _cooldownSeconds = null;
                });
              },
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('node-quality-run'),
            onPressed: _loading || !_available ? null : _run,
            style: FilledButton.styleFrom(
              backgroundColor: DashboardPalette.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: const RoundedSuperellipseBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(QuanXRadius.control),
                ),
              ),
            ),
            child: Text(l10n.nodeQualityRun),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.quanX.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbeRow {
  const _ProbeRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool selectable;
}

class _ProbeCard extends StatelessWidget {
  const _ProbeCard({
    required this.title,
    required this.status,
    required this.l10n,
    required this.rows,
    this.riskScore,
    this.footer,
  });

  final String title;
  final NodeQualityStatus status;
  final AppLocalizations l10n;
  final List<_ProbeRow> rows;
  final int? riskScore;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: quanX.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(status: status, l10n: l10n),
            ],
          ),
          if (riskScore != null) ...[
            const SizedBox(height: 10),
            _RiskScoreRow(score: riskScore!, l10n: l10n),
          ],
          for (final row in rows) ...[
            const SizedBox(height: 8),
            _buildRow(context, row),
          ],
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(
              footer!,
              style: context.textTheme.bodySmall?.copyWith(
                color: quanX.textTertiary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _ProbeRow row) {
    final quanX = context.quanX;
    final style = context.textTheme.bodySmall?.copyWith(
      fontFamily: row.mono ? 'JetBrainsMono' : null,
      fontWeight: FontWeight.w500,
      color: quanX.textPrimary,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            row.label,
            style: context.textTheme.bodySmall?.copyWith(
              color: quanX.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: row.selectable
              ? SelectableText(row.value, style: style)
              : Text(row.value, style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.l10n});

  final NodeQualityStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final (label, color) = switch (status) {
      NodeQualityStatus.ok => (l10n.nodeQualityStatusOk, quanX.success),
      NodeQualityStatus.timeout => (
        l10n.nodeQualityStatusTimeout,
        quanX.warning,
      ),
      NodeQualityStatus.notRequested => (
        l10n.nodeQualityNotRequested,
        quanX.textTertiary,
      ),
      NodeQualityStatus.unavailable => (
        l10n.nodeQualityStatusUnavailable,
        quanX.textTertiary,
      ),
      NodeQualityStatus.failed => (l10n.nodeQualityStatusFailed, quanX.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RiskScoreRow extends StatelessWidget {
  const _RiskScoreRow({required this.score, required this.l10n});

  final int score;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final color = nodeRiskColor(score);
    final label = score <= 30
        ? l10n.riskIndexLow
        : score <= 60
        ? l10n.riskIndexMedium
        : l10n.riskIndexHigh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                l10n.nodeQualityRiskScore,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$score',
              style: context.textTheme.titleLarge?.copyWith(
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.w700,
                height: 1,
                color: color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                ' / 100',
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final NodeQualityCooldown _sharedNodeQualityCooldown = NodeQualityCooldown();
