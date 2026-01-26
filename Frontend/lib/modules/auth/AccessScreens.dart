import 'package:flutter/material.dart';
import 'SessionManager.dart';
import 'package:provider/provider.dart';

class AccessScreens extends StatefulWidget {
  const AccessScreens({super.key});

  @override
  State<AccessScreens> createState() => _AccessScreensState();
}

class _AccessScreensState extends State<AccessScreens> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  String? _error;

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLoginMode) {
        await context.read<SessionManager>().login(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await context.read<SessionManager>().signup(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
      }
    } catch (e) {
      setState(() {
        String message = e.toString().replaceFirst('Exception: ', '');
        if (message.contains('User already exists')) {
          _error = 'An account with this email already exists.';
        } else if (message.contains('Invalid credentials')) {
          _error = 'Incorrect email or password.';
        } else {
          _error = 'Server error. Please try again later.';
          debugPrint('Auth Error: $e');
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'VBP VERSION 2.0',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  _isLoginMode ? 'Please sign in to continue' : 'Create your account',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                if (!_isLoginMode) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(_isLoginMode ? 'Sign In' : 'Register Now', style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() {
                      _isLoginMode = !_isLoginMode;
                      _error = null;
                    }),
                    child: Text(_isLoginMode ? 'CREATE NEW ACCOUNT' : 'BACK TO LOGIN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
