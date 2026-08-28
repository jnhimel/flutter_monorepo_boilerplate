// Convenience default so `flutter run` with no `-t`/`--flavor` still works
// during local development. Real runs should target a flavor explicitly:
// `flutter run --flavor dev -t lib/main_dev.dart` (see README).
import 'main_dev.dart' as dev_entrypoint;

void main() => dev_entrypoint.main();
