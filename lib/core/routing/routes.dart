abstract class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String mfa = '/mfa';
  static const String home = '/';
  static const String screeningHistory = '/screenings';
  static const String screeningDetail = '/screenings/:id';
  static const String notifications = '/notifications';
  static const String education = '/education';
  static const String aiAssistant = '/ai-assistant';
  static const String aiConversation = '/ai-assistant/conversations/:id';
  static const String educationDetail = '/education/:slug';
  static const String account = '/account';
  static const String editProfile = '/account/edit-profile';
  static const String changePassword = '/account/change-password';
  static const String privacy = '/privacy';
  static const String help = '/help';
  static const String about = '/about';

  static String screeningDetailPath(String id) => '/screenings/$id';
  static String educationDetailPath(String slug) => '/education/$slug';
  static String aiConversationPath(int id) => '/ai-assistant/conversations/$id';
}
