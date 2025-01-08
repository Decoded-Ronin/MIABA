import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AliasEdtScrn extends StatefulWidget {
  final String aliasEmail;
  final List<String> forwardsTo;
  final List<String> permittedSenders;

  const AliasEdtScrn({
    super.key,
    required this.aliasEmail,
    required this.forwardsTo,
    required this.permittedSenders,
  });

  @override
  State<AliasEdtScrn> createState() => _AliasEdtScrnState();
}

class _AliasEdtScrnState extends State<AliasEdtScrn> {
  bool isLoading = false;
  bool isSaving = false;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  List<String> selectedForwardsTo = [];
  List<String> selectedPermittedSenders = [];
  List<String> availableForwardsTo = [];
  List<String> availablePermittedSenders = [];

  @override
  void initState() {
    super.initState();
    selectedForwardsTo = List.from(widget.forwardsTo);
    selectedPermittedSenders = List.from(widget.permittedSenders);
    _fetchAvailableAddresses();
  }

  Future<void> _fetchAvailableAddresses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? emailFromPrefs = prefs.getString('email');
    String? apiKey = await FlutterSecureStorage().read(key: 'api_key');

    String credentials = '$emailFromPrefs:$apiKey';
    String base64Credentials = base64Encode(utf8.encode(credentials));

    try {
      final apiUrl = 'https://$url/admin/mail/users';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic $base64Credentials',
        },
      );

      if (response.statusCode == 200) {
        final List<String> fetchedAddresses =
            response.body.split('\n').map((e) => e.trim()).toList();

        setState(() {
          availableForwardsTo = fetchedAddresses
              .where((address) => !widget.forwardsTo.contains(address))
              .toList();

          availablePermittedSenders = fetchedAddresses
              .where((sender) => !widget.permittedSenders.contains(sender))
              .toList();
        });
      } else {
        throw Exception('Failed to fetch available addresses');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching available addresses: $e')),
        );
      }
    }
  }

  // Update alias (forwards and permitted senders)
  Future<void> _updateAlias() async {
    setState(() {
      isSaving = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? emailFromPrefs = prefs.getString('email');
    String? apiKey = await FlutterSecureStorage().read(key: 'api_key');

    String credentials = '$emailFromPrefs:$apiKey';
    String base64Credentials = base64Encode(utf8.encode(credentials));

    try {
      final updateApiUrl = 'https://$url/admin/mail/aliases/add';
      final response = await http.post(
        Uri.parse(updateApiUrl),
        headers: {
          'Authorization': 'Basic $base64Credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'update_if_exists': '1',
          'address': widget.aliasEmail,
          'forwards_to': selectedForwardsTo.join(','),
          'permitted_senders': selectedPermittedSenders.join(','),
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alias updated successfully')),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to update alias');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // Delete alias
  Future<void> _deleteAlias() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? emailFromPrefs = prefs.getString('email');
    String? apiKey = await FlutterSecureStorage().read(key: 'api_key');

    String apiUrl = 'https://$url/admin/mail/aliases/remove';
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
          'address': widget.aliasEmail,
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alias deleted successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete alias: ${response.statusCode}'),
            ),
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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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
        actions: [
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
                        'Are you sure you want to delete this alias?'),
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
                          _deleteAlias();
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
                'Edit Alias',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.aliasEmail,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Forwards To Multi-Select Dropdown
              availableForwardsTo.isEmpty
                  ? const CircularProgressIndicator()
                  : MultiSelectDialogField(
                      items: [
                        ...widget.forwardsTo
                            .map((user) => MultiSelectItem<String>(user, user)),
                        ...availableForwardsTo
                            .map((user) => MultiSelectItem<String>(user, user)),
                      ],
                      initialValue: selectedForwardsTo,
                      title: Text("Select Forwarding Address"),
                      selectedColor: Theme.of(context).primaryColor,
                      buttonText: Text("Select Forwarding Address"),
                      onConfirm: (values) {
                        if (mounted) {
                          setState(() {
                            selectedForwardsTo = values.cast<String>();
                          });
                        }
                      },
                    ),

              const SizedBox(height: 16),

              // Permitted Senders Multi-Select Dropdown
              availablePermittedSenders.isEmpty
                  ? const CircularProgressIndicator()
                  : MultiSelectDialogField(
                      items: [
                        ...widget.permittedSenders
                            .map((user) => MultiSelectItem<String>(user, user)),
                        ...availablePermittedSenders
                            .map((user) => MultiSelectItem<String>(user, user)),
                      ],
                      initialValue: selectedPermittedSenders,
                      title: Text("Select Permitted Senders"),
                      selectedColor: Theme.of(context).primaryColor,
                      buttonText: Text("Select Permitted Senders"),
                      onConfirm: (values) {
                        if (mounted) {
                          setState(() {
                            selectedPermittedSenders = values.cast<String>();
                          });
                        }
                      },
                    ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSaving ? null : _updateAlias,
                child: Text(isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
