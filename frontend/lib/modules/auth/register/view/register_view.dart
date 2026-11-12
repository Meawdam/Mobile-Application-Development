import 'package:flutter/material.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _registerController = RegisterController();

  void _register() {
    final result = _registerController.register(
      username: _usernameController.text,
      phoneNumber: _phoneNumberController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (result == RegisterResult.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can now log in.')),
      );
      return;
    }

    final message = switch (result) {
      RegisterResult.success => '',
      RegisterResult.missingFields => 'Please complete all fields',
      RegisterResult.passwordTooShort =>
        'Password must be at least 8 characters',
      RegisterResult.passwordMismatch => 'Passwords do not match',
      RegisterResult.emailAlreadyExists => 'This email is already registered',
    };

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
          ElevatedButton(onPressed: _register, child: const Text('Register')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
