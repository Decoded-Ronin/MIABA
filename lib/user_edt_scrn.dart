import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserEdtScrn extends StatefulWidget {
  final String userEmail;
  final bool isAdmin;

  const UserEdtScrn(
      {super.key, required this.userEmail, required this.isAdmin});

  @override
  State<UserEdtScrn> createState() => _UserEdtScrnState();
}

class _UserEdtScrnState extends State<UserEdtScrn> {
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isPasswordVisible2 = false;
  bool? isAdmin;
  bool? startPrivilege;

  String? error;
  String? domain;
  String? loggedInEmail;

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.userEmail;
    isAdmin = widget.isAdmin;
    startPrivilege = widget.isAdmin;

    _getLoggedInEmail();
  }

  // Retrieve the logged-in admin's email from SharedPreferences
  Future<void> _getLoggedInEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInEmail = prefs.getString('email');
    setState(() {});
  }

  Future<void> _updateUser() async {
    if (_newPasswordController.text.isEmpty &&
        _confirmNewPasswordController.text.isEmpty &&
        isAdmin == startPrivilege) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes were entered!')),
      );
      return;
    }

    // Ensure the passwords match
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    String email = _emailController.text;
    String password = _newPasswordController.text;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? emailFromPrefs = prefs.getString('email');
    String? apiKey = await FlutterSecureStorage().read(key: 'api_key');

    String credentials = '$emailFromPrefs:$apiKey';
    String base64Credentials = base64Encode(utf8.encode(credentials));

    try {
      setState(() {
        isLoading = true;
      });

      // Set the password if it's provided
      if (password.isNotEmpty) {
        final passwordApiUrl = 'https://$url/admin/mail/users/password';
        final passwordResponse = await http.post(
          Uri.parse(passwordApiUrl),
          headers: {
            'Authorization': 'Basic $base64Credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'email': email,
            'password': password,
          },
        );

        if (passwordResponse.statusCode != 200) {
          throw Exception(
              'Failed to update password: ${passwordResponse.statusCode}');
        }
      }

      // Handle Admin Privilege change (Add or Remove)
      if (isAdmin != startPrivilege) {
        String privilege = "admin";

        final privilegeApiUrl = isAdmin!
            ? 'https://$url/admin/mail/users/privileges/add'
            : 'https://$url/admin/mail/users/privileges/remove';

        final privilegeResponse = await http.post(
          Uri.parse(privilegeApiUrl),
          headers: {
            'Authorization': 'Basic $base64Credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'email': email,
            'privilege': privilege,
          },
        );

        if (privilegeResponse.statusCode != 200) {
          throw Exception(
              'Failed to update privilege: ${privilegeResponse.statusCode}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Delete user API call
  Future<void> _deleteUser() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? emailFromPrefs = prefs.getString('email');
    String? apiKey = await FlutterSecureStorage().read(key: 'api_key');

    String apiUrl = 'https://$url/admin/mail/users/remove';
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
          'email': widget.userEmail,
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          // Successfully deleted user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
          Navigator.pop(context, true);
        } else {
          // Error in deletion
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete user: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditable =
        loggedInEmail != null && loggedInEmail != widget.userEmail;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Image.asset(
          'assets/logos/miaba_logo.png',
          height: 90,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          if (loggedInEmail != widget.userEmail && isAdmin == false)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Delete confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                          'Are you sure you want to delete this user?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteUser();
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Edit User',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${widget.userEmail}',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                enabled: isEditable,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmNewPasswordController,
                obscureText: !isPasswordVisible2,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible2
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility2,
                  ),
                ),
                enabled: isEditable,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Is Admin'),
                value: isAdmin,
                onChanged: isEditable
                    ? (bool? value) {
                        setState(() {
                          isAdmin = value ?? false;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (isLoading || loggedInEmail == widget.userEmail)
                    ? null
                    : () {
                        bool isPasswordChanged =
                            _newPasswordController.text.isNotEmpty &&
                                _newPasswordController.text ==
                                    _confirmNewPasswordController.text;
                        bool isAdminChanged = isAdmin != startPrivilege;

                        if (!isPasswordChanged && !isAdminChanged) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('No changes were made!')),
                          );
                          return;
                        }

                        String title;
                        String content;

                        if (isPasswordChanged && isAdminChanged) {
                          title = 'Confirm Password & Admin Change';
                          content =
                              'Are you sure you want to change both the password and admin privileges?';
                        } else if (isPasswordChanged) {
                          title = 'Confirm Password Change';
                          content =
                              'Are you sure you want to change the password?';
                        } else if (isAdminChanged) {
                          title = 'Confirm Admin Change';
                          content =
                              'Are you sure you want to change the admin privileges?';
                        } else {
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(title),
                              content: Text(content),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _updateUser();
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  // Toggle confirm password visibility
  void _togglePasswordVisibility2() {
    setState(() {
      isPasswordVisible2 = !isPasswordVisible2;
    });
  }
}
