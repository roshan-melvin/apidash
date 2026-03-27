// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grpc_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GrpcRequestModel {

 String get url; bool get useTls; String get serviceName; String get methodName; GrpcCallType get callType; GrpcDescriptorSource get descriptorSource; List<NameValueModel> get metadata; List<bool> get isMetadataEnabledList; String get requestJson; int get requestTabIndex;
/// Create a copy of GrpcRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrpcRequestModelCopyWith<GrpcRequestModel> get copyWith => _$GrpcRequestModelCopyWithImpl<GrpcRequestModel>(this as GrpcRequestModel, _$identity);

  /// Serializes this GrpcRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrpcRequestModel&&(identical(other.url, url) || other.url == url)&&(identical(other.useTls, useTls) || other.useTls == useTls)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.methodName, methodName) || other.methodName == methodName)&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.descriptorSource, descriptorSource) || other.descriptorSource == descriptorSource)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&const DeepCollectionEquality().equals(other.isMetadataEnabledList, isMetadataEnabledList)&&(identical(other.requestJson, requestJson) || other.requestJson == requestJson)&&(identical(other.requestTabIndex, requestTabIndex) || other.requestTabIndex == requestTabIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,useTls,serviceName,methodName,callType,descriptorSource,const DeepCollectionEquality().hash(metadata),const DeepCollectionEquality().hash(isMetadataEnabledList),requestJson,requestTabIndex);

@override
String toString() {
  return 'GrpcRequestModel(url: $url, useTls: $useTls, serviceName: $serviceName, methodName: $methodName, callType: $callType, descriptorSource: $descriptorSource, metadata: $metadata, isMetadataEnabledList: $isMetadataEnabledList, requestJson: $requestJson, requestTabIndex: $requestTabIndex)';
}


}

