// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mqtt_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MQTTRequestModel {

 String get brokerUrl; int get port; String get clientId; String get username; String get password; int get keepAlive; bool get cleanSession; int get connectTimeout; bool get autoReconnect; MQTTProtocolVersion get protocolVersion; bool get useTls; List<MQTTTopicModel> get topics; String get publishTopic; String get publishPayload; int get publishQos; bool get publishRetain; String get lastWillTopic; String get lastWillMessage; int get lastWillQos; bool get lastWillRetain; List<MQTTSavedMessage> get savedMessages; List<MQTTSavedEvent> get savedEventLog;
/// Create a copy of MQTTRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MQTTRequestModelCopyWith<MQTTRequestModel> get copyWith => _$MQTTRequestModelCopyWithImpl<MQTTRequestModel>(this as MQTTRequestModel, _$identity);

  /// Serializes this MQTTRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MQTTRequestModel&&(identical(other.brokerUrl, brokerUrl) || other.brokerUrl == brokerUrl)&&(identical(other.port, port) || other.port == port)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.keepAlive, keepAlive) || other.keepAlive == keepAlive)&&(identical(other.cleanSession, cleanSession) || other.cleanSession == cleanSession)&&(identical(other.connectTimeout, connectTimeout) || other.connectTimeout == connectTimeout)&&(identical(other.autoReconnect, autoReconnect) || other.autoReconnect == autoReconnect)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.useTls, useTls) || other.useTls == useTls)&&const DeepCollectionEquality().equals(other.topics, topics)&&(identical(other.publishTopic, publishTopic) || other.publishTopic == publishTopic)&&(identical(other.publishPayload, publishPayload) || other.publishPayload == publishPayload)&&(identical(other.publishQos, publishQos) || other.publishQos == publishQos)&&(identical(other.publishRetain, publishRetain) || other.publishRetain == publishRetain)&&(identical(other.lastWillTopic, lastWillTopic) || other.lastWillTopic == lastWillTopic)&&(identical(other.lastWillMessage, lastWillMessage) || other.lastWillMessage == lastWillMessage)&&(identical(other.lastWillQos, lastWillQos) || other.lastWillQos == lastWillQos)&&(identical(other.lastWillRetain, lastWillRetain) || other.lastWillRetain == lastWillRetain)&&const DeepCollectionEquality().equals(other.savedMessages, savedMessages)&&const DeepCollectionEquality().equals(other.savedEventLog, savedEventLog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,brokerUrl,port,clientId,username,password,keepAlive,cleanSession,connectTimeout,autoReconnect,protocolVersion,useTls,const DeepCollectionEquality().hash(topics),publishTopic,publishPayload,publishQos,publishRetain,lastWillTopic,lastWillMessage,lastWillQos,lastWillRetain,const DeepCollectionEquality().hash(savedMessages),const DeepCollectionEquality().hash(savedEventLog)]);

@override
String toString() {
  return 'MQTTRequestModel(brokerUrl: $brokerUrl, port: $port, clientId: $clientId, username: $username, password: $password, keepAlive: $keepAlive, cleanSession: $cleanSession, connectTimeout: $connectTimeout, autoReconnect: $autoReconnect, protocolVersion: $protocolVersion, useTls: $useTls, topics: $topics, publishTopic: $publishTopic, publishPayload: $publishPayload, publishQos: $publishQos, publishRetain: $publishRetain, lastWillTopic: $lastWillTopic, lastWillMessage: $lastWillMessage, lastWillQos: $lastWillQos, lastWillRetain: $lastWillRetain, savedMessages: $savedMessages, savedEventLog: $savedEventLog)';
}


}

