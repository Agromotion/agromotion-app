class AppConfig {
  static const String robotId = String.fromEnvironment(
    'ROBOT_ID',
    defaultValue: 'agromotion-robot-01',
  );
}
