part of 'database.dart';

@DataClassName('RawProxyChain')
@TableIndex(
  name: 'idx_proxy_chains_profile_order',
  columns: {#profileId, #order},
)
class ProxyChains extends Table {
  @override
  String get tableName => 'proxy_chains';

  IntColumn get id => integer()();

  IntColumn get profileId => integer().references(
    Profiles,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get name => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  TextColumn get entryJson => text().map(const ChainHopConverter())();

  TextColumn get exitJson => text().map(const ChainHopConverter())();

  TextColumn get failurePolicy => textEnum<ChainFailurePolicy>()();

  TextColumn get sourceType => textEnum<ChainSourceType>()();

  IntColumn get order => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ChainHopConverter extends TypeConverter<ChainHop, String> {
  const ChainHopConverter();

  @override
  ChainHop fromSql(String fromDb) {
    return ChainHop.fromJson(
      Map<String, Object?>.from(json.decode(fromDb) as Map),
    );
  }

  @override
  String toSql(ChainHop value) {
    return json.encode(value.toJson());
  }
}

@DriftAccessor(tables: [ProxyChains])
class ProxyChainsDao extends DatabaseAccessor<Database>
    with _$ProxyChainsDaoMixin {
  ProxyChainsDao(super.attachedDatabase);

  Selectable<ProxyChain> query(int profileId) {
    final stmt = proxyChains.select()
      ..where((row) => row.profileId.equals(profileId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.order),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return stmt.map((item) => item.toProxyChain());
  }

  Future<int> put(ProxyChain chain) {
    return proxyChains.insertOnConflictUpdate(chain.toCompanion());
  }

  Future<int> deleteById(int id) {
    return (delete(proxyChains)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByProfile(int profileId) {
    return (delete(proxyChains)
          ..where((t) => t.profileId.equals(profileId)))
        .go();
  }

  void setAllWithBatch(
    int profileId,
    Batch batch,
    Iterable<ProxyChain> chains,
  ) {
    final items = <ProxyChainsCompanion>[];
    final ids = <int>[];
    chains.forEachIndexed((index, chain) {
      ids.add(chain.id);
      items.add(chain.toCompanion(index));
    });
    proxyChains.setAll(
      batch,
      items,
      deleteFilter: (t) =>
          t.profileId.equals(profileId) & t.id.isNotIn(ids),
    );
  }
}

extension RawProxyChainExt on RawProxyChain {
  ProxyChain toProxyChain() {
    return ProxyChain(
      id: id,
      profileId: profileId,
      name: name,
      enabled: enabled,
      entry: entryJson,
      exit: exitJson,
      failurePolicy: failurePolicy,
      sourceType: sourceType,
      order: order,
    );
  }
}

extension ProxyChainsCompanionExt on ProxyChain {
  ProxyChainsCompanion toCompanion([int? order]) {
    return ProxyChainsCompanion.insert(
      id: Value(id),
      profileId: profileId,
      name: name,
      enabled: Value(enabled),
      entryJson: entry,
      exitJson: this.exit,
      failurePolicy: failurePolicy,
      sourceType: sourceType,
      order: Value(order ?? this.order),
    );
  }
}
