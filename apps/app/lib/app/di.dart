import 'package:app/app/di.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// The app's [GetIt] service locator.
///
/// Every controller resolves its injected services (e.g.
/// `getIt<NavigationService>()`) from this instance, never from a
/// hand-rolled singleton — see `service_module.dart` for what is
/// registered.
final GetIt getIt = GetIt.instance;

/// Registers every dependency `injectable_generator` found (via
/// `@injectable`/`@module` annotations across `lib/`) into [getIt].
///
/// Called once from `main()`, before `runApp`.
@InjectableInit()
void configureDependencies() => getIt.init();
