library store_selected_conversation;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crowdleague/actions/redux_action.dart';
import 'package:crowdleague/models/conversations/conversation_summary.dart';
import 'package:crowdleague/utils/serializers.dart';
import 'package:meta/meta.dart';

part 'store_selected_conversation.g.dart';

abstract class StoreSelectedConversation extends Object
    with ReduxAction
    implements
        Built<StoreSelectedConversation, StoreSelectedConversationBuilder> {
  ConversationSummary get summary;

  StoreSelectedConversation._();

  factory StoreSelectedConversation({@required ConversationSummary summary}) =
      _$StoreSelectedConversation._;

  factory StoreSelectedConversation.by(
          [void Function(StoreSelectedConversationBuilder) updates]) =
      _$StoreSelectedConversation;

  Object toJson() =>
      serializers.serializeWith(StoreSelectedConversation.serializer, this);

  static StoreSelectedConversation fromJson(String jsonString) =>
      serializers.deserializeWith(
          StoreSelectedConversation.serializer, json.decode(jsonString));

  static Serializer<StoreSelectedConversation> get serializer =>
      _$storeSelectedConversationSerializer;

  @override
  String toString() => 'STORE_SELECTED_CONVERSATION';
}
