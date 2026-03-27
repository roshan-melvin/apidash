// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'websocket_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebSocketSavedMessage {

 String get payload; bool get isText; DateTime get timestamp; bool get isIncoming;
/// Create a copy of WebSocketSavedMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebSocketSavedMessageCopyWith<WebSocketSavedMessage> get copyWith => _$WebSocketSavedMessageCopyWithImpl<WebSocketSavedMessage>(this as WebSocketSavedMessage, _$identity);

  /// Serializes this WebSocketSavedMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebSocketSavedMessage&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.isText, isText) || other.isText == isText)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isIncoming, isIncoming) || other.isIncoming == isIncoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,payload,isText,timestamp,isIncoming);

@override
String toString() {
  return 'WebSocketSavedMessage(payload: $payload, isText: $isText, timestamp: $timestamp, isIncoming: $isIncoming)';
}


}

/// @nodoc
abstract mixin class $WebSocketSavedMessageCopyWith<$Res>  {
  factory $WebSocketSavedMessageCopyWith(WebSocketSavedMessage value, $Res Function(WebSocketSavedMessage) _then) = _$WebSocketSavedMessageCopyWithImpl;
@useResult
$Res call({
 String payload, bool isText, DateTime timestamp, bool isIncoming
});




}
/// @nodoc
class _$WebSocketSavedMessageCopyWithImpl<$Res>
    implements $WebSocketSavedMessageCopyWith<$Res> {
  _$WebSocketSavedMessageCopyWithImpl(this._self, this._then);

  final WebSocketSavedMessage _self;
  final $Res Function(WebSocketSavedMessage) _then;

/// Create a copy of WebSocketSavedMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? payload = null,Object? isText = null,Object? timestamp = null,Object? isIncoming = null,}) {
  return _then(_self.copyWith(
payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,isText: null == isText ? _self.isText : isText // ignore: cast_nullable_to_non_nullable
as bool,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isIncoming: null == isIncoming ? _self.isIncoming : isIncoming // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WebSocketSavedMessage].
extension WebSocketSavedMessagePatterns on WebSocketSavedMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebSocketSavedMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebSocketSavedMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebSocketSavedMessage value)  $default,){
final _that = this;
switch (_that) {
case _WebSocketSavedMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebSocketSavedMessage value)?  $default,){
final _that = this;
switch (_that) {
case _WebSocketSavedMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String payload,  bool isText,  DateTime timestamp,  bool isIncoming)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebSocketSavedMessage() when $default != null:
return $default(_that.payload,_that.isText,_that.timestamp,_that.isIncoming);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String payload,  bool isText,  DateTime timestamp,  bool isIncoming)  $default,) {final _that = this;
switch (_that) {
case _WebSocketSavedMessage():
return $default(_that.payload,_that.isText,_that.timestamp,_that.isIncoming);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String payload,  bool isText,  DateTime timestamp,  bool isIncoming)?  $default,) {final _that = this;
switch (_that) {
case _WebSocketSavedMessage() when $default != null:
return $default(_that.payload,_that.isText,_that.timestamp,_that.isIncoming);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, anyMap: true)
class _WebSocketSavedMessage implements WebSocketSavedMessage {
  const _WebSocketSavedMessage({required this.payload, required this.isText, required this.timestamp, required this.isIncoming});
  factory _WebSocketSavedMessage.fromJson(Map<String, dynamic> json) => _$WebSocketSavedMessageFromJson(json);

@override final  String payload;
@override final  bool isText;
@override final  DateTime timestamp;
@override final  bool isIncoming;

/// Create a copy of WebSocketSavedMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebSocketSavedMessageCopyWith<_WebSocketSavedMessage> get copyWith => __$WebSocketSavedMessageCopyWithImpl<_WebSocketSavedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebSocketSavedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebSocketSavedMessage&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.isText, isText) || other.isText == isText)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isIncoming, isIncoming) || other.isIncoming == isIncoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,payload,isText,timestamp,isIncoming);

@override
String toString() {
  return 'WebSocketSavedMessage(payload: $payload, isText: $isText, timestamp: $timestamp, isIncoming: $isIncoming)';
}


}

/// @nodoc
abstract mixin class _$WebSocketSavedMessageCopyWith<$Res> implements $WebSocketSavedMessageCopyWith<$Res> {
  factory _$WebSocketSavedMessageCopyWith(_WebSocketSavedMessage value, $Res Function(_WebSocketSavedMessage) _then) = __$WebSocketSavedMessageCopyWithImpl;
@override @useResult
$Res call({
 String payload, bool isText, DateTime timestamp, bool isIncoming
});




}
/// @nodoc
class __$WebSocketSavedMessageCopyWithImpl<$Res>
    implements _$WebSocketSavedMessageCopyWith<$Res> {
  __$WebSocketSavedMessageCopyWithImpl(this._self, this._then);

  final _WebSocketSavedMessage _self;
  final $Res Function(_WebSocketSavedMessage) _then;

/// Create a copy of WebSocketSavedMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payload = null,Object? isText = null,Object? timestamp = null,Object? isIncoming = null,}) {
  return _then(_WebSocketSavedMessage(
payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,isText: null == isText ? _self.isText : isText // ignore: cast_nullable_to_non_nullable
as bool,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isIncoming: null == isIncoming ? _self.isIncoming : isIncoming // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$WebSocketSavedEvent {

 DateTime get timestamp; String get eventType; String get description;
/// Create a copy of WebSocketSavedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebSocketSavedEventCopyWith<WebSocketSavedEvent> get copyWith => _$WebSocketSavedEventCopyWithImpl<WebSocketSavedEvent>(this as WebSocketSavedEvent, _$identity);

  /// Serializes this WebSocketSavedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebSocketSavedEvent&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,eventType,description);

@override
String toString() {
  return 'WebSocketSavedEvent(timestamp: $timestamp, eventType: $eventType, description: $description)';
}


}

/// @nodoc
abstract mixin class $WebSocketSavedEventCopyWith<$Res>  {
  factory $WebSocketSavedEventCopyWith(WebSocketSavedEvent value, $Res Function(WebSocketSavedEvent) _then) = _$WebSocketSavedEventCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, String eventType, String description
});




}
/// @nodoc
class _$WebSocketSavedEventCopyWithImpl<$Res>
    implements $WebSocketSavedEventCopyWith<$Res> {
  _$WebSocketSavedEventCopyWithImpl(this._self, this._then);

  final WebSocketSavedEvent _self;
  final $Res Function(WebSocketSavedEvent) _then;

/// Create a copy of WebSocketSavedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? eventType = null,Object? description = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebSocketSavedEvent].
extension WebSocketSavedEventPatterns on WebSocketSavedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebSocketSavedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebSocketSavedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebSocketSavedEvent value)  $default,){
final _that = this;
switch (_that) {
case _WebSocketSavedEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebSocketSavedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _WebSocketSavedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  String eventType,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebSocketSavedEvent() when $default != null:
return $default(_that.timestamp,_that.eventType,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  String eventType,  String description)  $default,) {final _that = this;
switch (_that) {
case _WebSocketSavedEvent():
return $default(_that.timestamp,_that.eventType,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  String eventType,  String description)?  $default,) {final _that = this;
switch (_that) {
case _WebSocketSavedEvent() when $default != null:
return $default(_that.timestamp,_that.eventType,_that.description);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, anyMap: true)
class _WebSocketSavedEvent implements WebSocketSavedEvent {
  const _WebSocketSavedEvent({required this.timestamp, required this.eventType, required this.description});
  factory _WebSocketSavedEvent.fromJson(Map<String, dynamic> json) => _$WebSocketSavedEventFromJson(json);

@override final  DateTime timestamp;
@override final  String eventType;
@override final  String description;

/// Create a copy of WebSocketSavedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebSocketSavedEventCopyWith<_WebSocketSavedEvent> get copyWith => __$WebSocketSavedEventCopyWithImpl<_WebSocketSavedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebSocketSavedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebSocketSavedEvent&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,eventType,description);

@override
String toString() {
  return 'WebSocketSavedEvent(timestamp: $timestamp, eventType: $eventType, description: $description)';
}


}

/// @nodoc
abstract mixin class _$WebSocketSavedEventCopyWith<$Res> implements $WebSocketSavedEventCopyWith<$Res> {
  factory _$WebSocketSavedEventCopyWith(_WebSocketSavedEvent value, $Res Function(_WebSocketSavedEvent) _then) = __$WebSocketSavedEventCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, String eventType, String description
});




}
/// @nodoc
class __$WebSocketSavedEventCopyWithImpl<$Res>
    implements _$WebSocketSavedEventCopyWith<$Res> {
  __$WebSocketSavedEventCopyWithImpl(this._self, this._then);

  final _WebSocketSavedEvent _self;
  final $Res Function(_WebSocketSavedEvent) _then;

/// Create a copy of WebSocketSavedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? eventType = null,Object? description = null,}) {
  return _then(_WebSocketSavedEvent(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WebSocketRequestModel {

 String get url; List<NameValueModel>? get requestHeaders; List<WebSocketSavedMessage> get savedMessages; List<WebSocketSavedEvent> get savedEventLog; int get requestTabIndex; int get filterIndex; int get pingInterval;
/// Create a copy of WebSocketRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebSocketRequestModelCopyWith<WebSocketRequestModel> get copyWith => _$WebSocketRequestModelCopyWithImpl<WebSocketRequestModel>(this as WebSocketRequestModel, _$identity);

  /// Serializes this WebSocketRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebSocketRequestModel&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.requestHeaders, requestHeaders)&&const DeepCollectionEquality().equals(other.savedMessages, savedMessages)&&const DeepCollectionEquality().equals(other.savedEventLog, savedEventLog)&&(identical(other.requestTabIndex, requestTabIndex) || other.requestTabIndex == requestTabIndex)&&(identical(other.filterIndex, filterIndex) || other.filterIndex == filterIndex)&&(identical(other.pingInterval, pingInterval) || other.pingInterval == pingInterval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,const DeepCollectionEquality().hash(requestHeaders),const DeepCollectionEquality().hash(savedMessages),const DeepCollectionEquality().hash(savedEventLog),requestTabIndex,filterIndex,pingInterval);

@override
String toString() {
  return 'WebSocketRequestModel(url: $url, requestHeaders: $requestHeaders, savedMessages: $savedMessages, savedEventLog: $savedEventLog, requestTabIndex: $requestTabIndex, filterIndex: $filterIndex, pingInterval: $pingInterval)';
}


}

/// @nodoc
abstract mixin class $WebSocketRequestModelCopyWith<$Res>  {
  factory $WebSocketRequestModelCopyWith(WebSocketRequestModel value, $Res Function(WebSocketRequestModel) _then) = _$WebSocketRequestModelCopyWithImpl;
@useResult
$Res call({
 String url, List<NameValueModel>? requestHeaders, List<WebSocketSavedMessage> savedMessages, List<WebSocketSavedEvent> savedEventLog, int requestTabIndex, int filterIndex, int pingInterval
});




}
/// @nodoc
class _$WebSocketRequestModelCopyWithImpl<$Res>
    implements $WebSocketRequestModelCopyWith<$Res> {
  _$WebSocketRequestModelCopyWithImpl(this._self, this._then);

  final WebSocketRequestModel _self;
  final $Res Function(WebSocketRequestModel) _then;

/// Create a copy of WebSocketRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? requestHeaders = freezed,Object? savedMessages = null,Object? savedEventLog = null,Object? requestTabIndex = null,Object? filterIndex = null,Object? pingInterval = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,requestHeaders: freezed == requestHeaders ? _self.requestHeaders : requestHeaders // ignore: cast_nullable_to_non_nullable
as List<NameValueModel>?,savedMessages: null == savedMessages ? _self.savedMessages : savedMessages // ignore: cast_nullable_to_non_nullable
as List<WebSocketSavedMessage>,savedEventLog: null == savedEventLog ? _self.savedEventLog : savedEventLog // ignore: cast_nullable_to_non_nullable
as List<WebSocketSavedEvent>,requestTabIndex: null == requestTabIndex ? _self.requestTabIndex : requestTabIndex // ignore: cast_nullable_to_non_nullable
as int,filterIndex: null == filterIndex ? _self.filterIndex : filterIndex // ignore: cast_nullable_to_non_nullable
as int,pingInterval: null == pingInterval ? _self.pingInterval : pingInterval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WebSocketRequestModel].
extension WebSocketRequestModelPatterns on WebSocketRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebSocketRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebSocketRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebSocketRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _WebSocketRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebSocketRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebSocketRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  List<NameValueModel>? requestHeaders,  List<WebSocketSavedMessage> savedMessages,  List<WebSocketSavedEvent> savedEventLog,  int requestTabIndex,  int filterIndex,  int pingInterval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebSocketRequestModel() when $default != null:
return $default(_that.url,_that.requestHeaders,_that.savedMessages,_that.savedEventLog,_that.requestTabIndex,_that.filterIndex,_that.pingInterval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  List<NameValueModel>? requestHeaders,  List<WebSocketSavedMessage> savedMessages,  List<WebSocketSavedEvent> savedEventLog,  int requestTabIndex,  int filterIndex,  int pingInterval)  $default,) {final _that = this;
switch (_that) {
case _WebSocketRequestModel():
return $default(_that.url,_that.requestHeaders,_that.savedMessages,_that.savedEventLog,_that.requestTabIndex,_that.filterIndex,_that.pingInterval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  List<NameValueModel>? requestHeaders,  List<WebSocketSavedMessage> savedMessages,  List<WebSocketSavedEvent> savedEventLog,  int requestTabIndex,  int filterIndex,  int pingInterval)?  $default,) {final _that = this;
switch (_that) {
case _WebSocketRequestModel() when $default != null:
return $default(_that.url,_that.requestHeaders,_that.savedMessages,_that.savedEventLog,_that.requestTabIndex,_that.filterIndex,_that.pingInterval);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, anyMap: true)
class _WebSocketRequestModel implements WebSocketRequestModel {
  const _WebSocketRequestModel({this.url = "", final  List<NameValueModel>? requestHeaders, final  List<WebSocketSavedMessage> savedMessages = const [], final  List<WebSocketSavedEvent> savedEventLog = const [], this.requestTabIndex = 0, this.filterIndex = 0, this.pingInterval = 0}): _requestHeaders = requestHeaders,_savedMessages = savedMessages,_savedEventLog = savedEventLog;
  factory _WebSocketRequestModel.fromJson(Map<String, dynamic> json) => _$WebSocketRequestModelFromJson(json);

@override@JsonKey() final  String url;
 final  List<NameValueModel>? _requestHeaders;
@override List<NameValueModel>? get requestHeaders {
  final value = _requestHeaders;
  if (value == null) return null;
  if (_requestHeaders is EqualUnmodifiableListView) return _requestHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<WebSocketSavedMessage> _savedMessages;
@override@JsonKey() List<WebSocketSavedMessage> get savedMessages {
  if (_savedMessages is EqualUnmodifiableListView) return _savedMessages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedMessages);
}

 final  List<WebSocketSavedEvent> _savedEventLog;
@override@JsonKey() List<WebSocketSavedEvent> get savedEventLog {
  if (_savedEventLog is EqualUnmodifiableListView) return _savedEventLog;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedEventLog);
}

@override@JsonKey() final  int requestTabIndex;
@override@JsonKey() final  int filterIndex;
@override@JsonKey() final  int pingInterval;

/// Create a copy of WebSocketRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebSocketRequestModelCopyWith<_WebSocketRequestModel> get copyWith => __$WebSocketRequestModelCopyWithImpl<_WebSocketRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebSocketRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebSocketRequestModel&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other._requestHeaders, _requestHeaders)&&const DeepCollectionEquality().equals(other._savedMessages, _savedMessages)&&const DeepCollectionEquality().equals(other._savedEventLog, _savedEventLog)&&(identical(other.requestTabIndex, requestTabIndex) || other.requestTabIndex == requestTabIndex)&&(identical(other.filterIndex, filterIndex) || other.filterIndex == filterIndex)&&(identical(other.pingInterval, pingInterval) || other.pingInterval == pingInterval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,const DeepCollectionEquality().hash(_requestHeaders),const DeepCollectionEquality().hash(_savedMessages),const DeepCollectionEquality().hash(_savedEventLog),requestTabIndex,filterIndex,pingInterval);

@override
String toString() {
  return 'WebSocketRequestModel(url: $url, requestHeaders: $requestHeaders, savedMessages: $savedMessages, savedEventLog: $savedEventLog, requestTabIndex: $requestTabIndex, filterIndex: $filterIndex, pingInterval: $pingInterval)';
}


}

/// @nodoc
abstract mixin class _$WebSocketRequestModelCopyWith<$Res> implements $WebSocketRequestModelCopyWith<$Res> {
  factory _$WebSocketRequestModelCopyWith(_WebSocketRequestModel value, $Res Function(_WebSocketRequestModel) _then) = __$WebSocketRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String url, List<NameValueModel>? requestHeaders, List<WebSocketSavedMessage> savedMessages, List<WebSocketSavedEvent> savedEventLog, int requestTabIndex, int filterIndex, int pingInterval
});




}
/// @nodoc
class __$WebSocketRequestModelCopyWithImpl<$Res>
    implements _$WebSocketRequestModelCopyWith<$Res> {
  __$WebSocketRequestModelCopyWithImpl(this._self, this._then);

  final _WebSocketRequestModel _self;
  final $Res Function(_WebSocketRequestModel) _then;

/// Create a copy of WebSocketRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? requestHeaders = freezed,Object? savedMessages = null,Object? savedEventLog = null,Object? requestTabIndex = null,Object? filterIndex = null,Object? pingInterval = null,}) {
  return _then(_WebSocketRequestModel(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,requestHeaders: freezed == requestHeaders ? _self._requestHeaders : requestHeaders // ignore: cast_nullable_to_non_nullable
as List<NameValueModel>?,savedMessages: null == savedMessages ? _self._savedMessages : savedMessages // ignore: cast_nullable_to_non_nullable
as List<WebSocketSavedMessage>,savedEventLog: null == savedEventLog ? _self._savedEventLog : savedEventLog // ignore: cast_nullable_to_non_nullable
as List<WebSocketSavedEvent>,requestTabIndex: null == requestTabIndex ? _self.requestTabIndex : requestTabIndex // ignore: cast_nullable_to_non_nullable
as int,filterIndex: null == filterIndex ? _self.filterIndex : filterIndex // ignore: cast_nullable_to_non_nullable
as int,pingInterval: null == pingInterval ? _self.pingInterval : pingInterval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
