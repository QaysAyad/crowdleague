library connect_to_messages_problem;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:crowdleague/models/problems/problem_base.dart';
import 'package:crowdleague/utils/serializers.dart';

part 'connect_to_messages_problem.g.dart';

abstract class ConnectToMessagesProblem
    implements
        ProblemBase,
        Built<ConnectToMessagesProblem, ConnectToMessagesProblemBuilder> {
  ConnectToMessagesProblem._();

  factory ConnectToMessagesProblem(
      {String message,
      String trace,
      BuiltMap<String, Object> info}) = _$ConnectToMessagesProblem._;

  factory ConnectToMessagesProblem.by(
          [void Function(ConnectToMessagesProblemBuilder) updates]) =
      _$ConnectToMessagesProblem;

  Object toJson() =>
      serializers.serializeWith(ConnectToMessagesProblem.serializer, this);

  static ConnectToMessagesProblem fromJson(String jsonString) =>
      serializers.deserializeWith(
          ConnectToMessagesProblem.serializer, json.decode(jsonString));

  static Serializer<ConnectToMessagesProblem> get serializer =>
      _$connectToMessagesProblemSerializer;
}
