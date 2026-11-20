import 'package:appwrite_tool/src/git_inspector.dart';

class FakeGitInspector implements GitInspector {
  FakeGitInspector({this.tag = 'app-v1.0.0', this.clean = true});

  final String? tag;
  final bool clean;

  @override
  Future<String?> exactTag() async => tag;

  @override
  Future<String> headSha() async => 'abc123';

  @override
  Future<bool> isClean() async => clean;
}
