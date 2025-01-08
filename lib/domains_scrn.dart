import 'dart:convert';
import 'package:html/parser.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DomainsScrn extends StatefulWidget {
  const DomainsScrn({super.key});

  @override
  State<DomainsScrn> createState() => _DomainsScrnState();
}

class _DomainsScrnState extends State<DomainsScrn> {
  String? userEmail;
  List<String> domains = [];
  bool isLoading = true;
  String? error;

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _fetchDomains();
  }

  // Get the logged-in email from SharedPreferences
  Future<void> _getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email');
    });
  }

  // Fetch the domains from the API
  Future<void> _fetchDomains() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('url');
    String? email = prefs.getString('email');
    String? apiKey = await secureStorage.read(key: 'api_key');

    String apiUrl = 'https://$url/admin/mail/domains';

    try {
      // Combine email and API key and encode them properly
      String credentials = '$email:$apiKey';
      String base64Credentials = base64Encode(utf8.encode(credentials));

      // Set the Authorization header with the base64 encoded credentials
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic $base64Credentials',
        },
      );

      if (response.statusCode == 200) {
        var document = parse(response.body);

        // Extract all the domain names from the HTML
        final domainsList = document.body?.text.split('\n') ?? [];

        setState(() {
          domains =
              domainsList.where((domain) => domain.trim().isNotEmpty).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error =
              'Failed to load domains: ${response.statusCode} - ${response.body}';
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Domains',
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
                          itemCount: domains.length,
                          itemBuilder: (context, index) {
                            final domain = domains[index];
                            return Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(domain),
                                trailing: Icon(Icons.domain),
                                //onTap: () {},
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 65),
            ],
          ),
        ),
      ),
      //floatingActionButton: FloatingActionButton(
      //  onPressed: () {},
      //  child: const Icon(Icons.add),
      //),
    );
  }
}
