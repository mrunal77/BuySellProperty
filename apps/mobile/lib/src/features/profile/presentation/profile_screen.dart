import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth_store.dart';
import '../../../core/theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await ref.read(authStoreProvider.notifier).logout();
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStoreProvider);
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text((auth.email ?? 'G').substring(0, 1).toUpperCase())),
              title: Text(auth.email ?? 'Guest'),
              subtitle: Text('Type: ${auth.userType ?? '-'}${auth.roles.isNotEmpty ? ' • ${auth.roles.join(', ')}' : ''}'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest), label: Text('Auto')),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                  ),
                ],
              ),
            ),
          ),
          if (auth.isLister) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.push('/owner'),
              child: const Text('Owner dashboard'),
            ),
          ],
          const SizedBox(height: 12),
          if (auth.isLoggedIn)
            FilledButton(
              onPressed: _loggingOut ? null : _logout,
              child: _loggingOut
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Logout'),
            )
          else
            FilledButton(onPressed: () => context.push('/login'), child: const Text('Log in')),
        ],
      ),
    );
  }
}