/// @nodoc
abstract mixin class $GrpcRequestModelCopyWith<$Res>  {
  factory $GrpcRequestModelCopyWith(GrpcRequestModel value, $Res Function(GrpcRequestModel) _then) = _$GrpcRequestModelCopyWithImpl;
@useResult
$Res call({
 String url, bool useTls, String serviceName, String methodName, GrpcCallType callType, GrpcDescriptorSource descriptorSource, List<NameValueModel> metadata, List<bool> isMetadataEnabledList, String requestJson, int requestTabIndex
});




}
/// @nodoc
class _$GrpcRequestModelCopyWithImpl<$Res>
    implements $GrpcRequestModelCopyWith<$Res> {
  _$GrpcRequestModelCopyWithImpl(this._self, this._then);

  final GrpcRequestModel _self;
  final $Res Function(GrpcRequestModel) _then;

/// Create a copy of GrpcRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? useTls = null,Object? serviceName = null,Object? methodName = null,Object? callType = null,Object? descriptorSource = null,Object? metadata = null,Object? isMetadataEnabledList = null,Object? requestJson = null,Object? requestTabIndex = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,useTls: null == useTls ? _self.useTls : useTls // ignore: cast_nullable_to_non_nullable
as bool,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,methodName: null == methodName ? _self.methodName : methodName // ignore: cast_nullable_to_non_nullable
as String,callType: null == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as GrpcCallType,descriptorSource: null == descriptorSource ? _self.descriptorSource : descriptorSource // ignore: cast_nullable_to_non_nullable
as GrpcDescriptorSource,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<NameValueModel>,isMetadataEnabledList: null == isMetadataEnabledList ? _self.isMetadataEnabledList : isMetadataEnabledList // ignore: cast_nullable_to_non_nullable
as List<bool>,requestJson: null == requestJson ? _self.requestJson : requestJson // ignore: cast_nullable_to_non_nullable
as String,requestTabIndex: null == requestTabIndex ? _self.requestTabIndex : requestTabIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GrpcRequestModel].
extension GrpcRequestModelPatterns on GrpcRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrpcRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrpcRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrpcRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _GrpcRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrpcRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _GrpcRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  bool useTls,  String serviceName,  String methodName,  GrpcCallType callType,  GrpcDescriptorSource descriptorSource,  List<NameValueModel> metadata,  List<bool> isMetadataEnabledList,  String requestJson,  int requestTabIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrpcRequestModel() when $default != null:
return $default(_that.url,_that.useTls,_that.serviceName,_that.methodName,_that.callType,_that.descriptorSource,_that.metadata,_that.isMetadataEnabledList,_that.requestJson,_that.requestTabIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  bool useTls,  String serviceName,  String methodName,  GrpcCallType callType,  GrpcDescriptorSource descriptorSource,  List<NameValueModel> metadata,  List<bool> isMetadataEnabledList,  String requestJson,  int requestTabIndex)  $default,) {final _that = this;
switch (_that) {
case _GrpcRequestModel():
return $default(_that.url,_that.useTls,_that.serviceName,_that.methodName,_that.callType,_that.descriptorSource,_that.metadata,_that.isMetadataEnabledList,_that.requestJson,_that.requestTabIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  bool useTls,  String serviceName,  String methodName,  GrpcCallType callType,  GrpcDescriptorSource descriptorSource,  List<NameValueModel> metadata,  List<bool> isMetadataEnabledList,  String requestJson,  int requestTabIndex)?  $default,) {final _that = this;
switch (_that) {
case _GrpcRequestModel() when $default != null:
return $default(_that.url,_that.useTls,_that.serviceName,_that.methodName,_that.callType,_that.descriptorSource,_that.metadata,_that.isMetadataEnabledList,_that.requestJson,_that.requestTabIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrpcRequestModel implements GrpcRequestModel {
  const _GrpcRequestModel({this.url = '', this.useTls = false, this.serviceName = '', this.methodName = '', this.callType = GrpcCallType.unary, this.descriptorSource = GrpcDescriptorSource.reflection, final  List<NameValueModel> metadata = const [], final  List<bool> isMetadataEnabledList = const [], this.requestJson = '', this.requestTabIndex = 0}): _metadata = metadata,_isMetadataEnabledList = isMetadataEnabledList;
  factory _GrpcRequestModel.fromJson(Map<String, dynamic> json) => _$GrpcRequestModelFromJson(json);

@override@JsonKey() final  String url;
@override@JsonKey() final  bool useTls;
@override@JsonKey() final  String serviceName;
@override@JsonKey() final  String methodName;
@override@JsonKey() final  GrpcCallType callType;
@override@JsonKey() final  GrpcDescriptorSource descriptorSource;
 final  List<NameValueModel> _metadata;
@override@JsonKey() List<NameValueModel> get metadata {
  if (_metadata is EqualUnmodifiableListView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metadata);
}

 final  List<bool> _isMetadataEnabledList;
@override@JsonKey() List<bool> get isMetadataEnabledList {
  if (_isMetadataEnabledList is EqualUnmodifiableListView) return _isMetadataEnabledList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_isMetadataEnabledList);
}

@override@JsonKey() final  String requestJson;
@override@JsonKey() final  int requestTabIndex;

/// Create a copy of GrpcRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrpcRequestModelCopyWith<_GrpcRequestModel> get copyWith => __$GrpcRequestModelCopyWithImpl<_GrpcRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrpcRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrpcRequestModel&&(identical(other.url, url) || other.url == url)&&(identical(other.useTls, useTls) || other.useTls == useTls)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.methodName, methodName) || other.methodName == methodName)&&(identical(other.callType, callType) || other.callType == callType)&&(identical(other.descriptorSource, descriptorSource) || other.descriptorSource == descriptorSource)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&const DeepCollectionEquality().equals(other._isMetadataEnabledList, _isMetadataEnabledList)&&(identical(other.requestJson, requestJson) || other.requestJson == requestJson)&&(identical(other.requestTabIndex, requestTabIndex) || other.requestTabIndex == requestTabIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,useTls,serviceName,methodName,callType,descriptorSource,const DeepCollectionEquality().hash(_metadata),const DeepCollectionEquality().hash(_isMetadataEnabledList),requestJson,requestTabIndex);

@override
String toString() {
  return 'GrpcRequestModel(url: $url, useTls: $useTls, serviceName: $serviceName, methodName: $methodName, callType: $callType, descriptorSource: $descriptorSource, metadata: $metadata, isMetadataEnabledList: $isMetadataEnabledList, requestJson: $requestJson, requestTabIndex: $requestTabIndex)';
}


}

/// @nodoc
abstract mixin class _$GrpcRequestModelCopyWith<$Res> implements $GrpcRequestModelCopyWith<$Res> {
  factory _$GrpcRequestModelCopyWith(_GrpcRequestModel value, $Res Function(_GrpcRequestModel) _then) = __$GrpcRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String url, bool useTls, String serviceName, String methodName, GrpcCallType callType, GrpcDescriptorSource descriptorSource, List<NameValueModel> metadata, List<bool> isMetadataEnabledList, String requestJson, int requestTabIndex
});




}
/// @nodoc
class __$GrpcRequestModelCopyWithImpl<$Res>
    implements _$GrpcRequestModelCopyWith<$Res> {
  __$GrpcRequestModelCopyWithImpl(this._self, this._then);

  final _GrpcRequestModel _self;
  final $Res Function(_GrpcRequestModel) _then;

/// Create a copy of GrpcRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? useTls = null,Object? serviceName = null,Object? methodName = null,Object? callType = null,Object? descriptorSource = null,Object? metadata = null,Object? isMetadataEnabledList = null,Object? requestJson = null,Object? requestTabIndex = null,}) {
  return _then(_GrpcRequestModel(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,useTls: null == useTls ? _self.useTls : useTls // ignore: cast_nullable_to_non_nullable
as bool,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,methodName: null == methodName ? _self.methodName : methodName // ignore: cast_nullable_to_non_nullable
as String,callType: null == callType ? _self.callType : callType // ignore: cast_nullable_to_non_nullable
as GrpcCallType,descriptorSource: null == descriptorSource ? _self.descriptorSource : descriptorSource // ignore: cast_nullable_to_non_nullable
as GrpcDescriptorSource,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<NameValueModel>,isMetadataEnabledList: null == isMetadataEnabledList ? _self._isMetadataEnabledList : isMetadataEnabledList // ignore: cast_nullable_to_non_nullable
as List<bool>,requestJson: null == requestJson ? _self.requestJson : requestJson // ignore: cast_nullable_to_non_nullable
as String,requestTabIndex: null == requestTabIndex ? _self.requestTabIndex : requestTabIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
