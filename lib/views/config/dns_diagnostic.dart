import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/dns_diagnostic.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DnsDiagnosticItem extends StatelessWidget {
  const DnsDiagnosticItem({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    return ListItem.open(
      leading: const Icon(Icons.manage_search_outlined),
      title: Text(l10n.dnsDiagnosticTitle),
      subtitle: Text(l10n.dnsDiagnosticDescription),
      delegate: const OpenDelegate(blur: false, widget: DnsDiagnosticPage()),
    );
  }
}

class DnsDiagnosticPage extends ConsumerStatefulWidget {
  const DnsDiagnosticPage({super.key, this.loadDiagnostic});

  // Keep the platform facade as the production boundary; injection permits
  // widget tests without starting a core or changing system networking.
  final Future<DnsDiagnostic> Function()? loadDiagnostic;

  @override
  ConsumerState<DnsDiagnosticPage> createState() => _DnsDiagnosticPageState();
}

class _DnsDiagnosticPageState extends ConsumerState<DnsDiagnosticPage> {
  DnsDiagnostic? _diagnostic;
  DateTime? _readAt;
  bool _loading = false;
  bool _failed = false;
  int _request = 0;

  bool get _available =>
      ref.read(coreStatusProvider) == CoreStatus.connected &&
      ref.read(initProvider);

  @override
  void initState() {
    super.initState();
    ref.listenManual(coreStatusProvider, (_, _) => _refresh());
    ref.listenManual(initProvider, (_, _) => _refresh());
    // The app bumps this revision after successful config/mode updates. This
    // is event driven, not a background health check or a periodic DNS probe.
    ref.listenManual(checkIpNumProvider, (_, _) => _refresh());
    _refresh();
  }

  Future<void> _refresh() async {
    final request = ++_request;
    setState(() {
      _diagnostic = null;
      _readAt = null;
      _failed = false;
      _loading = _available;
    });
    if (!_available) {
      return;
    }
    try {
      final result =
          await (widget.loadDiagnostic ?? coreController.getDnsDiagnostic)()
              .timeout(const Duration(seconds: 5));
      if (!mounted || request != _request || !_available) {
        return;
      }
      setState(() {
        _diagnostic = result;
        _readAt = DateTime.now();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request || !_available) {
        return;
      }
      // Never render a raw IPC/schema exception: it may contain config data.
      // Clear the previous snapshot rather than leaving stale paths on screen.
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final diagnostic = _diagnostic;
    return BaseScaffold(
      title: l10n.dnsDiagnosticTitle,
      actions: [
        IconButton(
          key: const ValueKey('dns-diagnostic-refresh'),
          tooltip: l10n.dnsDiagnosticRefresh,
          onPressed: _loading || !_available ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ListView(
        children: [
          ListItem(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.dnsDiagnosticScope),
            subtitle: Text(l10n.dnsDiagnosticLimitations),
          ),
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.loading),
                ],
              ),
            )
          else if (_failed)
            ListItem(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text(l10n.dnsDiagnosticUnavailable),
              subtitle: Text(l10n.dnsDiagnosticRetryHint),
            )
          else if (diagnostic == null)
            ListItem(
              title: Text(l10n.dnsDiagnosticInactive),
              subtitle: Text(l10n.dnsDiagnosticInactiveHint),
            )
          else ...[
            ListItem(
              title: Text(_statusLabel(l10n, diagnostic.status)),
              subtitle: Text(l10n.dnsDiagnosticReadAt(_readAt!.showFull)),
            ),
            if (diagnostic.status == DnsDiagnosticStatus.ready) ...[
              ListItem(
                title: Text(l10n.dnsDiagnosticInheritance),
                subtitle: Text(
                  [
                    '${l10n.proxyNameserver}: ${_inheritance(l10n, diagnostic.proxyBootstrap)}',
                    '${l10n.dnsDiagnosticDirect}: ${_inheritance(l10n, diagnostic.directQueries)}',
                    'direct-nameserver-follow-policy: ${diagnostic.directFollowPolicy}',
                  ].join('\n'),
                ),
              ),
              ..._routeSections(l10n, diagnostic.routes),
            ],
            ...generateSection(
              title: l10n.dnsDiagnosticWarnings,
              items: [
                for (final warning in diagnostic.warnings.toSet())
                  ListItem(
                    title: Text(_warningLabel(l10n, warning)),
                    subtitle: Text(warning),
                  ),
                if (diagnostic.warnings.isEmpty)
                  ListItem(title: Text(l10n.dnsDiagnosticNoWarnings)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

List<Widget> _routeSections(
  AppLocalizations l10n,
  List<DnsRouteDiagnostic> routes,
) {
  const bootstrapRoles = {
    'default-nameserver',
    'proxy-server-nameserver',
    'proxy-server-nameserver-policy',
  };
  final sections = <String, List<DnsRouteDiagnostic>>{
    l10n.dnsDiagnosticOrdinary: [],
    l10n.dnsDiagnosticBootstrap: [],
    l10n.dnsDiagnosticDirect: [],
    l10n.unknown: [],
  };
  for (final route in routes) {
    final section = switch (route.role) {
      'nameserver' ||
      'fallback' ||
      'nameserver-policy' => l10n.dnsDiagnosticOrdinary,
      'direct-nameserver' => l10n.dnsDiagnosticDirect,
      _ =>
        bootstrapRoles.contains(route.role)
            ? l10n.dnsDiagnosticBootstrap
            : l10n.unknown,
    };
    sections[section]!.add(route);
  }
  return [
    for (final section in sections.entries)
      if (section.value.isNotEmpty || section.key != l10n.unknown)
        ...generateSection(
          title: section.key,
          items: [
            for (final route in section.value)
              ListItem(
                title: Text(
                  [
                    route.role,
                    if (route.policyIndex != null)
                      '[${route.policyIndex! + 1}]',
                    '#${route.serverIndex + 1}',
                  ].join(' '),
                ),
                subtitle: Text(
                  [
                    _pathLabel(l10n, route.path),
                    '${route.transport} / ${route.endpoint.isEmpty ? l10n.dnsDiagnosticNoEndpoint : route.endpoint}',
                    if (route.target?.isNotEmpty == true)
                      l10n.dnsDiagnosticTarget(route.target!),
                  ].join('\n'),
                ),
              ),
            if (section.value.isEmpty) ListItem(title: Text(l10n.noData)),
          ],
        ),
  ];
}

String _inheritance(AppLocalizations l10n, String value) => switch (value) {
  'dedicated' => l10n.dnsDiagnosticDedicated,
  'inherits-main' => l10n.dnsDiagnosticInheritsMain,
  _ => l10n.unknown,
};

String _statusLabel(AppLocalizations l10n, DnsDiagnosticStatus status) =>
    switch (status) {
      DnsDiagnosticStatus.ready => l10n.dnsDiagnosticReady,
      DnsDiagnosticStatus.disabled => l10n.dnsDiagnosticDisabled,
      DnsDiagnosticStatus.inactive => l10n.dnsDiagnosticInactive,
      DnsDiagnosticStatus.notConfigured => l10n.dnsDiagnosticNotConfigured,
      DnsDiagnosticStatus.unknown => l10n.unknown,
    };

String _pathLabel(AppLocalizations l10n, DnsRoutePath path) => switch (path) {
  DnsRoutePath.direct => l10n.dnsDiagnosticPathDirect,
  DnsRoutePath.rules => l10n.dnsDiagnosticPathRules,
  DnsRoutePath.proxy => l10n.dnsDiagnosticPathProxy,
  DnsRoutePath.interface => l10n.dnsDiagnosticPathInterface,
  DnsRoutePath.system => l10n.dnsDiagnosticPathSystem,
  DnsRoutePath.dhcp => l10n.dnsDiagnosticPathDhcp,
  DnsRoutePath.overlay => l10n.dnsDiagnosticPathOverlay,
  DnsRoutePath.synthetic => l10n.dnsDiagnosticPathSynthetic,
  DnsRoutePath.blocked => l10n.dnsDiagnosticPathBlocked,
  DnsRoutePath.unknown => l10n.unknown,
};

String _warningLabel(AppLocalizations l10n, String code) => switch (code) {
  'configuration-only-not-a-leak-test' => l10n.dnsDiagnosticScope,
  'host-dns-path-present' => l10n.dnsDiagnosticWarningHost,
  'rules-may-select-direct' => l10n.dnsDiagnosticWarningRules,
  'direct-bootstrap-path-present' => l10n.dnsDiagnosticWarningBootstrap,
  'direct-query-path-present' => l10n.dnsDiagnosticWarningDirect,
  'configured-proxy-path-not-verified' => l10n.dnsDiagnosticWarningProxy,
  'unknown-dns-path' => l10n.dnsDiagnosticWarningUnknown,
  'core-dns-disabled' => l10n.dnsDiagnosticDisabled,
  _ => l10n.dnsDiagnosticWarningUnknown,
};
