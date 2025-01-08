import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScrn extends StatefulWidget {
  const SettingsScrn({super.key, required this.isDarkModeNotifier});

  final ValueNotifier<bool> isDarkModeNotifier;

  @override
  State<SettingsScrn> createState() => _SettingsScrnState();
}

class _SettingsScrnState extends State<SettingsScrn> {
  @override
  void initState() {
    super.initState();
  }

  // Save theme preference to SharedPreferences
  Future<void> _setThemePreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', value);
  }

  // Toggle theme mode
  void _toggleTheme(bool value) {
    widget.isDarkModeNotifier.value = value;
    _setThemePreference(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Image.asset(
          'assets/logos/miaba_logo.png',
          height: 90,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Enable Dark Mode'),
              trailing: Switch(
                value: widget.isDarkModeNotifier.value,
                onChanged: _toggleTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
