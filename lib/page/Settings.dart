import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/AppSettings.dart';
import '../service/ServiceNotification.dart';
import '../service/translate.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadNotificationTime();
  }

  Future<void> _loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notif_hour') ?? 12;
    final minute = prefs.getInt('notif_minute') ?? 0;
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notif_hour', picked.hour);
      await prefs.setInt('notif_minute', picked.minute);
      ServiceNotification().programmerNotificationQuotidienne(
        heure: picked.hour,
        minute: picked.minute,
      );
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final localisation = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final List<String> _languages = ['fr', 'en', 'ar'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(localisation.translate('settings.title')),
        backgroundColor: Colors.deepPurple.withOpacity(0.9),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              _buildSwitchTile(
                icon: Icons.dark_mode,
                title: localisation.translate('settings.darkMode'),
                value: appSettings.darkMode,
                onChanged: (val) => appSettings.updateDarkMode(val),
              ),
              _buildSwitchTile(
                icon: Icons.music_note,
                title: localisation.translate('settings.music'),
                value: appSettings.music,
                onChanged: (val) => appSettings.updateMusic(val),
              ),
              _buildTimeTile(localisation),
              const SizedBox(height: 30),
              Text(
                localisation.translate('settings.language'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _languages.map((lang) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => appSettings.updateLanguage(lang),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: appSettings.language == lang
                              ? theme.colorScheme.primary
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              lang == 'fr'
                                  ? Icons.language
                                  : lang == 'en'
                                  ? Icons.translate
                                  : Icons.g_translate,
                              color: appSettings.language == lang
                                  ? Colors.white
                                  : Colors.deepPurple,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang.toUpperCase(),
                              style: TextStyle(
                                color: appSettings.language == lang
                                    ? Colors.white
                                    : Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildTimeTile(LocalizationService localisation) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: const Icon(Icons.notifications_active, color: Colors.white),
      title: Text(localisation.translate('settings.notificationHour'), style: const TextStyle(color: Colors.white)),
      subtitle: _selectedTime != null
          ? Text('⏰ ${_selectedTime!.format(context)}', style: const TextStyle(color: Colors.white70))
          : null,
      onTap: () => _selectTime(context),
    );
  }
}
