// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo:
            kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
      );
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
              duration: Duration(seconds: 2),
              title: Text(
                'Check your email for a login link!',
                style: TextStyle(color: Colors.white),
              )),
        );

        _emailController.clear();
      }
    } on AuthException catch (error) {
      ShadToaster.of(context).show(
        ShadToast(
            duration: const Duration(seconds: 2), title: Text(error.message)),
      );
    } catch (error) {
      ShadToaster.of(context).show(
        const ShadToast(
            duration: Duration(seconds: 2),
            title: Text('Unexpected error occurred')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;
      final session = data.session;
      if (session != null) {
        _redirecting = true;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sign In',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 10,
                ),
                const Text('Sign in via the magic link with your email below'),
                const SizedBox(height: 18),
                ShadInput(
                  controller: _emailController,
                  placeholder: const Text("Email"),
                ),
                const SizedBox(height: 18),
                ShadButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: Text(_isLoading ? 'Loading' : 'Send Magic Link'),
                ),
              ],
            )));
  }
}
