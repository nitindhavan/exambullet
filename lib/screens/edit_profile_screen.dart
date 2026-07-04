import 'package:flutter/material.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent/models/User.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseDatabase.instance.ref('users/$uid').update({
        'name': _nameController.text.trim(),
      });
      if (mounted) {
        widget.user.name = _nameController.text.trim();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppTopBar(title: 'Edit Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Full Name',
              style: AppTheme.headingSm.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space6, vertical: AppTheme.space5),
                border: OutlineInputBorder(
                  borderRadius: AppTheme.brMd,
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.brMd,
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.brMd,
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Email',
              style: AppTheme.headingSm.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(
                  text: FirebaseAuth.instance.currentUser?.email ?? widget.user.phone),
              enabled: false,
              style: const TextStyle(color: AppTheme.textSecondary),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space6, vertical: AppTheme.space5),
                border: OutlineInputBorder(
                  borderRadius: AppTheme.brMd,
                  borderSide: BorderSide.none,
                ),
                suffixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 48),
            AppButton(
              label: 'Save Changes',
              loading: _saving,
              onPressed: _save,
              height: 56,
            ),
          ],
        ),
      ),
    );
  }
}
