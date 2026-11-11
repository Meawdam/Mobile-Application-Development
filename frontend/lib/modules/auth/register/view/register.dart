import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
          const TextField(
            decoration: InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(onPressed: null, child: const Text('Register')),
          TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false),
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
