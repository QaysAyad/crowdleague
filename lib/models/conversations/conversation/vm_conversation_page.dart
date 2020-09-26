library vm_conversation_page;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crowdleague/models/conversations/conversation/message.dart';
import 'package:crowdleague/models/conversations/conversation_summary.dart';
import 'package:crowdleague/utils/serializers.dart';
import 'package:meta/meta.dart';

part 'vm_conversation_page.g.dart';

abstract class VmConversationPage
    implements Built<VmConversationPage, VmConversationPageBuilder> {
  @nullable
  ConversationSummary get summary;
  BuiltList<Message> get messages;
  String get messageText;

  VmConversationPage._();

  factory VmConversationPage(
      {@required ConversationSummary summary,
      @required BuiltList<Message> messages,
      @required String messageText}) = _$VmConversationPage._;

  factory VmConversationPage.by(
          [void Function(VmConversationPageBuilder) updates]) =
      _$VmConversationPage;

  Object toJson() =>
      serializers.serializeWith(VmConversationPage.serializer, this);

  static VmConversationPage fromJson(String jsonString) => serializers
      .deserializeWith(VmConversationPage.serializer, json.decode(jsonString));

  static Serializer<VmConversationPage> get serializer =>
      _$vmConversationPageSerializer;
}
