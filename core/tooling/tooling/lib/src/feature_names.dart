import 'package:tooling/src/command_failure.dart';

/// The folder names a feature may never use: they are the reserved
/// sub-folders of a feature (see `apps/app/README.md`, "Feature structure").
const List<String> reservedFeatureSegments = <String>[
  'widgets',
  'layouts',
  'steps',
];

final RegExp _snakeCase = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

/// Every name derived from a feature path such as `settings/notifications`.
///
/// Naming rule: the feature is named after the **last** path segment only
/// (`notifications` -> `NotificationsView`, `notifications_view.dart`,
/// `NotificationsRoute`); the leading segments are the parent features it
/// nests under and appear in the folder and the route path, never in names.
class FeatureNames {
  FeatureNames._(this.segments);

  /// Parses [rawPath], throwing a [CommandFailure] naming the first problem:
  /// an empty path or segment, a segment that is not snake_case, or a
  /// reserved segment.
  factory FeatureNames.parse(String rawPath) {
    final segments = rawPath.split('/');
    for (final segment in segments) {
      if (segment.isEmpty) {
        throw CommandFailure(
          'Invalid feature path "$rawPath": empty segment (no leading, '
          'trailing or doubled "/").',
        );
      }
      if (reservedFeatureSegments.contains(segment)) {
        throw CommandFailure(
          'Invalid feature path "$rawPath": "$segment" is a reserved '
          'feature-folder name (${reservedFeatureSegments.join(', ')}).',
        );
      }
      if (!_snakeCase.hasMatch(segment)) {
        throw CommandFailure(
          'Invalid feature path "$rawPath": segment "$segment" is not '
          'snake_case (lowercase letters, digits and single underscores, '
          'starting with a letter).',
        );
      }
    }

    return FeatureNames._(segments);
  }

  /// The path segments, outermost parent first.
  final List<String> segments;

  /// The feature's own snake_case name: the last segment.
  String get name => segments.last;

  /// The parent feature folders (every segment but the last).
  List<String> get parentSegments => segments.sublist(0, segments.length - 1);

  /// The slash-joined path, e.g. `settings/notifications`.
  String get path => segments.join('/');

  /// The PascalCase class-name stem, e.g. `Notifications`.
  String get pascal => name.split('_').map(_capitalize).join();

  /// A human-readable title, e.g. `Notifications` or `Sign In`.
  String get title => name.split('_').map(_capitalize).join(' ');

  /// The generated route class, e.g. `NotificationsRoute`.
  String get routeClass => '${pascal}Route';

  /// The route path: every segment kebab-cased and slash-joined, e.g.
  /// `settings/notifications` or `settings/push-alerts`.
  String get routePath => segments.map((s) => s.replaceAll('_', '-')).join('/');

  static String _capitalize(String word) =>
      word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';
}
