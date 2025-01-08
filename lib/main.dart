import 'package:flutter/material.dart';
import 'package:miaba/signin_scrn.dart';
import 'package:miaba/home_scrn.dart';
import 'package:miaba/users_scrn.dart';
import 'package:miaba/user_crt_scrn.dart';
import 'package:miaba/user_edt_scrn.dart';
import 'package:miaba/aliases_scrn.dart';
import 'package:miaba/alias_crt_scrn.dart';
import 'package:miaba/alias_edt_scrn.dart';
import 'package:miaba/domains_scrn.dart';
import 'package:miaba/account_scrn.dart';
import 'package:miaba/settings_scrn.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _getThemePreference();
  }

  // Fetch theme preference from SharedPreferences
  Future<void> _getThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('darkMode') ?? false; // Default to light
    setState(() {
      isDarkModeNotifier.value = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          title: 'MIABA',
          theme: ThemeData(
            brightness: Brightness.light,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            // Handle the '/edit_user' route
            if (settings.name == '/edit_user') {
              final args = settings.arguments as Map<String, dynamic>;
              final userEmail = args['email'] as String?;
              final isAdmin = args['isAdmin'] as bool;

              return MaterialPageRoute(
                builder: (context) => UserEdtScrn(
                  userEmail: userEmail ?? 'default@example.com',
                  isAdmin: isAdmin,
                ),
              );
            }

            // Handle the '/edit_alias' route
            if (settings.name == '/edit_alias') {
              final args = settings.arguments as Map<String, dynamic>?;

              final aliasEmail = args!['alias'] as String?;
              final forwardsTo = List<String>.from(args['forwardsTo'] ?? []);
              final permittedSenders =
                  List<String>.from(args['permittedSenders'] ?? []);

              return MaterialPageRoute(
                builder: (context) => AliasEdtScrn(
                  aliasEmail: aliasEmail ?? 'default@example.com',
                  forwardsTo: forwardsTo,
                  permittedSenders: permittedSenders,
                ),
              );
            }

            // Handle other routes
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                    builder: (context) => const SignInScrn());
              case '/home':
                return MaterialPageRoute(
                    builder: (context) => const HomeScrn());
              case '/users':
                return MaterialPageRoute(
                    builder: (context) => const UsersScrn());
              case '/create_user':
                return MaterialPageRoute(
                    builder: (context) => const UserCrtScrn());
              case '/aliases':
                return MaterialPageRoute(
                    builder: (context) => const AliasesScrn());
              case '/create_alias':
                return MaterialPageRoute(
                    builder: (context) => const AliasCrtScrn());
              case '/domains':
                return MaterialPageRoute(
                    builder: (context) => const DomainsScrn());
              case '/account':
                return MaterialPageRoute(
                    builder: (context) => const AccountScrn());
              case '/settings':
                return MaterialPageRoute(
                  builder: (context) =>
                      SettingsScrn(isDarkModeNotifier: isDarkModeNotifier),
                );
              default:
                return MaterialPageRoute(
                    builder: (context) => const SignInScrn());
            }
          },
        );
      },
    );
  }
}
