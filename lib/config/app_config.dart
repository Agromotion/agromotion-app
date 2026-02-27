class AppConfig {
  static const String robotId = String.fromEnvironment(
    'ROBOT_ID',
    defaultValue: 'agromotion-robot-01',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );

  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
  );
}
