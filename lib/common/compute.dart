import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';

List<Group> computeSort({
  required List<Group> groups,
  required ProxiesSortType sortType,
  required DelayMap delayMap,
  required Map<String, String> selectedMap,
  required String defaultTestUrl,
}) {
  List<Proxy> sortOfDelay({
    required List<Group> groups,
    required List<Proxy> proxies,
    required DelayMap delayMap,
    required Map<String, String> selectedMap,
    required String testUrl,
  }) {
    return List.from(proxies)..sort((a, b) {
      final aDelayState = computeProxyDelayState(
        proxyName: a.name,
        testUrl: testUrl,
        groups: groups,
        selectedMap: selectedMap,
        delayMap: delayMap,
      );
      final bDelayState = computeProxyDelayState(
        proxyName: b.name,
        testUrl: testUrl,
        groups: groups,
        selectedMap: selectedMap,
        delayMap: delayMap,
      );
      return aDelayState.compareTo(bDelayState);
    });
  }

  List<Proxy> sortOfName(List<Proxy> proxies) {
    return List.of(proxies)..sort((a, b) => a.name.compareTo(b.name));
  }

  return groups.map((group) {
    final proxies = group.all;
    final newProxies = switch (sortType) {
      ProxiesSortType.none => proxies,
      ProxiesSortType.delay => sortOfDelay(
        groups: groups,
        proxies: proxies,
        delayMap: delayMap,
        selectedMap: selectedMap,
        testUrl: group.testUrl.takeFirstValid([defaultTestUrl]),
      ),
      ProxiesSortType.name => sortOfName(proxies),
    };
    return group.copyWith(all: newProxies);
  }).toList();
}

SelectedProxyState getRealSelectedProxyState(
  SelectedProxyState state, {
  required List<Group> groups,
  required Map<String, String> selectedMap,
}) {
  if (state.proxyName.isEmpty) return state;
  final index = groups.indexWhere((element) => element.name == state.proxyName);
  final newState = state.copyWith(group: true);
  if (index == -1) return newState;
  final group = groups[index];
  final currentSelectedName = group.getCurrentSelectedName(
    selectedMap[newState.proxyName] ?? '',
  );
  if (currentSelectedName.isEmpty) {
    return newState;
  }
  return getRealSelectedProxyState(
    newState.copyWith(proxyName: currentSelectedName, testUrl: group.testUrl),
    groups: groups,
    selectedMap: selectedMap,
  );
}

SelectedProxyState computeRealSelectedProxyState(
  String proxyName, {
  required List<Group> groups,
  required Map<String, String> selectedMap,
}) {
  return getRealSelectedProxyState(
    SelectedProxyState(proxyName: proxyName),
    groups: groups,
    selectedMap: selectedMap,
  );
}

/// Pseudo-proxy names that never identify a dialing node.
const reservedProxyNames = {
  'DIRECT',
  'REJECT',
  'REJECT-DROP',
  'PASS',
  'COMPATIBLE',
  'RULES',
  'GLOBAL',
};

bool isReservedProxyName(String name) =>
    reservedProxyNames.contains(name.toUpperCase());

/// Pick the group whose selection best represents the node traffic uses.
///
/// mihomo always exposes a `GLOBAL` selector whose default selection is
/// `DIRECT`. Taking the first selector group therefore pinned the tray panel
/// and the risk-index probe to DIRECT even when rule mode was routing through
/// a real node. Prefer the group the user last opened, then any group whose
/// selection resolves to a real proxy.
Group? computeCurrentGroup(
  List<Group> groups, {
  String? preferredName,
  Map<String, String> selectedMap = const {},
}) {
  Group? withSelection(String? name) {
    if (name == null || name.isEmpty) {
      return null;
    }
    final group = groups.getGroup(name);
    if (group == null || (group.now?.isEmpty ?? true)) {
      return null;
    }
    return group;
  }

  bool usable(Group group) {
    final now = group.now;
    if (now == null || now.isEmpty || group.name.toUpperCase() == 'GLOBAL') {
      return false;
    }
    final state = computeRealSelectedProxyState(
      now,
      groups: groups,
      selectedMap: selectedMap,
    );
    return !isReservedProxyName(state.proxyName);
  }

  final preferred = withSelection(preferredName);
  if (preferred != null && usable(preferred)) {
    return preferred;
  }
  for (final group in groups) {
    if (group.type == GroupType.Selector && usable(group)) {
      return group;
    }
  }
  for (final group in groups) {
    if (usable(group)) {
      return group;
    }
  }
  // Nothing resolves to a real node (direct-only profile): keep the explicit
  // selection so the UI can still show what is active.
  return preferred ?? (groups.isEmpty ? null : withSelection(groups.first.name));
}

DelayState computeProxyDelayState({
  required String proxyName,
  required String testUrl,
  required List<Group> groups,
  required Map<String, String> selectedMap,
  required DelayMap delayMap,
}) {
  final state = computeRealSelectedProxyState(
    proxyName,
    groups: groups,
    selectedMap: selectedMap,
  );
  final currentDelayMap =
      delayMap[state.testUrl.takeFirstValid([testUrl])] ?? {};
  final delay = currentDelayMap[state.proxyName];
  return DelayState(delay: delay ?? 0, group: state.group);
}
