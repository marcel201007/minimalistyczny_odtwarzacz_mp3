// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: const Text('Unexpected error occurred'),
      ));
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isSignedIn = user != null;
    final email = user?.email ?? 'You must log in';

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Manage your account',
                      style: TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'ACCOUNT',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      isSignedIn ? Icons.person_rounded : Icons.person_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignedIn ? 'Signed in' : 'Guest session',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        
                      ],
                    ),
                  ),
                  Icon(
                    isSignedIn ? Icons.verified_rounded : Icons.info_outline,
                    size: 20,
                    color: isSignedIn
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'SESSION',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            ShadButton(
              leading: Icon(isSignedIn ? Icons.logout : Icons.login),
              child: Text(isSignedIn ? 'Log out' : 'Log in'),
              onPressed: () {
                if (isSignedIn) {
                  _signOut();
                } else {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            )
          ],
        ),
      ],
    );
  }
}
