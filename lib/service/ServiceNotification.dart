import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/translate.dart';

class ServiceNotification {
  static final ServiceNotification _instance = ServiceNotification._interne();
  factory ServiceNotification() => _instance;

  ServiceNotification._interne();

  Future<void> programmerNotificationQuotidienne({
    required int heure,
    required int minute,
    BuildContext? context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final localisation = context != null
        ? Provider.of<LocalizationService>(context, listen: false)
        : null;

    final String title = localisation?.translate('notification.title') ?? 'Rappel du quiz quotidien';
    final String body = localisation?.translate('notification.body') ?? 'Il est temps de faire votre quiz du jour !';

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 0,
          channelKey: 'daily_notification_channel',
          title: title,
          body: body,
          payload: {'navigate': 'true'},
        ),
        schedule: NotificationCalendar(
          hour: heure,
          minute: minute,
          second: 0,
          millisecond: 0,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
          repeats: true,
        ),
      );
      print("Notification programmée avec succès à $heure:$minute");
    } catch (e) {
      print("Échec de la programmation de la notification : $e");
    }
  }
}