/// @nodoc
abstract mixin class $MQTTRequestModelCopyWith<$Res>  {
  factory $MQTTRequestModelCopyWith(MQTTRequestModel value, $Res Function(MQTTRequestModel) _then) = _$MQTTRequestModelCopyWithImpl;
@useResult
$Res call({
 String brokerUrl, int port, String clientId, String username, String password, int keepAlive, bool cleanSession, int connectTimeout, bool autoReconnect, MQTTProtocolVersion protocolVersion, bool useTls, List<MQTTTopicModel> topics, String publishTopic, String publishPayload, int publishQos, bool publishRetain, String lastWillTopic, String lastWillMessage, int lastWillQos, bool lastWillRetain, List<MQTTSavedMessage> savedMessages, List<MQTTSavedEvent> savedEventLog
});




}
/// @nodoc
class _$MQTTRequestModelCopyWithImpl<$Res>
    implements $MQTTRequestModelCopyWith<$Res> {
  _$MQTTRequestModelCopyWithImpl(this._self, this._then);

  final MQTTRequestModel _self;
  final $Res Function(MQTTRequestModel) _then;

/// Create a copy of MQTTRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? brokerUrl = null,Object? port = null,Object? clientId = null,Object? username = null,Object? password = null,Object? keepAlive = null,Object? cleanSession = null,Object? connectTimeout = null,Object? autoReconnect = null,Object? protocolVersion = null,Object? useTls = null,Object? topics = null,Object? publishTopic = null,Object? publishPayload = null,Object? publishQos = null,Object? publishRetain = null,Object? lastWillTopic = null,Object? lastWillMessage = null,Object? lastWillQos = null,Object? lastWillRetain = null,Object? savedMessages = null,Object? savedEventLog = null,}) {
  return _then(_self.copyWith(
brokerUrl: null == brokerUrl ? _self.brokerUrl : brokerUrl // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,keepAlive: null == keepAlive ? _self.keepAlive : keepAlive // ignore: cast_nullable_to_non_nullable
as int,cleanSession: null == cleanSession ? _self.cleanSession : cleanSession // ignore: cast_nullable_to_non_nullable
as bool,connectTimeout: null == connectTimeout ? _self.connectTimeout : connectTimeout // ignore: cast_nullable_to_non_nullable
as int,autoReconnect: null == autoReconnect ? _self.autoReconnect : autoReconnect // ignore: cast_nullable_to_non_nullable
as bool,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as MQTTProtocolVersion,useTls: null == useTls ? _self.useTls : useTls // ignore: cast_nullable_to_non_nullable
as bool,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<MQTTTopicModel>,publishTopic: null == publishTopic ? _self.publishTopic : publishTopic // ignore: cast_nullable_to_non_nullable
as String,publishPayload: null == publishPayload ? _self.publishPayload : publishPayload // ignore: cast_nullable_to_non_nullable
as String,publishQos: null == publishQos ? _self.publishQos : publishQos // ignore: cast_nullable_to_non_nullable
as int,publishRetain: null == publishRetain ? _self.publishRetain : publishRetain // ignore: cast_nullable_to_non_nullable
as bool,lastWillTopic: null == lastWillTopic ? _self.lastWillTopic : lastWillTopic // ignore: cast_nullable_to_non_nullable
as String,lastWillMessage: null == lastWillMessage ? _self.lastWillMessage : lastWillMessage // ignore: cast_nullable_to_non_nullable
as String,lastWillQos: null == lastWillQos ? _self.lastWillQos : lastWillQos // ignore: cast_nullable_to_non_nullable
as int,lastWillRetain: null == lastWillRetain ? _self.lastWillRetain : lastWillRetain // ignore: cast_nullable_to_non_nullable
as bool,savedMessages: null == savedMessages ? _self.savedMessages : savedMessages // ignore: cast_nullable_to_non_nullable
as List<MQTTSavedMessage>,savedEventLog: null == savedEventLog ? _self.savedEventLog : savedEventLog // ignore: cast_nullable_to_non_nullable
as List<MQTTSavedEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [MQTTRequestModel].
extension MQTTRequestModelPatterns on MQTTRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MQTTRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MQTTRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MQTTRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _MQTTRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MQTTRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _MQTTRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String brokerUrl,  int port,  String clientId,  String username,  String password,  int keepAlive,  bool cleanSession,  int connectTimeout,  bool autoReconnect,  MQTTProtocolVersion protocolVersion,  bool useTls,  List<MQTTTopicModel> topics,  String publishTopic,  String publishPayload,  int publishQos,  bool publishRetain,  String lastWillTopic,  String lastWillMessage,  int lastWillQos,  bool lastWillRetain,  List<MQTTSavedMessage> savedMessages,  List<MQTTSavedEvent> savedEventLog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MQTTRequestModel() when $default != null:
return $default(_that.brokerUrl,_that.port,_that.clientId,_that.username,_that.password,_that.keepAlive,_that.cleanSession,_that.connectTimeout,_that.autoReconnect,_that.protocolVersion,_that.useTls,_that.topics,_that.publishTopic,_that.publishPayload,_that.publishQos,_that.publishRetain,_that.lastWillTopic,_that.lastWillMessage,_that.lastWillQos,_that.lastWillRetain,_that.savedMessages,_that.savedEventLog);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String brokerUrl,  int port,  String clientId,  String username,  String password,  int keepAlive,  bool cleanSession,  int connectTimeout,  bool autoReconnect,  MQTTProtocolVersion protocolVersion,  bool useTls,  List<MQTTTopicModel> topics,  String publishTopic,  String publishPayload,  int publishQos,  bool publishRetain,  String lastWillTopic,  String lastWillMessage,  int lastWillQos,  bool lastWillRetain,  List<MQTTSavedMessage> savedMessages,  List<MQTTSavedEvent> savedEventLog)  $default,) {final _that = this;
switch (_that) {
case _MQTTRequestModel():
return $default(_that.brokerUrl,_that.port,_that.clientId,_that.username,_that.password,_that.keepAlive,_that.cleanSession,_that.connectTimeout,_that.autoReconnect,_that.protocolVersion,_that.useTls,_that.topics,_that.publishTopic,_that.publishPayload,_that.publishQos,_that.publishRetain,_that.lastWillTopic,_that.lastWillMessage,_that.lastWillQos,_that.lastWillRetain,_that.savedMessages,_that.savedEventLog);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String brokerUrl,  int port,  String clientId,  String username,  String password,  int keepAlive,  bool cleanSession,  int connectTimeout,  bool autoReconnect,  MQTTProtocolVersion protocolVersion,  bool useTls,  List<MQTTTopicModel> topics,  String publishTopic,  String publishPayload,  int publishQos,  bool publishRetain,  String lastWillTopic,  String lastWillMessage,  int lastWillQos,  bool lastWillRetain,  List<MQTTSavedMessage> savedMessages,  List<MQTTSavedEvent> savedEventLog)?  $default,) {final _that = this;
switch (_that) {
case _MQTTRequestModel() when $default != null:
return $default(_that.brokerUrl,_that.port,_that.clientId,_that.username,_that.password,_that.keepAlive,_that.cleanSession,_that.connectTimeout,_that.autoReconnect,_that.protocolVersion,_that.useTls,_that.topics,_that.publishTopic,_that.publishPayload,_that.publishQos,_that.publishRetain,_that.lastWillTopic,_that.lastWillMessage,_that.lastWillQos,_that.lastWillRetain,_that.savedMessages,_that.savedEventLog);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, anyMap: true)
class _MQTTRequestModel implements MQTTRequestModel {
  const _MQTTRequestModel({this.brokerUrl = "", this.port = 1883, this.clientId = "", this.username = "", this.password = "", this.keepAlive = 60, this.cleanSession = false, this.connectTimeout = 3, this.autoReconnect = true, this.protocolVersion = MQTTProtocolVersion.v311, this.useTls = false, final  List<MQTTTopicModel> topics = const [], this.publishTopic = "", this.publishPayload = "", this.publishQos = 0, this.publishRetain = false, this.lastWillTopic = "", this.lastWillMessage = "", this.lastWillQos = 0, this.lastWillRetain = false, final  List<MQTTSavedMessage> savedMessages = const [], final  List<MQTTSavedEvent> savedEventLog = const []}): _topics = topics,_savedMessages = savedMessages,_savedEventLog = savedEventLog;
  factory _MQTTRequestModel.fromJson(Map<String, dynamic> json) => _$MQTTRequestModelFromJson(json);

@override@JsonKey() final  String brokerUrl;
@override@JsonKey() final  int port;
@override@JsonKey() final  String clientId;
@override@JsonKey() final  String username;
@override@JsonKey() final  String password;
@override@JsonKey() final  int keepAlive;
@override@JsonKey() final  bool cleanSession;
@override@JsonKey() final  int connectTimeout;
@override@JsonKey() final  bool autoReconnect;
@override@JsonKey() final  MQTTProtocolVersion protocolVersion;
@override@JsonKey() final  bool useTls;
 final  List<MQTTTopicModel> _topics;
@override@JsonKey() List<MQTTTopicModel> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}

@override@JsonKey() final  String publishTopic;
@override@JsonKey() final  String publishPayload;
@override@JsonKey() final  int publishQos;
@override@JsonKey() final  bool publishRetain;
@override@JsonKey() final  String lastWillTopic;
@override@JsonKey() final  String lastWillMessage;
@override@JsonKey() final  int lastWillQos;
@override@JsonKey() final  bool lastWillRetain;
 final  List<MQTTSavedMessage> _savedMessages;
@override@JsonKey() List<MQTTSavedMessage> get savedMessages {
  if (_savedMessages is EqualUnmodifiableListView) return _savedMessages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedMessages);
}

 final  List<MQTTSavedEvent> _savedEventLog;
@override@JsonKey() List<MQTTSavedEvent> get savedEventLog {
  if (_savedEventLog is EqualUnmodifiableListView) return _savedEventLog;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedEventLog);
}


