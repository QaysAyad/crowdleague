library vm_conversation_summaries_page;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crowdleague/utils/serializers.dart';
import 'package:meta/meta.dart';

import 'conversation_summary.dart';

part 'vm_conversation_summaries_page.g.dart';

abstract class VmConversationSummariesPage
    implements
        Built<VmConversationSummariesPage, VmConversationSummariesPageBuilder> {
  BuiltList<ConversationSummary> get summaries;

  VmConversationSummariesPage._();

  factory VmConversationSummariesPage(
          {@required BuiltList<ConversationSummary> summaries}) =
      _$VmConversationSummariesPage._;

  factory VmConversationSummariesPage.by(
          [void Function(VmConversationSummariesPageBuilder) updates]) =
      _$VmConversationSummariesPage;

  Object toJson() =>
      serializers.serializeWith(VmConversationSummariesPage.serializer, this);

  static VmConversationSummariesPage fromJson(String jsonString) =>
      serializers.deserializeWith(
          VmConversationSummariesPage.serializer, json.decode(jsonString));

  static Serializer<VmConversationSummariesPage> get serializer =>
      _$vmConversationSummariesPageSerializer;
}
