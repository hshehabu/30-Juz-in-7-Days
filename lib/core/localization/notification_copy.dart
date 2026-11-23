/// Localized notification text.
///
/// Notifications are scheduled outside the widget tree (and the action button
/// may be handled in a background isolate), so `easy_localization` lookups
/// are not available there. This small table mirrors the app languages.
class NotificationCopy {
  final String languageCode;
  final String portionTitle;
  final String portionBodyTemplate;
  final String markCompletedAction;
  final String followUpTitle;
  final String followUpBodyTemplate;
  final String habitTitle;
  final String habitBody;
  final String completionTitle;
  final String completionBody;
  final String channelName;
  final String channelDescription;

  const NotificationCopy._({
    required this.languageCode,
    required this.portionTitle,
    required this.portionBodyTemplate,
    required this.markCompletedAction,
    required this.followUpTitle,
    required this.followUpBodyTemplate,
    required this.habitTitle,
    required this.habitBody,
    required this.completionTitle,
    required this.completionBody,
    required this.channelName,
    required this.channelDescription,
  });

  bool get isArabic => languageCode == 'ar';

  static const NotificationCopy en = NotificationCopy._(
    languageCode: 'en',
    portionTitle: 'Daily Qur\'an Portion 📖',
    portionBodyTemplate: 'Day {day}: {range}',
    markCompletedAction: 'Mark as completed',
    followUpTitle: 'Still time to read today 🌙',
    followUpBodyTemplate: 'Day {day} is still waiting: {range}',
    habitTitle: 'Daily Qur\'an Reminder 📖',
    habitBody: 'Time for your daily Qur\'an reading. Keep up your blessed habit!',
    completionTitle: 'Alhamdulillah',
    completionBody: 'You have completed your 7-day Qur\'an khatmah!',
    channelName: 'Daily Khatmah Reminders',
    channelDescription: 'Gentle daily reminders for your 7-day Qur\'an completion',
  );

  static const NotificationCopy ar = NotificationCopy._(
    languageCode: 'ar',
    portionTitle: 'ورد اليوم من القرآن 📖',
    portionBodyTemplate: 'اليوم {day}: {range}',
    markCompletedAction: 'تمت القراءة',
    followUpTitle: 'ما زال هناك وقت للقراءة اليوم 🌙',
    followUpBodyTemplate: 'ورد اليوم {day} بانتظارك: {range}',
    habitTitle: 'تذكير القراءة اليومية 📖',
    habitBody: 'حان وقت وردك اليومي من القرآن. ثبّتك الله على هذه العادة المباركة!',
    completionTitle: 'الحمد لله',
    completionBody: 'لقد أتممت ختمة القرآن في سبعة أيام!',
    channelName: 'تذكيرات الختمة اليومية',
    channelDescription: 'تذكيرات يومية لطيفة لختم القرآن في سبعة أيام',
  );

  static NotificationCopy of(String? languageCode) =>
      languageCode == 'ar' ? ar : en;

  String portionBody(int day, String range) =>
      portionBodyTemplate.replaceAll('{day}', '$day').replaceAll('{range}', range);

  String followUpBody(int day, String range) =>
      followUpBodyTemplate.replaceAll('{day}', '$day').replaceAll('{range}', range);
}
