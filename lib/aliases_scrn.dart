import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:miaba/alias_edt_scrn.dart';
import 'package:miaba/alias_crt_scrn.dart';

class AliasesScrn extends StatefulWidget {
  const AliasesScrn({super.key});

  @override
  State<AliasesScrn> createState() => _AliasesScrnState();
}

class _AliasesScrnState extends State<AliasesScrn> {
  String? userEmail;
  List<Map<String, dynamic>> aliases = [];
  bool isLoading = true;
  String? error;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _fetchAliases();
  }

  // Add a new alias
  void _createNewAlias() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AliasCrtScrn()),
    );

    // If a new alias was created successfully, refresh the alias list
    if (result == true) {
      _fetchAliases();
    }
  }

  // Add a new user
  void _editAlias(aliasEmail, forwardsTo, permittedSenders) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AliasEdtScrn(
          aliasEmail: aliasEmail,
          forwardsTo: List<String>.from(forwardsTo),
          permittedSenders: List<String>.from(permittedSenders),
        ),
      ),
    );

    // If user was edited successfully, refresh the user list
    if (result == true) {
      _fetchAliases();
    }
  }

  // Get the logged-in email from SharedPreferences
  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
    });
  }

  // Fetch the aliases using the API
  Future<void> _fetchAliases() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? email = prefs.getString('email');
    String? apiKey = await secureStorage.read(key: 'api_key');

    if (url != null && email != null && apiKey != null) {
      String apiUrl = 'https://$url/admin/mail/aliases?format=json';

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
          List<Map<String, dynamic>> fetchedAliases = [];

          for (var domain in data) {
            for (var alias in domain['aliases']) {
              fetchedAliases.add({
                'address': alias['address'],
                'address_display': alias['address_display'],
                'forwards_to': alias['forwards_to'] ?? [],
                'permitted_senders': alias['permitted_senders'] ?? [],
                'required': alias['required'] ?? false,
              });
            }
          }

          setState(() {
            aliases = fetchedAliases;
            isLoading = false;
          });
        } else {
          setState(() {
            error =
                'Failed to load aliases: ${response.statusCode} - ${response.body}';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          error = 'Error occurred: $e';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        error = 'URL, email, or API Key not found';
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Aliases',
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
                          itemCount: aliases.length,
                          itemBuilder: (context, index) {
                            final alias = aliases[index];
                            return Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  alias['address'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Forwards to: ${(alias['forwards_to'] as List).join(', ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Permitted Senders: ${(alias['permitted_senders'] as List).join(', ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Required: ${alias['required'] ? 'Yes' : 'No'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.edit_note),
                                onTap: () {
                                  _editAlias(
                                      alias['address'],
                                      alias['forwards_to'],
                                      alias['permitted_senders']);
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
        onPressed: _createNewAlias,
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}
