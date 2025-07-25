import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:wetherapp/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // If the form is valid, navigate to the HomePage.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(body: buildUI(colorScheme, textTheme));
  }

  Widget buildUI(ColorScheme colorScheme, TextTheme textTheme) {
    return Stack(
      children: [
        // Background with decorative blobs
        Positioned(
          top: -100,
          left: -100,
          child:
              Container(width: 200, height: 200, decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.4), shape: BoxShape.circle)),
        ),
        Positioned(
          bottom: -150,
          right: -150,
          child:
              Container(width: 300, height: 300, decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.3), shape: BoxShape.circle)),
        ),
        // Glassmorphism container
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      child: buildLoginForm(textTheme, colorScheme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLoginForm(TextTheme textTheme, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildLogo(colorScheme),
          const SizedBox(height: 24.0),
          Text(
            'Welcome Back!',
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text('Sign in to continue', style: textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 48.0),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              labelText: 'Email',
              filled: true,
              fillColor: colorScheme.surface.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              labelText: 'Password',
              filled: true,
              fillColor: colorScheme.surface.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters long';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password functionality
              },
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    // This widget creates a logo for a mobile shop concept.
    // You can replace this with your own Image.asset('assets/logo.png') later on.
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Center(
        child: Icon(
          Icons.smartphone,
          size: 45,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}