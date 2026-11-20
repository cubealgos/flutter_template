/// An organisation of several people who share data.
class Team {
  /// Creates a team with [id] and [name].
  const Team({required this.id, required this.name});

  /// The team's ID (Appwrite's team `$id`), also what a team-scoped row
  /// carries.
  final String id;

  /// The team's display name.
  final String name;

  @override
  String toString() => 'Team(id: $id, name: $name)';
}
