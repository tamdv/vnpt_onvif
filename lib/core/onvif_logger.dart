import 'dart:developer' as developer;

/// Signature for custom logging functions.
///
/// Implement this to integrate with external logging systems (Firebase, Sentry, etc).
typedef LoggerFunction = void Function(String message, {String? name});

/// A centralized, configurable logger for the VNPT ONVIF library.
///
/// This singleton allows you to:
/// - Replace all internal `developer.log()` calls with a custom logging function
/// - Integrate with Firebase, Sentry, or other logging services
/// - Customize log formatting, filtering, or routing
///
/// **Usage:**
///
/// By default, the logger uses Dart's `developer.log`:
/// ```dart
/// // No setup needed - uses developer.log automatically
/// OnvifDiscovery discovery = OnvifDiscovery();
/// await discovery.probe();  // Logs using developer.log
/// ```
///
/// To use a custom logger (e.g., Firebase, Sentry):
/// ```dart
/// // Initialize ONCE before using the library
/// Logger.initialize((message, {name}) {
///   // Custom logging logic here
///   print('[$name] $message');
///   // Or:
///   FirebaseAnalytics.log(name: name, message: message);
/// });
///
/// // Now all library logging uses your custom function
/// OnvifDiscovery discovery = OnvifDiscovery();
/// await discovery.probe();  // Logs using your custom function
/// ```
///
/// **Common integrations:**
///
/// Firebase Analytics:
/// ```dart
/// Logger.initialize((message, {name}) {
///   FirebaseAnalytics.instance.logEvent(
///     name: name ?? 'vnpt_onvif_log',
///     parameters: {'message': message},
///   );
/// });
/// ```
///
/// Sentry:
/// ```dart
/// Logger.initialize((message, {name}) {
///   Sentry.captureMessage(message, level: SentryLevel.info);
/// });
/// ```
///
/// Custom formatter:
/// ```dart
/// Logger.initialize((message, {name}) {
///   final timestamp = DateTime.now().toIso8601String();
///   print('[$timestamp] [$name] $message');
/// });
/// ```
class OnvifLogger {
  static final OnvifLogger _instance = OnvifLogger._private();
  late LoggerFunction _logFunction;

  OnvifLogger._private() {
    // Default: use Dart's developer.log
    _logFunction = (String message, {String? name}) {
      developer.log(message, name: name ?? 'vnpt_onvif');
    };
  }

  /// Gets the singleton instance of the logger.
  static OnvifLogger get instance => _instance;

  /// Initializes the logger with a custom logging function.
  ///
  /// Call this ONCE at application startup, before using any VNPT ONVIF library classes.
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   Logger.initialize((message, {name}) {
  ///     print('[$name] $message');
  ///   });
  ///   runApp(MyApp());
  /// }
  /// ```
  static void initialize(LoggerFunction logFunction) {
    _instance._logFunction = logFunction;
  }

  /// Logs a message using the configured logging function.
  ///
  /// - [message]: The message to log
  /// - [name]: Optional category name (e.g., 'Discovery', 'OnvifClient')
  void log(String message, {String? name}) {
    _logFunction(message, name: name);
  }
}
