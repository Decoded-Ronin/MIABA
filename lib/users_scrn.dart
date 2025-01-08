import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UsersScrn extends StatefulWidget {
  const UsersScrn({super.key});

  @override
  State<UsersScrn> createState() => _UsersScrnState();
}

class _UsersScrnState extends State<UsersScrn> {
  String? userEmail;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? error;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _fetchUsers();
  }

  // Add a new user
  void _createNewUser() async {
    final result = await Navigator.pushNamed(context, '/create_user');

    if (result == true) {
      _fetchUsers();
    }
  }

  // Add a new user
  void _editUser(email, isAdmin) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit_user',
      arguments: {
        'email': email ?? 'default@example.com',
        'isAdmin': isAdmin,
      },
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  // Get the logged-in email from SharedPreferences
  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
    });
  }

  // Fetch the users using the API
  Future<void> _fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? email = prefs.getString('email');
    String? apiKey = await secureStorage.read(key: 'api_key');

    String apiUrl = 'https://$url/admin/mail/users?format=json';

    try {
      String credentials = '$email:$apiKey';
      String base64Credentials = base64Encode(utf8.encode(credentials));

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic $base64Credentials',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedUsers = [];

        for (var domain in data) {
          for (var user in domain['users']) {
            fetchedUsers.add({
              'email': user['email'],
              'privileges': user['privileges'],
              'status': user['status'],
              'mailbox': user['mailbox'],
            });
          }
        }

        setState(() {
          users = fetchedUsers;
          isLoading = false;
        });
      } else {
        setState(() {
          error =
              'Failed to load users: ${response.statusCode} - ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error occurred: $e';
        isLoading = false;
      });
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Users',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              isLoading
                  ? const CircularProgressIndicator()
                  : error != null
                      ? Text(
                          error!,
                          style: TextStyle(color: Colors.red),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            bool isAdmin = user['privileges'].contains('admin');

                            return Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  user['email'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status: ${user['status']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Admin: ${isAdmin ? "Yes" : "No"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.edit_note),
                                onTap: () {
                                  _editUser(user['email'], isAdmin);
                                },
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 65),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewUser,
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}
