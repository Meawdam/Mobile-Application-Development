import 'package:flutter/material.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';

class RegisterScreen extends StatefulWidget {
  final RegisterController? controller;

  const RegisterScreen({super.key, this.controller});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final _registerController = widget.controller ?? RegisterController();
  bool _submitting = false;

  Future<void> _register() async {
    if (_submitting) return;

    final username = _usernameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    String? validationMessage;
    if (username.isEmpty ||
        phoneNumber.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      validationMessage = 'Please complete all fields';
    } else if (phoneNumber.length > 10) {
      validationMessage = 'Phone number must be 10 characters or fewer';
    } else if (password.length < 8) {
      validationMessage = 'Password must be at least 8 characters';
    } else if (password != confirmPassword) {
      validationMessage = 'Passwords do not match';
    }

    if (validationMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    setState(() => _submitting = true);
    try {
      final success = await _registerController.register(
        username,
        phoneNumber,
        email,
        password,
      );

      if (!mounted) return;

      if (success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Account created. You can now log in.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create account. Email or username may already be in use.',
          ),
        ),
      );
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
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Create your account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: 'Enter your phone number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'At least 8 characters',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              hintText: 'Re-enter password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _submitting ? null : _register,
            child: Text(_submitting ? 'Registering...' : 'Register'),
          ),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
