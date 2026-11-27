import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quanclash/common/common.dart';

part 'generated/proxy_chain.freezed.dart';
part 'generated/proxy_chain.g.dart';

const String chainGroupPrefix = '';
const String chainAggregateGroupName = '链式代理';

enum ChainGroupType {
  fallback,
  urlTest,
  select;

  String get yamlValue => switch (this) {
    ChainGroupType.fallback => 'fallback',
    ChainGroupType.urlTest => 'url-test',
    ChainGroupType.select => 'select',
  };
}

enum ChainFailurePolicy {
  block,
  directFallback,
}

enum ChainSourceType {
  staticNodes,
  provider,
}

@freezed
abstract class ChainHop with _$ChainHop {
  const factory ChainHop({
    @Default(ChainGroupType.fallback) ChainGroupType type,
    @Default([]) List<String> members,
    String? testUrl,
    @Default(300) int interval,
    @Default(50) int tolerance,
  }) = _ChainHop;

  factory ChainHop.fromJson(Map<String, Object?> json) =>
      _$ChainHopFromJson(json);
}

@freezed
abstract class ProxyChain with _$ProxyChain {
  const factory ProxyChain({
    required int id,
    required int profileId,
    required String name,
    @Default(true) bool enabled,
    @Default(ChainHop()) ChainHop entry,
    @Default(ChainHop()) ChainHop exit,
    @Default(ChainFailurePolicy.block) ChainFailurePolicy failurePolicy,
    @Default(ChainSourceType.staticNodes) ChainSourceType sourceType,
    @Default(0) int order,
  }) = _ProxyChain;

  factory ProxyChain.fromJson(Map<String, Object?> json) =>
      _$ProxyChainFromJson(json);

  factory ProxyChain.create({
    required int profileId,
    required String name,
    int order = 0,
  }) {
    return ProxyChain(
      id: snowflake.id,
      profileId: profileId,
      name: name,
      order: order,
    );
  }
}

extension ProxyChainExt on ProxyChain {
  String get groupName => name.trim();

  String get entryGroupName => '${name.trim()} · 入口';

  String exitCopyName(String member) {
    if (exit.members.length == 1 &&
        failurePolicy == ChainFailurePolicy.block) {
      return groupName;
    }
    return '${name.trim()} / $member';
  }
}
