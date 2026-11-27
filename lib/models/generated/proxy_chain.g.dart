// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../proxy_chain.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChainHop _$ChainHopFromJson(Map<String, dynamic> json) => _ChainHop(
  type:
      $enumDecodeNullable(_$ChainGroupTypeEnumMap, json['type']) ??
      ChainGroupType.fallback,
  members:
      (json['members'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  testUrl: json['testUrl'] as String?,
  interval: (json['interval'] as num?)?.toInt() ?? 300,
  tolerance: (json['tolerance'] as num?)?.toInt() ?? 50,
);

Map<String, dynamic> _$ChainHopToJson(_ChainHop instance) => <String, dynamic>{
  'type': _$ChainGroupTypeEnumMap[instance.type]!,
  'members': instance.members,
  'testUrl': instance.testUrl,
  'interval': instance.interval,
  'tolerance': instance.tolerance,
};

const _$ChainGroupTypeEnumMap = {
  ChainGroupType.fallback: 'fallback',
  ChainGroupType.urlTest: 'urlTest',
  ChainGroupType.select: 'select',
};

_ProxyChain _$ProxyChainFromJson(Map<String, dynamic> json) => _ProxyChain(
  id: (json['id'] as num).toInt(),
  profileId: (json['profileId'] as num).toInt(),
  name: json['name'] as String,
  enabled: json['enabled'] as bool? ?? true,
  entry: json['entry'] == null
      ? const ChainHop()
      : ChainHop.fromJson(json['entry'] as Map<String, dynamic>),
  exit: json['exit'] == null
      ? const ChainHop()
      : ChainHop.fromJson(json['exit'] as Map<String, dynamic>),
  failurePolicy:
      $enumDecodeNullable(_$ChainFailurePolicyEnumMap, json['failurePolicy']) ??
      ChainFailurePolicy.block,
  sourceType:
      $enumDecodeNullable(_$ChainSourceTypeEnumMap, json['sourceType']) ??
      ChainSourceType.staticNodes,
  order: (json['order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProxyChainToJson(_ProxyChain instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profileId': instance.profileId,
      'name': instance.name,
      'enabled': instance.enabled,
      'entry': instance.entry,
      'exit': instance.exit,
      'failurePolicy': _$ChainFailurePolicyEnumMap[instance.failurePolicy]!,
      'sourceType': _$ChainSourceTypeEnumMap[instance.sourceType]!,
      'order': instance.order,
    };

const _$ChainFailurePolicyEnumMap = {
  ChainFailurePolicy.block: 'block',
  ChainFailurePolicy.directFallback: 'directFallback',
};

const _$ChainSourceTypeEnumMap = {
  ChainSourceType.staticNodes: 'staticNodes',
  ChainSourceType.provider: 'provider',
};
