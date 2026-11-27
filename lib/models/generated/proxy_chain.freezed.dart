// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../proxy_chain.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChainHop {

 ChainGroupType get type; List<String> get members; String? get testUrl; int get interval; int get tolerance;
/// Create a copy of ChainHop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChainHopCopyWith<ChainHop> get copyWith => _$ChainHopCopyWithImpl<ChainHop>(this as ChainHop, _$identity);

  /// Serializes this ChainHop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChainHop&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.testUrl, testUrl) || other.testUrl == testUrl)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.tolerance, tolerance) || other.tolerance == tolerance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(members),testUrl,interval,tolerance);

@override
String toString() {
  return 'ChainHop(type: $type, members: $members, testUrl: $testUrl, interval: $interval, tolerance: $tolerance)';
}


}

/// @nodoc
abstract mixin class $ChainHopCopyWith<$Res>  {
  factory $ChainHopCopyWith(ChainHop value, $Res Function(ChainHop) _then) = _$ChainHopCopyWithImpl;
@useResult
$Res call({
 ChainGroupType type, List<String> members, String? testUrl, int interval, int tolerance
});




}
/// @nodoc
class _$ChainHopCopyWithImpl<$Res>
    implements $ChainHopCopyWith<$Res> {
  _$ChainHopCopyWithImpl(this._self, this._then);

  final ChainHop _self;
  final $Res Function(ChainHop) _then;

/// Create a copy of ChainHop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? members = null,Object? testUrl = freezed,Object? interval = null,Object? tolerance = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChainGroupType,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<String>,testUrl: freezed == testUrl ? _self.testUrl : testUrl // ignore: cast_nullable_to_non_nullable
as String?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,tolerance: null == tolerance ? _self.tolerance : tolerance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChainHop].
extension ChainHopPatterns on ChainHop {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChainHop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChainHop() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChainHop value)  $default,){
final _that = this;
switch (_that) {
case _ChainHop():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChainHop value)?  $default,){
final _that = this;
switch (_that) {
case _ChainHop() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChainGroupType type,  List<String> members,  String? testUrl,  int interval,  int tolerance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChainHop() when $default != null:
return $default(_that.type,_that.members,_that.testUrl,_that.interval,_that.tolerance);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChainGroupType type,  List<String> members,  String? testUrl,  int interval,  int tolerance)  $default,) {final _that = this;
switch (_that) {
case _ChainHop():
return $default(_that.type,_that.members,_that.testUrl,_that.interval,_that.tolerance);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChainGroupType type,  List<String> members,  String? testUrl,  int interval,  int tolerance)?  $default,) {final _that = this;
switch (_that) {
case _ChainHop() when $default != null:
return $default(_that.type,_that.members,_that.testUrl,_that.interval,_that.tolerance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChainHop implements ChainHop {
  const _ChainHop({this.type = ChainGroupType.fallback, final  List<String> members = const [], this.testUrl, this.interval = 300, this.tolerance = 50}): _members = members;
  factory _ChainHop.fromJson(Map<String, dynamic> json) => _$ChainHopFromJson(json);

@override@JsonKey() final  ChainGroupType type;
 final  List<String> _members;
@override@JsonKey() List<String> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  String? testUrl;
@override@JsonKey() final  int interval;
@override@JsonKey() final  int tolerance;

/// Create a copy of ChainHop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChainHopCopyWith<_ChainHop> get copyWith => __$ChainHopCopyWithImpl<_ChainHop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChainHopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChainHop&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.testUrl, testUrl) || other.testUrl == testUrl)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.tolerance, tolerance) || other.tolerance == tolerance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_members),testUrl,interval,tolerance);

@override
String toString() {
  return 'ChainHop(type: $type, members: $members, testUrl: $testUrl, interval: $interval, tolerance: $tolerance)';
}


}

/// @nodoc
abstract mixin class _$ChainHopCopyWith<$Res> implements $ChainHopCopyWith<$Res> {
  factory _$ChainHopCopyWith(_ChainHop value, $Res Function(_ChainHop) _then) = __$ChainHopCopyWithImpl;
@override @useResult
$Res call({
 ChainGroupType type, List<String> members, String? testUrl, int interval, int tolerance
});




}
/// @nodoc
class __$ChainHopCopyWithImpl<$Res>
    implements _$ChainHopCopyWith<$Res> {
  __$ChainHopCopyWithImpl(this._self, this._then);

  final _ChainHop _self;
  final $Res Function(_ChainHop) _then;

/// Create a copy of ChainHop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? members = null,Object? testUrl = freezed,Object? interval = null,Object? tolerance = null,}) {
  return _then(_ChainHop(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChainGroupType,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<String>,testUrl: freezed == testUrl ? _self.testUrl : testUrl // ignore: cast_nullable_to_non_nullable
as String?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,tolerance: null == tolerance ? _self.tolerance : tolerance // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProxyChain {

 int get id; int get profileId; String get name; bool get enabled; ChainHop get entry; ChainHop get exit; ChainFailurePolicy get failurePolicy; ChainSourceType get sourceType; int get order;
/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProxyChainCopyWith<ProxyChain> get copyWith => _$ProxyChainCopyWithImpl<ProxyChain>(this as ProxyChain, _$identity);

  /// Serializes this ProxyChain to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProxyChain&&(identical(other.id, id) || other.id == id)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.entry, entry) || other.entry == entry)&&(identical(other.exit, exit) || other.exit == exit)&&(identical(other.failurePolicy, failurePolicy) || other.failurePolicy == failurePolicy)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,profileId,name,enabled,entry,exit,failurePolicy,sourceType,order);

@override
String toString() {
  return 'ProxyChain(id: $id, profileId: $profileId, name: $name, enabled: $enabled, entry: $entry, exit: $exit, failurePolicy: $failurePolicy, sourceType: $sourceType, order: $order)';
}


}

/// @nodoc
abstract mixin class $ProxyChainCopyWith<$Res>  {
  factory $ProxyChainCopyWith(ProxyChain value, $Res Function(ProxyChain) _then) = _$ProxyChainCopyWithImpl;
@useResult
$Res call({
 int id, int profileId, String name, bool enabled, ChainHop entry, ChainHop exit, ChainFailurePolicy failurePolicy, ChainSourceType sourceType, int order
});


$ChainHopCopyWith<$Res> get entry;$ChainHopCopyWith<$Res> get exit;

}
/// @nodoc
class _$ProxyChainCopyWithImpl<$Res>
    implements $ProxyChainCopyWith<$Res> {
  _$ProxyChainCopyWithImpl(this._self, this._then);

  final ProxyChain _self;
  final $Res Function(ProxyChain) _then;

/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? profileId = null,Object? name = null,Object? enabled = null,Object? entry = null,Object? exit = null,Object? failurePolicy = null,Object? sourceType = null,Object? order = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as ChainHop,exit: null == exit ? _self.exit : exit // ignore: cast_nullable_to_non_nullable
as ChainHop,failurePolicy: null == failurePolicy ? _self.failurePolicy : failurePolicy // ignore: cast_nullable_to_non_nullable
as ChainFailurePolicy,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as ChainSourceType,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChainHopCopyWith<$Res> get entry {
  
  return $ChainHopCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChainHopCopyWith<$Res> get exit {
  
  return $ChainHopCopyWith<$Res>(_self.exit, (value) {
    return _then(_self.copyWith(exit: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProxyChain].
extension ProxyChainPatterns on ProxyChain {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProxyChain value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProxyChain() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProxyChain value)  $default,){
final _that = this;
switch (_that) {
case _ProxyChain():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProxyChain value)?  $default,){
final _that = this;
switch (_that) {
case _ProxyChain() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int profileId,  String name,  bool enabled,  ChainHop entry,  ChainHop exit,  ChainFailurePolicy failurePolicy,  ChainSourceType sourceType,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProxyChain() when $default != null:
return $default(_that.id,_that.profileId,_that.name,_that.enabled,_that.entry,_that.exit,_that.failurePolicy,_that.sourceType,_that.order);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int profileId,  String name,  bool enabled,  ChainHop entry,  ChainHop exit,  ChainFailurePolicy failurePolicy,  ChainSourceType sourceType,  int order)  $default,) {final _that = this;
switch (_that) {
case _ProxyChain():
return $default(_that.id,_that.profileId,_that.name,_that.enabled,_that.entry,_that.exit,_that.failurePolicy,_that.sourceType,_that.order);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int profileId,  String name,  bool enabled,  ChainHop entry,  ChainHop exit,  ChainFailurePolicy failurePolicy,  ChainSourceType sourceType,  int order)?  $default,) {final _that = this;
switch (_that) {
case _ProxyChain() when $default != null:
return $default(_that.id,_that.profileId,_that.name,_that.enabled,_that.entry,_that.exit,_that.failurePolicy,_that.sourceType,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProxyChain implements ProxyChain {
  const _ProxyChain({required this.id, required this.profileId, required this.name, this.enabled = true, this.entry = const ChainHop(), this.exit = const ChainHop(), this.failurePolicy = ChainFailurePolicy.block, this.sourceType = ChainSourceType.staticNodes, this.order = 0});
  factory _ProxyChain.fromJson(Map<String, dynamic> json) => _$ProxyChainFromJson(json);

@override final  int id;
@override final  int profileId;
@override final  String name;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  ChainHop entry;
@override@JsonKey() final  ChainHop exit;
@override@JsonKey() final  ChainFailurePolicy failurePolicy;
@override@JsonKey() final  ChainSourceType sourceType;
@override@JsonKey() final  int order;

/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProxyChainCopyWith<_ProxyChain> get copyWith => __$ProxyChainCopyWithImpl<_ProxyChain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProxyChainToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProxyChain&&(identical(other.id, id) || other.id == id)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.name, name) || other.name == name)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.entry, entry) || other.entry == entry)&&(identical(other.exit, exit) || other.exit == exit)&&(identical(other.failurePolicy, failurePolicy) || other.failurePolicy == failurePolicy)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,profileId,name,enabled,entry,exit,failurePolicy,sourceType,order);

@override
String toString() {
  return 'ProxyChain(id: $id, profileId: $profileId, name: $name, enabled: $enabled, entry: $entry, exit: $exit, failurePolicy: $failurePolicy, sourceType: $sourceType, order: $order)';
}


}

/// @nodoc
abstract mixin class _$ProxyChainCopyWith<$Res> implements $ProxyChainCopyWith<$Res> {
  factory _$ProxyChainCopyWith(_ProxyChain value, $Res Function(_ProxyChain) _then) = __$ProxyChainCopyWithImpl;
@override @useResult
$Res call({
 int id, int profileId, String name, bool enabled, ChainHop entry, ChainHop exit, ChainFailurePolicy failurePolicy, ChainSourceType sourceType, int order
});


@override $ChainHopCopyWith<$Res> get entry;@override $ChainHopCopyWith<$Res> get exit;

}
/// @nodoc
class __$ProxyChainCopyWithImpl<$Res>
    implements _$ProxyChainCopyWith<$Res> {
  __$ProxyChainCopyWithImpl(this._self, this._then);

  final _ProxyChain _self;
  final $Res Function(_ProxyChain) _then;

/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? profileId = null,Object? name = null,Object? enabled = null,Object? entry = null,Object? exit = null,Object? failurePolicy = null,Object? sourceType = null,Object? order = null,}) {
  return _then(_ProxyChain(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,entry: null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as ChainHop,exit: null == exit ? _self.exit : exit // ignore: cast_nullable_to_non_nullable
as ChainHop,failurePolicy: null == failurePolicy ? _self.failurePolicy : failurePolicy // ignore: cast_nullable_to_non_nullable
as ChainFailurePolicy,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as ChainSourceType,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChainHopCopyWith<$Res> get entry {
  
  return $ChainHopCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}/// Create a copy of ProxyChain
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChainHopCopyWith<$Res> get exit {
  
  return $ChainHopCopyWith<$Res>(_self.exit, (value) {
    return _then(_self.copyWith(exit: value));
  });
}
}

// dart format on
