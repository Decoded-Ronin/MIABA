import 'dart:convert';
import 'package:html/parser.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserCrtScrn extends StatefulWidget {
  const UserCrtScrn({super.key});

  @override
  State<UserCrtScrn> createState() => _UserCrtScrnState();
}

class _UserCrtScrnState extends State<UserCrtScrn> {
  String? userEmail;
  String? domain;
  bool isLoading = true;
  bool isPasswordVisible = false;
  bool isPasswordVisible2 = false;
  String? error;
  bool isAdmin = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  List<String> domains = [];

  @override
  void initState() {
    super.initState();
    _fetchDomains();
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

      if (response.statusCode == 200) {
        var document = parse(response.body);
        final domainsList = document.body?.text.split('\n') ?? [];

        if (mounted) {
          setState(() {
            domains = domainsList
                .where((domain) => domain.trim().isNotEmpty)
                .toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
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

  // Confirmation Dialog when "Set as Admin" is clicked
  Future<void> _showAdminConfirmationDialog() async {
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Admin'),
        content: Text('Set this user as an Admin?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
    if (isConfirmed == true) {
      if (mounted) {
        setState(() {
          isAdmin = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isAdmin = false;
        });
      }
    }
  }

  // API Call to Create the User
  Future<void> _createUser() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email field required!')),
      );
      return; // Stop execution if fields are empty
    } else if (domain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Domain field required!')),
      );
      return;
    } else if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password field required!')),
      );
      return;
    } else if (_confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirm Password field required!')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    String email = '${_emailController.text}@${domain!}';
    String password = _passwordController.text;
    String privilege = isAdmin ? 'admin' : '';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? emailFromPrefs = prefs.getString('email');
    String? apiKey = await FlutterSecureStorage().read(key: 'api_key');

    String apiUrl = 'https://$url/admin/mail/users/add';

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
          'email': email,
          'password': password,
          'privileges': privilege,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User created successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.body)),
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

  // Build the widget displayed on Modal
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
        // Wrap the entire body in a SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Create User',
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
                        label: Text('Email'),
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
                            value: domain, // The currently selected value
                            hint: Text('Select Domain'),
                            onChanged: (String? newValue) {
                              if (mounted) {
                                setState(() {
                                  domain =
                                      newValue; // Update the selected domain
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
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: error != null && error!.contains('password')
                      ? error
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                obscureText: !isPasswordVisible,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  errorText: error != null && error!.contains('password')
                      ? error
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible2
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility2,
                  ),
                ),
                obscureText: !isPasswordVisible2,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isAdmin,
                    onChanged: (bool? value) async {
                      if (value ?? false) {
                        await _showAdminConfirmationDialog();
                      } else {
                        if (mounted) {
                          setState(() {
                            isAdmin = false;
                          });
                        }
                      }
                    },
                  ),
                  const Text('Set as Admin'),
                  const Expanded(child: SizedBox()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _createUser();
                        },
                        child: const Text('Create User'),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    if (mounted) {
      setState(() {
        isPasswordVisible = !isPasswordVisible;
      });
    }
  }

  // Toggle confirm password visibility
  void _togglePasswordVisibility2() {
    if (mounted) {
      setState(() {
        isPasswordVisible2 = !isPasswordVisible2;
      });
    }
  }
}
