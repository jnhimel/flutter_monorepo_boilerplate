/// Shared foundation package: theme, widget starter set, network client,
/// storage services, DI, routing base, logging, and security stubs.
library;

export 'src/di/service_locator.dart';
export 'src/error/app_failure.dart';
export 'src/error/result.dart';
export 'src/logging/app_logger.dart';
export 'src/logging/error_reporter.dart';
export 'src/network/app_exception.dart';
export 'src/network/dio_client.dart';
export 'src/routing/app_route_paths.dart';
export 'src/routing/app_shell_scaffold.dart';
export 'src/security/security_config.dart';
export 'src/storage/database/app_database.dart';
export 'src/storage/hive_service.dart';
export 'src/storage/preferences_service.dart';
export 'src/storage/secure_storage_service.dart';
export 'src/theme/app_colors.dart';
export 'src/theme/app_text_theme.dart';
export 'src/theme/app_theme.dart';
export 'src/widgets/app_app_bar.dart';
export 'src/widgets/app_button.dart';
export 'src/widgets/app_empty_state.dart';
export 'src/widgets/app_error_view.dart';
export 'src/widgets/app_loading_indicator.dart';
export 'src/widgets/app_text.dart';
export 'src/widgets/app_text_field.dart';
