import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScrn extends StatefulWidget {
  const HomeScrn({super.key});

  @override
  State<HomeScrn> createState() => _HomeScrnState();
}

class _HomeScrnState extends State<HomeScrn> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  // Get the logged-in email
  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth * 0.4;

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
            if (userEmail != null)
              Text(
                'Admin Panel',
                style: Theme.of(context).textTheme.headlineLarge,
              ),

            const SizedBox(height: 8),
            // Card for "Users"
            Card(
              elevation: 5,
              child: ListTile(
                title: const Text('Users'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pushNamed(context, '/users');
                },
              ),
            ),

            const SizedBox(height: 15),

            // Card for "Aliases"
            Card(
              elevation: 5,
              child: ListTile(
                title: const Text('Aliases'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pushNamed(context, '/aliases');
                },
              ),
            ),

            const SizedBox(height: 15),

            // Card for "Domains"
            Card(
              elevation: 5,
              child: ListTile(
                title: const Text('Domains'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.pushNamed(context, '/domains');
                },
              ),
            ),

            const SizedBox(height: 15),

            // Row for "Account" and "Settings" cards, placed side-by-side
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card for "Account"
                Card(
                  elevation: 5,
                  child: SizedBox(
                    width: cardWidth,
                    child: ListTile(
                      title: const Text('Account'),
                      trailing: const Icon(Icons.account_circle),
                      onTap: () {
                        Navigator.pushNamed(context, '/account');
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 5),

                // Card for "Settings"
                Card(
                  elevation: 5,
                  child: SizedBox(
                    width: cardWidth,
                    child: ListTile(
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.settings),
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
