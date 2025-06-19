// File: lib/features/profile/screens/sign_out_button_tile.dart
import 'package:flutter/material.dart';
import 'package:mm_associates/features/auth/services/auth_service.dart'; // Absolute import for AuthService

class SignOutButtonTile extends StatelessWidget {
  const SignOutButtonTile({super.key});

  Future<void> _signOut(BuildContext context) async {
    final AuthService authService = AuthService(); // Instantiated here
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            } ,
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await authService.signOut();
        if (context.mounted) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error signing out: ${e.toString()}"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.logout_outlined, color: theme.colorScheme.error), 
      title: Text(
        "Sign Out",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.error, 
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () => _signOut(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      dense: true,
    );
  }
}