import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountScrn extends StatefulWidget {
  const AccountScrn({super.key});

  @override
  State<AccountScrn> createState() => _AccountScrnState();
}

class _AccountScrnState extends State<AccountScrn> {
  String? userEmail;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
  }

  // Get the logged-in email from SharedPreferences
  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (mounted) {
      if (email == null || email.isEmpty) {
        setState(() {
          error = 'No email found. Please log in first.';
          isLoading = false;
        });
      } else {
        setState(() {
          userEmail = email;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    // Retrieve the stored API key
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? apiKey = await secureStorage.read(key: 'api_key');
    String? email = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('email'));
    String? url = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('url'));

    if (apiKey == null || email == null) {
      _clearUserData();
      return;
    }

    try {
      String auth = 'Basic ${base64Encode(utf8.encode('$email:$apiKey'))}';

      final response = await http.post(
        Uri.parse('https://$url/admin/logout'),
        headers: {
          'Authorization': auth,
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _clearUserData();
        }
      } else {
        if (mounted) {
          setState(() {
            error = 'Failed to logout: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error occurred during logout: $e';
        });
      }
    }
  }

  // Clear Secure Storage and SharedPreferences
  void _clearUserData() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: 'api_key');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  // Show a confirmation dialog before logging out
  Future<void> _showLogoutConfirmation() async {
    bool? logoutConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (logoutConfirmed == true) {
      _logout();
    }
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
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Center(
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              )
            else
              Column(
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Logged in as:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '$userEmail',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),

                  // Logout Card
                  Card(
                    elevation: 5,
                    child: SizedBox(
                      width: double.infinity,
                      child: ListTile(
                        title: const Text('Logout'),
                        trailing: const Icon(Icons.exit_to_app),
                        onTap: _showLogoutConfirmation,
                      ),
                    ),
                  ),

                  // Red Message at the Bottom
                  const SizedBox(height: 20),
                  Text(
                    "Note: If you log out, the API key generated at sign-in will become invalid and all 'Sign In' info will be deleted from this device",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
