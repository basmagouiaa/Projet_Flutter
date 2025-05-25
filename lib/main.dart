import 'package:flutter/material.dart';
import 'package:projet/service/AppSettings.dart';
import 'package:projet/service/ServiceNotification.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'page/Home.dart';
import 'page/Settings.dart';
import 'page/Classement.dart';
import 'page/Result.dart';
import 'page/Question.dart';
import 'page_lottie.dart';
import 'service/translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'daily_notification_channel',
        channelName: 'Daily Notifications',
        channelDescription: 'Notifications for daily reminders',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.white,
      ),
    ],
  );

  final appSettings = AppSettings();
  await appSettings.loadPreferences();

  final localisation = LocalizationService();
  await localisation.load(appSettings.language);

  appSettings.onLanguageChanged = (String newLang) async {
    await localisation.load(newLang);
  };

  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  final prefs = await SharedPreferences.getInstance();
  final hour = prefs.getInt('notif_hour') ?? 12;
  final minute = prefs.getInt('notif_minute') ?? 0;

  ServiceNotification().programmerNotificationQuotidienne(heure: hour, minute: minute);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appSettings),
        Provider<LocalizationService>.value(value: localisation),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appSettings.darkMode ? ThemeData.dark() : ThemeData.light(),
      locale: Locale(appSettings.language),
      home: const page1(),
      routes: {
        '/home': (context) => Accueil(),
        '/settings': (context) => const SettingsPage(),
        '/question': (context) => const Question(nombreQuestions: 0, categorie: '', difficulte: ''),
        '/result': (context) => const PageResultats(reponsesUtilisateur: [], difficulte: '', nombreQuestions: 0, categorie: ''),
        '/Classement': (context) => Classement(numQuestions: 0, category: '', difficulty: ''),
      },
    );
  }
}
