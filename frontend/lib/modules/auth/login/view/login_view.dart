import 'package:flutter/material.dart';
import 'package:frontend/modules/auth/login/controller/login_controller.dart';

class LoginScreen extends StatefulWidget {
  final LoginController? controller;

  const LoginScreen({super.key, this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final _loginController = widget.controller ?? LoginController();
  bool _submitting = false;

  Future<void> _login() async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final role = await _loginController.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (role == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
        return;
      }

      final route = switch (role) {
        'admin' => '/admin',
        'user' => '/home',
        _ => null,
      };

      if (route == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account has an unsupported role')),
        );
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.swap_horizontal_circle,
                size: 72,
                color: Color(0xFF2F4BFF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Borrow',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to borrow and lend items',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@university.ac.th',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onSubmitted: (_) => _login(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _login,
                child: Text(_submitting ? 'Signing in...' : 'Log in'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.pushNamed(context, '/register'),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
