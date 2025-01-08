import 'dart:convert';
import 'package:html/parser.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart'; // For multi-select dropdown

class AliasCrtScrn extends StatefulWidget {
  const AliasCrtScrn({super.key});

  @override
  State<AliasCrtScrn> createState() => _AliasCrtScrnState();
}

class _AliasCrtScrnState extends State<AliasCrtScrn> {
  String? userEmail;
  String? domain;
  bool isLoading = true;
  String? error;

  final _emailController = TextEditingController();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  List<String> domains = [];
  List<String> forwardsToOptions = [];
  List<String> permittedSendersOptions = [];

  List<String> selectedForwardsTo = [];
  List<String> selectedPermittedSenders = [];

  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchDomains();
    _fetchUsers();
  }

  // Fetch the domains from the API
  Future<void> _fetchDomains() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? email = prefs.getString('email');
    String? apiKey = await secureStorage.read(key: 'api_key');

    String apiUrl = 'https://$url/admin/mail/domains';

    try {
      String credentials = '$email:$apiKey';
      String base64Credentials = base64Encode(utf8.encode(credentials));

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic $base64Credentials',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          var document = parse(response.body);
          final domainsList = document.body?.text.split('\n') ?? [];
          setState(() {
            domains = domainsList
                .where((domain) => domain.trim().isNotEmpty)
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Failed to load domains: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error occurred: $e';
          isLoading = false;
        });
      }
    }
  }

  // Fetch users for forwardsTo and permittedSenders
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

        // Loop through response data and extract user emails
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
          forwardsToOptions =
              fetchedUsers.map((user) => user['email'] as String).toList();
          permittedSendersOptions =
              fetchedUsers.map((user) => user['email'] as String).toList();
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

  // API Call to Create the Alias
  Future<void> _createAlias() async {
    if (_emailController.text.isEmpty ||
        domain == null ||
        selectedForwardsTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    String email = '${_emailController.text}@${domain!}';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? emailFromPrefs = prefs.getString('email');
    String? apiKey = await FlutterSecureStorage().read(key: 'api_key');

    String apiUrl = 'https://$url/admin/mail/aliases/add';

    String credentials = '$emailFromPrefs:$apiKey';
    String base64Credentials = base64Encode(utf8.encode(credentials));

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic $base64Credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'update_if_exists': '0',
          'address': email,
          'forwards_to': selectedForwardsTo.join(','),
          'permitted_senders': selectedPermittedSenders.join(','),
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alias created successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
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
                'Create Alias',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      maxLength: 64,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        label: Text('Email Alias'),
                      ),
                    ),
                  ),
                  Text(
                    ' @ ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  isLoading
                      ? CircularProgressIndicator()
                      : Expanded(
                          child: DropdownButton<String>(
                            value: domain,
                            hint: Text('Select Domain'),
                            onChanged: (String? newValue) {
                              if (mounted) {
                                setState(() {
                                  domain = newValue;
                                });
                              }
                            },
                            items: domains
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 16),

              // Forwards To Multi-Select Dropdown
              MultiSelectDialogField(
                items: forwardsToOptions
                    .map((user) => MultiSelectItem<String>(user, user))
                    .toList(),
                title: Text("Select Forwarding Address"),
                selectedColor: Theme.of(context).primaryColor,
                buttonText: Text("Select Forwarding Address"),
                onConfirm: (values) {
                  setState(() {
                    selectedForwardsTo = values.cast<String>();
                  });
                },
              ),
              if (selectedForwardsTo.isNotEmpty)
                Text(
                    'Selected Forwarding Addresses: \n${selectedForwardsTo.join(', ')}'),

              const SizedBox(height: 16),

              // Permitted Senders Multi-Select Dropdown
              MultiSelectDialogField(
                items: permittedSendersOptions
                    .map((user) => MultiSelectItem<String>(user, user))
                    .toList(),
                title: Text("Select Permitted Senders"),
                selectedColor: Theme.of(context).primaryColor,
                buttonText: Text("Select Permitted Senders"),
                onConfirm: (values) {
                  setState(() {
                    selectedPermittedSenders = values.cast<String>();
                  });
                },
              ),
              if (selectedPermittedSenders.isNotEmpty)
                Text(
                    'Selected Permitted Senders: ${selectedPermittedSenders.join(', ')}'),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createAlias,
                child: Text('Create Alias'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
