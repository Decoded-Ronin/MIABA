import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignInScrn extends StatefulWidget {
  const SignInScrn({super.key});

  @override
  State<SignInScrn> createState() => _SignInState();
}

class _SignInState extends State<SignInScrn> {
  bool isLoading = false;
  String? error;
  bool isPasswordVisible = false;
  String? otp;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _otpController = TextEditingController();

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  // Check if user is already signed in using SharedPreferences or Secure Storage
  Future<void> _checkSignInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? url = prefs.getString('url');

    // Check if the API key is available securely
    String? apiKey = await secureStorage.read(key: 'api_key');

    // Ensure email, apiKey, and url are non-null before auto-signing in
    if (email != null && apiKey != null && url != null) {
      _autoSignIn(email, apiKey, url);
    } else {
      setState(() {
        error = 'No stored credentials found. Please log in again.';
      });
    }
  }

  // Auto sign in with the saved credentials
  Future<void> _autoSignIn(String email, String apiKey, String url) async {
    setState(() {
      isLoading = true;
    });

    // Assuming API key is valid and auto-signing in
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
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
          children: <Widget>[
            const SizedBox(height: 16),
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'admin@domain.com',
                errorText:
                    error != null && error!.contains('email') ? error : null,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password TextField with Eye Icon for visibility toggle
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText:
                    error != null && error!.contains('password') ? error : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              obscureText: !isPasswordVisible,
            ),
            const SizedBox(height: 16),

            // URL TextField
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'box.example.com',
                errorText:
                    error != null && error!.contains('url') ? error : null,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // OTP TextField (shown only if OTP is required)
            if (otp != null && otp == 'OTP required') ...[
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'OTP',
                  hintText: 'Enter OTP',
                  errorText:
                      error != null && error!.contains('OTP') ? error : null,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // Sign In Button
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleSubmit,
                    child: const Text('Sign In'),
                  ),
            const SizedBox(height: 16),

            // Informational message about password and API key
            Text(
              "Your password is only used to fetch the API key. The API key is then securely stored on your device encrypted and used for making the API calls. If an OTP is required, it will be prompted above after the first 'Sign In' attempt.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red, // Red text color
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    String email = _emailController.text;
    String password = _passwordController.text;
    String url = _urlController.text;
    String? otpInput = otp != null ? _otpController.text : null;

    if (email.isEmpty || password.isEmpty || url.isEmpty) {
      setState(() {
        error = 'Email, password, and URL are required!';
        isLoading = false;
      });
      return;
    }

    String auth = 'Basic ${base64Encode(utf8.encode('$email:$password'))}';

    try {
      final response = await http.post(
        Uri.parse('https://$url/admin/login'),
        headers: {
          'Authorization': auth,
          'Content-Type': 'application/json',
          if (otpInput != null && otpInput.isNotEmpty) 'x-auth-token': otpInput,
        },
        body: json.encode({
          'email': email,
          'password': password,
          'otp': otpInput ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['reason'] == 'missing-totp-token') {
          setState(() {
            otp = 'OTP required';
            isLoading = false;
          });
        } else {
          String apiKey = data['api_key'] ?? '';
          String userEmail = data['email'] ?? '';

          if (apiKey.isNotEmpty) {
            await secureStorage.write(key: 'api_key', value: apiKey);

            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.setString('email', userEmail);
            prefs.setString('url', url);

            setState(() {
              isLoading = false;
            });
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            setState(() {
              error = 'Invalid credentials or API Key not received';
              isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          error = 'Failed to authenticate: ${response.statusCode}';
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

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }
}
