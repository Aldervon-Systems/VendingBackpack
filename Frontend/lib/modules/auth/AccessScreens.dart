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
  bool _isLoading = false;
  String? _error;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<SessionManager>().login(
        _emailController.text,
        _passwordController.text,
      );
      // Main navigation happens in main.dart listener
    } catch (e) {
      setState(() {
        _error = 'Login failed. Check credentials.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
           padding: const EdgeInsets.all(24),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(
                 'VendingBackpack',
                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 32),
               ),
               const SizedBox(height: 32),
               TextField(
                 controller: _emailController,
                 decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 16),
               TextField(
                 controller: _passwordController,
                 decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                 obscureText: true,
               ),
               const SizedBox(height: 24),
               if (_error != null) ...[
                 Text(_error!, style: const TextStyle(color: Colors.red)),
                 const SizedBox(height: 16),
               ],
               SizedBox(
                 width: double.infinity,
                 height: 48,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _handleLogin,
                   child: _isLoading ? const CircularProgressIndicator() : const Text('Sign In'),
                 ),
               ),
             ],
           ),
        ),
      ),
    );
  }
}
