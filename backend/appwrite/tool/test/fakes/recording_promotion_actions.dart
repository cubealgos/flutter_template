import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/promoter.dart';

class RecordingPromotionActions implements PromotionActions {
  RecordingPromotionActions({this.failFunction});

  final String? failFunction;
  final List<String> calls = <String>[];

  @override
  Future<List<String>> provision({required bool dryRun}) async {
    calls.add('provision(dry=$dryRun)');

    return <String>['created table "x"'];
  }

  @override
  Future<bool> deployFunction(
    FunctionSchema function, {
    required bool dryRun,
  }) async {
    calls.add('function ${function.id}(dry=$dryRun)');

    return function.id != failFunction;
  }

  @override
  Future<bool> deploySite(SiteSchema site, {required bool dryRun}) async {
    calls.add('site ${site.id}(dry=$dryRun)');

    return true;
  }
}
