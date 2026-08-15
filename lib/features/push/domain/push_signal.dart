class PushSignal {
  const PushSignal({required this.notificationId, required this.type});

  final int notificationId;
  final String type;

  static PushSignal? fromData(Map<String, dynamic> data) {
    final rawId = data['notification_id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final type = data['type'];
    if (id == null || id <= 0 || type is! String || type.trim().isEmpty) {
      return null;
    }
    return PushSignal(notificationId: id, type: type);
  }
}

enum PushPermission { authorized, denied, unavailable }