/// Create a copy of MQTTRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MQTTRequestModelCopyWith<_MQTTRequestModel> get copyWith => __$MQTTRequestModelCopyWithImpl<_MQTTRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MQTTRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MQTTRequestModel&&(identical(other.brokerUrl, brokerUrl) || other.brokerUrl == brokerUrl)&&(identical(other.port, port) || other.port == port)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.keepAlive, keepAlive) || other.keepAlive == keepAlive)&&(identical(other.cleanSession, cleanSession) || other.cleanSession == cleanSession)&&(identical(other.connectTimeout, connectTimeout) || other.connectTimeout == connectTimeout)&&(identical(other.autoReconnect, autoReconnect) || other.autoReconnect == autoReconnect)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.useTls, useTls) || other.useTls == useTls)&&const DeepCollectionEquality().equals(other._topics, _topics)&&(identical(other.publishTopic, publishTopic) || other.publishTopic == publishTopic)&&(identical(other.publishPayload, publishPayload) || other.publishPayload == publishPayload)&&(identical(other.publishQos, publishQos) || other.publishQos == publishQos)&&(identical(other.publishRetain, publishRetain) || other.publishRetain == publishRetain)&&(identical(other.lastWillTopic, lastWillTopic) || other.lastWillTopic == lastWillTopic)&&(identical(other.lastWillMessage, lastWillMessage) || other.lastWillMessage == lastWillMessage)&&(identical(other.lastWillQos, lastWillQos) || other.lastWillQos == lastWillQos)&&(identical(other.lastWillRetain, lastWillRetain) || other.lastWillRetain == lastWillRetain)&&const DeepCollectionEquality().equals(other._savedMessages, _savedMessages)&&const DeepCollectionEquality().equals(other._savedEventLog, _savedEventLog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,brokerUrl,port,clientId,username,password,keepAlive,cleanSession,connectTimeout,autoReconnect,protocolVersion,useTls,const DeepCollectionEquality().hash(_topics),publishTopic,publishPayload,publishQos,publishRetain,lastWillTopic,lastWillMessage,lastWillQos,lastWillRetain,const DeepCollectionEquality().hash(_savedMessages),const DeepCollectionEquality().hash(_savedEventLog)]);

