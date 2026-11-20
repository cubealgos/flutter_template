/// Backend-agnostic team tenancy: the `TeamService` interface, its models
/// (`Team`, `Membership`, `Invitation`, `MembershipEvent`), the typed
/// `TeamError` hierarchy, `TeamEngine` (the one implementation of the team
/// rules) over a `TeamStore`, and in-memory fakes for screens and tests.
///
/// `backend/appwrite/functions/team_admin` runs `TeamEngine` against Appwrite
/// Teams and tables; `backend/appwrite/adapters`'s `AppwriteTeamService` is
/// the client that calls it. Split into one file per declared type under
/// `src/` (matching this workspace's `prefer_match_file_name` lint) — this
/// file just re-exports all of them, mirroring `core/contracts/auth`.
library;

export 'src/fake_team_backend.dart';
export 'src/fake_team_service.dart';
export 'src/in_memory_team_store.dart';
export 'src/invitation.dart';
export 'src/invitation_status.dart';
export 'src/membership.dart';
export 'src/membership_event.dart';
export 'src/membership_event_type.dart';
export 'src/team.dart';
export 'src/team_actor.dart';
export 'src/team_directory.dart';
export 'src/team_engine.dart';
export 'src/team_error.dart';
export 'src/team_roles.dart';
export 'src/team_service.dart';
export 'src/team_store.dart';
export 'src/team_wire.dart';
