enum DnsDiagnosticStatus { ready, disabled, inactive, notConfigured, unknown }

enum DnsRoutePath {
  direct,
  rules,
  proxy,
  interface,
  system,
  dhcp,
  overlay,
  synthetic,
  blocked,
  unknown,
}

class DnsRouteDiagnostic {
  final String role;
  final int? policyIndex;
  final int serverIndex;
  final String endpoint;
  final String transport;
  final DnsRoutePath path;
  final String? target;

  const DnsRouteDiagnostic({
    required this.role,
    required this.policyIndex,
    required this.serverIndex,
    required this.endpoint,
    required this.transport,
    required this.path,
    required this.target,
  });

  factory DnsRouteDiagnostic.fromJson(Map<String, dynamic> json) {
    final pathValue = json['path'] as String;
    return DnsRouteDiagnostic(
      role: json['role'] as String,
      policyIndex: json['policyIndex'] as int?,
      serverIndex: json['serverIndex'] as int,
      endpoint: json['endpoint'] as String,
      transport: json['transport'] as String,
      path: DnsRoutePath.values.firstWhere(
        (path) => path.name == pathValue,
        orElse: () => DnsRoutePath.unknown,
      ),
      target: json['target'] as String?,
    );
  }
}

// This is a configuration-path snapshot, not a measured DNS leak verdict.
// Keep wire validation here, independent of the eventual diagnostics UI.
class DnsDiagnostic {
  final int schemaVersion;
  final DnsDiagnosticStatus status;
  final String proxyBootstrap;
  final String directQueries;
  final bool directFollowPolicy;
  final List<DnsRouteDiagnostic> routes;
  final List<String> warnings;

  DnsDiagnostic._({
    required this.schemaVersion,
    required this.status,
    required this.proxyBootstrap,
    required this.directQueries,
    required this.directFollowPolicy,
    required List<DnsRouteDiagnostic> routes,
    required List<String> warnings,
  }) : routes = List.unmodifiable(routes),
       warnings = List.unmodifiable(warnings);

  factory DnsDiagnostic.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 || json['source'] != 'active-config') {
      throw const FormatException(
        'Unsupported DNS diagnostic schema or source',
      );
    }
    return DnsDiagnostic._(
      schemaVersion: json['schemaVersion'] as int,
      status: switch (json['status'] as String) {
        'ready' => DnsDiagnosticStatus.ready,
        'disabled' => DnsDiagnosticStatus.disabled,
        'inactive' => DnsDiagnosticStatus.inactive,
        'not-configured' => DnsDiagnosticStatus.notConfigured,
        _ => DnsDiagnosticStatus.unknown,
      },
      proxyBootstrap: json['proxyBootstrap'] as String,
      directQueries: json['directQueries'] as String,
      directFollowPolicy: json['directFollowPolicy'] as bool,
      routes: (json['routes'] as List)
          .map(
            (item) => DnsRouteDiagnostic.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      warnings: List<String>.from(json['warnings'] as List),
    );
  }
}