@override
String toString() {
  return 'MQTTRequestModel(brokerUrl: $brokerUrl, port: $port, clientId: $clientId, username: $username, password: $password, keepAlive: $keepAlive, cleanSession: $cleanSession, connectTimeout: $connectTimeout, autoReconnect: $autoReconnect, protocolVersion: $protocolVersion, useTls: $useTls, topics: $topics, publishTopic: $publishTopic, publishPayload: $publishPayload, publishQos: $publishQos, publishRetain: $publishRetain, lastWillTopic: $lastWillTopic, lastWillMessage: $lastWillMessage, lastWillQos: $lastWillQos, lastWillRetain: $lastWillRetain, savedMessages: $savedMessages, savedEventLog: $savedEventLog)';
}


}

/// @nodoc
abstract mixin class _$MQTTRequestModelCopyWith<$Res> implements $MQTTRequestModelCopyWith<$Res> {
  factory _$MQTTRequestModelCopyWith(_MQTTRequestModel value, $Res Function(_MQTTRequestModel) _then) = __$MQTTRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String brokerUrl, int port, String clientId, String username, String password, int keepAlive, bool cleanSession, int connectTimeout, bool autoReconnect, MQTTProtocolVersion protocolVersion, bool useTls, List<MQTTTopicModel> topics, String publishTopic, String publishPayload, int publishQos, bool publishRetain, String lastWillTopic, String lastWillMessage, int lastWillQos, bool lastWillRetain, List<MQTTSavedMessage> savedMessages, List<MQTTSavedEvent> savedEventLog
});




}
/// @nodoc
class __$MQTTRequestModelCopyWithImpl<$Res>
    implements _$MQTTRequestModelCopyWith<$Res> {
  __$MQTTRequestModelCopyWithImpl(this._self, this._then);

  final _MQTTRequestModel _self;
  final $Res Function(_MQTTRequestModel) _then;

/// Create a copy of MQTTRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? brokerUrl = null,Object? port = null,Object? clientId = null,Object? username = null,Object? password = null,Object? keepAlive = null,Object? cleanSession = null,Object? connectTimeout = null,Object? autoReconnect = null,Object? protocolVersion = null,Object? useTls = null,Object? topics = null,Object? publishTopic = null,Object? publishPayload = null,Object? publishQos = null,Object? publishRetain = null,Object? lastWillTopic = null,Object? lastWillMessage = null,Object? lastWillQos = null,Object? lastWillRetain = null,Object? savedMessages = null,Object? savedEventLog = null,}) {
  return _then(_MQTTRequestModel(
brokerUrl: null == brokerUrl ? _self.brokerUrl : brokerUrl // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,keepAlive: null == keepAlive ? _self.keepAlive : keepAlive // ignore: cast_nullable_to_non_nullable
as int,cleanSession: null == cleanSession ? _self.cleanSession : cleanSession // ignore: cast_nullable_to_non_nullable
as bool,connectTimeout: null == connectTimeout ? _self.connectTimeout : connectTimeout // ignore: cast_nullable_to_non_nullable
as int,autoReconnect: null == autoReconnect ? _self.autoReconnect : autoReconnect // ignore: cast_nullable_to_non_nullable
as bool,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as MQTTProtocolVersion,useTls: null == useTls ? _self.useTls : useTls // ignore: cast_nullable_to_non_nullable
as bool,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<MQTTTopicModel>,publishTopic: null == publishTopic ? _self.publishTopic : publishTopic // ignore: cast_nullable_to_non_nullable
as String,publishPayload: null == publishPayload ? _self.publishPayload : publishPayload // ignore: cast_nullable_to_non_nullable
as String,publishQos: null == publishQos ? _self.publishQos : publishQos // ignore: cast_nullable_to_non_nullable
as int,publishRetain: null == publishRetain ? _self.publishRetain : publishRetain // ignore: cast_nullable_to_non_nullable
as bool,lastWillTopic: null == lastWillTopic ? _self.lastWillTopic : lastWillTopic // ignore: cast_nullable_to_non_nullable
as String,lastWillMessage: null == lastWillMessage ? _self.lastWillMessage : lastWillMessage // ignore: cast_nullable_to_non_nullable
as String,lastWillQos: null == lastWillQos ? _self.lastWillQos : lastWillQos // ignore: cast_nullable_to_non_nullable
as int,lastWillRetain: null == lastWillRetain ? _self.lastWillRetain : lastWillRetain // ignore: cast_nullable_to_non_nullable
as bool,savedMessages: null == savedMessages ? _self._savedMessages : savedMessages // ignore: cast_nullable_to_non_nullable
as List<MQTTSavedMessage>,savedEventLog: null == savedEventLog ? _self._savedEventLog : savedEventLog // ignore: cast_nullable_to_non_nullable
as List<MQTTSavedEvent>,
  ));
}


}


