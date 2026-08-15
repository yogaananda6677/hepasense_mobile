class JakartaDateTime {
  JakartaDateTime._();

  static DateTime? parse(String value) {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$',
    ).firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }

  static String display(String value) {
    final date = parse(value);
    if (date == null) return 'Waktu tidak tersedia';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour.$minute WIB';
  }
}
