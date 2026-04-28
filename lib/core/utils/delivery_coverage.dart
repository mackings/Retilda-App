class DeliveryCoverage {
  DeliveryCoverage._();

  static const localStates = ['Ondo State', 'Abia State'];
  static const regionalStates = ['Ekiti State', 'Delta State'];

  static const supportedStatesMessage =
      'Retilda currently delivers in Ondo State, Abia State, Ekiti State, and Delta State only.';

  static bool isUnsupportedStateMessage(String? message) {
    final lower = (message ?? '').toLowerCase();
    return lower.contains('not operational in that state') ||
        lower.contains('not operational') ||
        lower.contains('currently not operational');
  }

  static String userMessage(String? message) {
    final base = (message == null || message.trim().isEmpty)
        ? 'Retilda is not operational in that state.'
        : message.trim();

    if (!isUnsupportedStateMessage(base)) {
      return base;
    }

    return '$base\n\n$supportedStatesMessage\n\nLocal: ${localStates.join(', ')}.\nRegional: ${regionalStates.join(', ')}.';
  }
}