/// @nodoc
mixin _$MQTTTopicModel {

 String get topic; int get qos; bool get subscribe; String get description;
/// Create a copy of MQTTTopicModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MQTTTopicModelCopyWith<MQTTTopicModel> get copyWith => _$MQTTTopicModelCopyWithImpl<MQTTTopicModel>(this as MQTTTopicModel, _$identity);

  /// Serializes this MQTTTopicModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MQTTTopicModel&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.qos, qos) || other.qos == qos)&&(identical(other.subscribe, subscribe) || other.subscribe == subscribe)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,qos,subscribe,description);

@override
String toString() {
  return 'MQTTTopicModel(topic: $topic, qos: $qos, subscribe: $subscribe, description: $description)';
}


}

/// @nodoc
abstract mixin class $MQTTTopicModelCopyWith<$Res>  {
  factory $MQTTTopicModelCopyWith(MQTTTopicModel value, $Res Function(MQTTTopicModel) _then) = _$MQTTTopicModelCopyWithImpl;
@useResult
$Res call({
 String topic, int qos, bool subscribe, String description
});




}
/// @nodoc
class _$MQTTTopicModelCopyWithImpl<$Res>
    implements $MQTTTopicModelCopyWith<$Res> {
  _$MQTTTopicModelCopyWithImpl(this._self, this._then);

  final MQTTTopicModel _self;
  final $Res Function(MQTTTopicModel) _then;

/// Create a copy of MQTTTopicModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topic = null,Object? qos = null,Object? subscribe = null,Object? description = null,}) {
  return _then(_self.copyWith(
topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,qos: null == qos ? _self.qos : qos // ignore: cast_nullable_to_non_nullable
as int,subscribe: null == subscribe ? _self.subscribe : subscribe // ignore: cast_nullable_to_non_nullable
as bool,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MQTTTopicModel].
extension MQTTTopicModelPatterns on MQTTTopicModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MQTTTopicModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MQTTTopicModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MQTTTopicModel value)  $default,){
final _that = this;
switch (_that) {
case _MQTTTopicModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MQTTTopicModel value)?  $default,){
final _that = this;
switch (_that) {
case _MQTTTopicModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String topic,  int qos,  bool subscribe,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MQTTTopicModel() when $default != null:
return $default(_that.topic,_that.qos,_that.subscribe,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String topic,  int qos,  bool subscribe,  String description)  $default,) {final _that = this;
switch (_that) {
case _MQTTTopicModel():
return $default(_that.topic,_that.qos,_that.subscribe,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String topic,  int qos,  bool subscribe,  String description)?  $default,) {final _that = this;
switch (_that) {
case _MQTTTopicModel() when $default != null:
return $default(_that.topic,_that.qos,_that.subscribe,_that.description);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, anyMap: true)
class _MQTTTopicModel implements MQTTTopicModel {
  const _MQTTTopicModel({required this.topic, this.qos = 0, this.subscribe = false, this.description = ""});
  factory _MQTTTopicModel.fromJson(Map<String, dynamic> json) => _$MQTTTopicModelFromJson(json);

@override final  String topic;
@override@JsonKey() final  int qos;
@override@JsonKey() final  bool subscribe;
@override@JsonKey() final  String description;

/// Create a copy of MQTTTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MQTTTopicModelCopyWith<_MQTTTopicModel> get copyWith => __$MQTTTopicModelCopyWithImpl<_MQTTTopicModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MQTTTopicModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MQTTTopicModel&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.qos, qos) || other.qos == qos)&&(identical(other.subscribe, subscribe) || other.subscribe == subscribe)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,qos,subscribe,description);

@override
String toString() {
  return 'MQTTTopicModel(topic: $topic, qos: $qos, subscribe: $subscribe, description: $description)';
}


}

/// @nodoc
abstract mixin class _$MQTTTopicModelCopyWith<$Res> implements $MQTTTopicModelCopyWith<$Res> {
  factory _$MQTTTopicModelCopyWith(_MQTTTopicModel value, $Res Function(_MQTTTopicModel) _then) = __$MQTTTopicModelCopyWithImpl;
@override @useResult
$Res call({
 String topic, int qos, bool subscribe, String description
});




}
/// @nodoc
class __$MQTTTopicModelCopyWithImpl<$Res>
    implements _$MQTTTopicModelCopyWith<$Res> {
  __$MQTTTopicModelCopyWithImpl(this._self, this._then);

  final _MQTTTopicModel _self;
  final $Res Function(_MQTTTopicModel) _then;

/// Create a copy of MQTTTopicModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topic = null,Object? qos = null,Object? subscribe = null,Object? description = null,}) {
  return _then(_MQTTTopicModel(
topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,qos: null == qos ? _self.qos : qos // ignore: cast_nullable_to_non_nullable
as int,subscribe: null == subscribe ? _self.subscribe : subscribe // ignore: cast_nullable_to_non_nullable
as bool,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MQTTSavedMessage {

 String get topic; String get payload; DateTime get timestamp; bool get isIncoming; int get qos; bool get isRetained;
/// Create a copy of MQTTSavedMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MQTTSavedMessageCopyWith<MQTTSavedMessage> get copyWith => _$MQTTSavedMessageCopyWithImpl<MQTTSavedMessage>(this as MQTTSavedMessage, _$identity);

  /// Serializes this MQTTSavedMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MQTTSavedMessage&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isIncoming, isIncoming) || other.isIncoming == isIncoming)&&(identical(other.qos, qos) || other.qos == qos)&&(identical(other.isRetained, isRetained) || other.isRetained == isRetained));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,payload,timestamp,isIncoming,qos,isRetained);

@override
String toString() {
  return 'MQTTSavedMessage(topic: $topic, payload: $payload, timestamp: $timestamp, isIncoming: $isIncoming, qos: $qos, isRetained: $isRetained)';
}


}

/// @nodoc
abstract mixin class $MQTTSavedMessageCopyWith<$Res>  {
  factory $MQTTSavedMessageCopyWith(MQTTSavedMessage value, $Res Function(MQTTSavedMessage) _then) = _$MQTTSavedMessageCopyWithImpl;
@useResult
$Res call({
 String topic, String payload, DateTime timestamp, bool isIncoming, int qos, bool isRetained
});




}
/// @nodoc
class _$MQTTSavedMessageCopyWithImpl<$Res>
    implements $MQTTSavedMessageCopyWith<$Res> {
  _$MQTTSavedMessageCopyWithImpl(this._self, this._then);

  final MQTTSavedMessage _self;
  final $Res Function(MQTTSavedMessage) _then;

/// Create a copy of MQTTSavedMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topic = null,Object? payload = null,Object? timestamp = null,Object? isIncoming = null,Object? qos = null,Object? isRetained = null,}) {
  return _then(_self.copyWith(
topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isIncoming: null == isIncoming ? _self.isIncoming : isIncoming // ignore: cast_nullable_to_non_nullable
as bool,qos: null == qos ? _self.qos : qos // ignore: cast_nullable_to_non_nullable
as int,isRetained: null == isRetained ? _self.isRetained : isRetained // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MQTTSavedMessage].
extension MQTTSavedMessagePatterns on MQTTSavedMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MQTTSavedMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MQTTSavedMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MQTTSavedMessage value)  $default,){
final _that = this;
switch (_that) {
case _MQTTSavedMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MQTTSavedMessage value)?  $default,){
final _that = this;
switch (_that) {
case _MQTTSavedMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String topic,  String payload,  DateTime timestamp,  bool isIncoming,  int qos,  bool isRetained)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MQTTSavedMessage() when $default != null:
return $default(_that.topic,_that.payload,_that.timestamp,_that.isIncoming,_that.qos,_that.isRetained);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String topic,  String payload,  DateTime timestamp,  bool isIncoming,  int qos,  bool isRetained)  $default,) {final _that = this;
switch (_that) {
case _MQTTSavedMessage():
return $default(_that.topic,_that.payload,_that.timestamp,_that.isIncoming,_that.qos,_that.isRetained);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String topic,  String payload,  DateTime timestamp,  bool isIncoming,  int qos,  bool isRetained)?  $default,) {final _that = this;
switch (_that) {
case _MQTTSavedMessage() when $default != null:
return $default(_that.topic,_that.payload,_that.timestamp,_that.isIncoming,_that.qos,_that.isRetained);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(anyMap: true)
class _MQTTSavedMessage implements MQTTSavedMessage {
  const _MQTTSavedMessage({required this.topic, required this.payload, required this.timestamp, required this.isIncoming, this.qos = 0, this.isRetained = false});
  factory _MQTTSavedMessage.fromJson(Map<String, dynamic> json) => _$MQTTSavedMessageFromJson(json);

@override final  String topic;
@override final  String payload;
@override final  DateTime timestamp;
@override final  bool isIncoming;
@override@JsonKey() final  int qos;
@override@JsonKey() final  bool isRetained;

/// Create a copy of MQTTSavedMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MQTTSavedMessageCopyWith<_MQTTSavedMessage> get copyWith => __$MQTTSavedMessageCopyWithImpl<_MQTTSavedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MQTTSavedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MQTTSavedMessage&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isIncoming, isIncoming) || other.isIncoming == isIncoming)&&(identical(other.qos, qos) || other.qos == qos)&&(identical(other.isRetained, isRetained) || other.isRetained == isRetained));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topic,payload,timestamp,isIncoming,qos,isRetained);

@override
String toString() {
  return 'MQTTSavedMessage(topic: $topic, payload: $payload, timestamp: $timestamp, isIncoming: $isIncoming, qos: $qos, isRetained: $isRetained)';
}


}

/// @nodoc
abstract mixin class _$MQTTSavedMessageCopyWith<$Res> implements $MQTTSavedMessageCopyWith<$Res> {
  factory _$MQTTSavedMessageCopyWith(_MQTTSavedMessage value, $Res Function(_MQTTSavedMessage) _then) = __$MQTTSavedMessageCopyWithImpl;
@override @useResult
$Res call({
 String topic, String payload, DateTime timestamp, bool isIncoming, int qos, bool isRetained
});




}
/// @nodoc
class __$MQTTSavedMessageCopyWithImpl<$Res>
    implements _$MQTTSavedMessageCopyWith<$Res> {
  __$MQTTSavedMessageCopyWithImpl(this._self, this._then);

  final _MQTTSavedMessage _self;
  final $Res Function(_MQTTSavedMessage) _then;

/// Create a copy of MQTTSavedMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topic = null,Object? payload = null,Object? timestamp = null,Object? isIncoming = null,Object? qos = null,Object? isRetained = null,}) {
  return _then(_MQTTSavedMessage(
topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isIncoming: null == isIncoming ? _self.isIncoming : isIncoming // ignore: cast_nullable_to_non_nullable
as bool,qos: null == qos ? _self.qos : qos // ignore: cast_nullable_to_non_nullable
as int,isRetained: null == isRetained ? _self.isRetained : isRetained // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$MQTTSavedEvent {

 DateTime get timestamp; String get eventType; String get description; String? get topic; String? get payload;
/// Create a copy of MQTTSavedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MQTTSavedEventCopyWith<MQTTSavedEvent> get copyWith => _$MQTTSavedEventCopyWithImpl<MQTTSavedEvent>(this as MQTTSavedEvent, _$identity);

  /// Serializes this MQTTSavedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MQTTSavedEvent&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.description, description) || other.description == description)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.payload, payload) || other.payload == payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,eventType,description,topic,payload);

@override
String toString() {
  return 'MQTTSavedEvent(timestamp: $timestamp, eventType: $eventType, description: $description, topic: $topic, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $MQTTSavedEventCopyWith<$Res>  {
  factory $MQTTSavedEventCopyWith(MQTTSavedEvent value, $Res Function(MQTTSavedEvent) _then) = _$MQTTSavedEventCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, String eventType, String description, String? topic, String? payload
});




}
/// @nodoc
class _$MQTTSavedEventCopyWithImpl<$Res>
    implements $MQTTSavedEventCopyWith<$Res> {
  _$MQTTSavedEventCopyWithImpl(this._self, this._then);

  final MQTTSavedEvent _self;
  final $Res Function(MQTTSavedEvent) _then;

/// Create a copy of MQTTSavedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? eventType = null,Object? description = null,Object? topic = freezed,Object? payload = freezed,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MQTTSavedEvent].
extension MQTTSavedEventPatterns on MQTTSavedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MQTTSavedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MQTTSavedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MQTTSavedEvent value)  $default,){
final _that = this;
switch (_that) {
case _MQTTSavedEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MQTTSavedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _MQTTSavedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  String eventType,  String description,  String? topic,  String? payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MQTTSavedEvent() when $default != null:
return $default(_that.timestamp,_that.eventType,_that.description,_that.topic,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  String eventType,  String description,  String? topic,  String? payload)  $default,) {final _that = this;
switch (_that) {
case _MQTTSavedEvent():
return $default(_that.timestamp,_that.eventType,_that.description,_that.topic,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  String eventType,  String description,  String? topic,  String? payload)?  $default,) {final _that = this;
switch (_that) {
case _MQTTSavedEvent() when $default != null:
return $default(_that.timestamp,_that.eventType,_that.description,_that.topic,_that.payload);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(anyMap: true)
class _MQTTSavedEvent implements MQTTSavedEvent {
  const _MQTTSavedEvent({required this.timestamp, required this.eventType, required this.description, this.topic, this.payload});
  factory _MQTTSavedEvent.fromJson(Map<String, dynamic> json) => _$MQTTSavedEventFromJson(json);

@override final  DateTime timestamp;
@override final  String eventType;
@override final  String description;
@override final  String? topic;
@override final  String? payload;

/// Create a copy of MQTTSavedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MQTTSavedEventCopyWith<_MQTTSavedEvent> get copyWith => __$MQTTSavedEventCopyWithImpl<_MQTTSavedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MQTTSavedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MQTTSavedEvent&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.description, description) || other.description == description)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.payload, payload) || other.payload == payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,eventType,description,topic,payload);

@override
String toString() {
  return 'MQTTSavedEvent(timestamp: $timestamp, eventType: $eventType, description: $description, topic: $topic, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$MQTTSavedEventCopyWith<$Res> implements $MQTTSavedEventCopyWith<$Res> {
  factory _$MQTTSavedEventCopyWith(_MQTTSavedEvent value, $Res Function(_MQTTSavedEvent) _then) = __$MQTTSavedEventCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, String eventType, String description, String? topic, String? payload
});




}
/// @nodoc
class __$MQTTSavedEventCopyWithImpl<$Res>
    implements _$MQTTSavedEventCopyWith<$Res> {
  __$MQTTSavedEventCopyWithImpl(this._self, this._then);

  final _MQTTSavedEvent _self;
  final $Res Function(_MQTTSavedEvent) _then;

/// Create a copy of MQTTSavedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? eventType = null,Object? description = null,Object? topic = freezed,Object? payload = freezed,}) {
  return _then(_MQTTSavedEvent(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
