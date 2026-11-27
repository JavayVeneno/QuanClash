import 'package:flutter/material.dart';
import 'package:quanclash/common/common.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:quanclash/widgets/widgets.dart';

class ChainNodeInfo {
  const ChainNodeInfo({
    required this.name,
    required this.protocol,
    required this.isProvider,
    this.server,
    this.port,
    this.supportsUdp = false,
    this.isQuic = false,
    this.existingDialer,
    this.providerName,
    this.delay,
    this.fullChainDelay,
    this.qualityProxyName,
    this.occupancies = const [],
  });

  final String name;
  final String protocol;
  final bool isProvider;
  final String? server;
  final int? port;
  final bool supportsUdp;
  final bool isQuic;
  final String? existingDialer;
  final String? providerName;
  final int? delay;
  final int? fullChainDelay;
  final String? qualityProxyName;
  final List<String> occupancies;
}

/// Centered modal dialog showing node details (matches QuanXDialog style).
Future<void> showChainNodeDrawer(
  BuildContext context,
  ChainNodeInfo info,
) {
  final quanX = context.quanX;
  final l10n = context.appLocalizations;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return QuanXDialog(
        icon: QuanXIcons.server,
        color: quanX.accent,
        title: info.name,
        subtitle: info.protocol.toUpperCase(),
        maxWidth: 420,
        maxHeight: 480,
        actions: [
          if (!info.isProvider)
            OutlinedButton.icon(
              icon: const Icon(QuanXIcons.shield, size: 15),
              label: Text(l10n.nodeQualityTitle),
              onPressed: () {
                final targetName = info.qualityProxyName ?? info.name;
                Navigator.of(dialogContext).pop();
                showDialog<void>(
                  context: context,
                  builder: (_) => NodeQualityDialog(proxyName: targetName),
                );
              },
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.confirm),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (info.isProvider) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quanX.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.proxyChainProviderStrictTip,
                    style: TextStyle(fontSize: 12, color: quanX.warning),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _InfoSection(
                children: [
                  _InfoRow(
                    label: l10n.proxyType,
                    value: info.protocol.toUpperCase(),
                  ),
                  if (info.server != null)
                    _InfoRow(
                      label: l10n.address,
                      value: info.port != null
                          ? '${info.server}:${info.port}'
                          : info.server!,
                    ),
                  _InfoRow(
                    label: 'UDP',
                    value: info.supportsUdp ? '✓' : '✕',
                    valueColor: info.supportsUdp
                        ? quanX.success
                        : quanX.textTertiary,
                  ),
                  _InfoRow(
                    label: 'QUIC',
                    value: info.isQuic ? '✓' : '—',
                    valueColor: info.isQuic
                        ? quanX.warning
                        : quanX.textTertiary,
                  ),
                  if (info.existingDialer != null)
                    _InfoRow(
                      label: 'dialer-proxy',
                      value: info.existingDialer!,
                      valueColor: quanX.warning,
                    ),
                  if (info.delay != null && info.delay! > 0)
                    _InfoRow(
                      label: l10n.delay,
                      value: '${info.delay} ms',
                      valueColor: quanX.success,
                    ),
                  if (info.fullChainDelay != null && info.fullChainDelay! > 0)
                    _InfoRow(
                      label: '${l10n.proxyChains} ${l10n.delay}',
                      value: '${info.fullChainDelay} ms',
                      valueColor: quanX.accent,
                    ),
                ],
              ),
              if (info.occupancies.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final occ in info.occupancies)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: quanX.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          occ,
                          style: TextStyle(
                            fontSize: 11,
                            color: quanX.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quanX.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: quanX.separator),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: quanX.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? quanX.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
