import 'package:flutter/material.dart';
import 'package:frontend/modules/auth/register/controller/register_controller.dart';
import 'package:frontend/modules/auth/widgets/auth_feedback_dialog.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
      await showAuthFeedbackDialog(
        context,
        isSuccess: false,
        title: 'Check your details',
        message: validationMessage,
      );
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
        await showAuthFeedbackDialog(
          context,
          isSuccess: true,
          title: 'Account created',
          message: 'Your account is ready. You can now log in.',
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      await showAuthFeedbackDialog(
        context,
        isSuccess: false,
        title: 'Registration failed',
        message:
            'Unable to create account. Email or username may already be in use.',
      );
    } on Exception catch (error) {
      if (!mounted) return;
      await showAuthFeedbackDialog(
        context,
        isSuccess: false,
        title: 'Connection error',
        message: error.toString().replaceFirst('Exception: ', ''),
      );
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
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
                        'Create account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join Borrow to borrow and lend items',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _usernameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          hintText: 'Enter your full name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
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
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'At least 8 characters',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        onSubmitted: (_) => _register(),
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          hintText: 'Re-enter your password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitting ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F4BFF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_submitting ? 'Registering...' : 'Register'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2F4BFF),
                        ),
                        child: const Text('Already have an account? Log in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
