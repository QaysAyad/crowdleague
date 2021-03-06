library problem_base;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'problem_base.g.dart';

/// This is the base class for all Problems.
/// For an unspecific subclass see [GeneralProblem].
@BuiltValue(instantiable: false)
abstract class ProblemBase {
  String get message;
  String get trace;
  BuiltMap<String, Object> get info;

  ProblemBase rebuild(void Function(ProblemBaseBuilder) updates);
  ProblemBaseBuilder toBuilder();
}
