import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'home_screen.dart';

/// Forced onboarding screen shown to any user whose profile is incomplete.
/// Also used to edit an existing profile when [isEditing] is true.
class ProfileSetupScreen extends StatefulWidget {
  /// When [isEditing] is true the screen pre-populates fields from the
  /// current profile and allows the user to navigate back.
  final bool isEditing;

  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // ─── Colors ───────────────────────────────────────────────────────────────
  static const _bg             = Color(0xFF0C0E11);
  static const _surface        = Color(0xFF111417);
  static const _surfaceHigh    = Color(0xFF1C2025);
  static const _primary        = Color(0xFFADCBDB);
  static const _primaryCont    = Color(0xFF395664);
  static const _onPrimaryCont  = Color(0xFFC9E8F8);
  static const _onSurface      = Color(0xFFE2E5EE);
  static const _onSurfaceVar   = Color(0xFFA7ABB3);
  static const _outline        = Color(0xFF44484F);
  static const _error          = Color(0xFFFF6B6B);

  final _formKey         = GlobalKey<FormState>();
  final _usernameCtrl    = TextEditingController();
  final _nameCtrl        = TextEditingController();
  final _schoolCtrl      = TextEditingController();
  final _phoneCtrl       = TextEditingController();

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _prefillFromProfile();
  }

  /// Pre-populate controllers with the user's existing profile data.
  Future<void> _prefillFromProfile() async {
    final profile = await ProfileService.getMyProfile();
    if (!mounted || profile == null) return;
    setState(() {
      _usernameCtrl.text = profile.username;
      _nameCtrl.text     = profile.studentName ?? '';
      _schoolCtrl.text   = profile.schoolName ?? '';
      _phoneCtrl.text    = profile.phoneNumber ?? '';
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _errorMessage = null; });

    try {
      await ProfileService.saveProfile(
        username:    _usernameCtrl.text,
        studentName: _nameCtrl.text,
        schoolName:  _schoolCtrl.text,
        phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
      );
      if (!mounted) return;
      if (widget.isEditing) {
        // Return to caller (home screen) after a successful edit.
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('unique')
            ? 'That username is already taken. Please choose another.'
            : 'Something went wrong. Please try again.';
        _saving = false;
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block back-nav only during initial onboarding (not in edit mode).
      canPop: widget.isEditing,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildCard([
                    _buildField(
                      controller: _usernameCtrl,
                      label: 'Username',
                      hint: 'e.g. mahin_27',
                      icon: Icons.alternate_email_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Username is required';
                        if (v.trim().length < 3) return 'Must be at least 3 characters';
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                          return 'Only letters, numbers and underscores';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Your Full Name',
                      hint: 'e.g. Mahin Ahmed',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _schoolCtrl,
                      label: 'School / Institution',
                      hint: 'e.g. Rajshahi Collegiate School',
                      icon: Icons.school_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'School name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Phone Number (optional)',
                      hint: 'e.g. 01XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ]),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: _error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                
                                fontSize: 13,
                                color: _error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Sign out and use a different account',
                        style: TextStyle(
                          
                          fontSize: 12,
                          color: _onSurfaceVar,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primaryCont.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: _primaryCont.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.person_pin_rounded, color: _primary, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          widget.isEditing ? 'Edit Your Profile' : 'Set Up Your Profile',
          style: const TextStyle(
            
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isEditing
              ? 'Update your details below.'
              : 'Fill in your details to join study rooms and appear on the leaderboard.',
          style: const TextStyle(
            
            fontSize: 14,
            color: _onSurfaceVar,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _onSurfaceVar,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            
            fontSize: 14,
            color: _onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              
              fontSize: 14,
              color: _onSurfaceVar.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(icon, color: _onSurfaceVar, size: 18),
            filled: true,
            fillColor: _surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _error.withValues(alpha: 0.6)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryCont,
          foregroundColor: _onPrimaryCont,
          disabledBackgroundColor: _primaryCont.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _onPrimaryCont,
                ),
              )
            : Text(widget.isEditing ? 'Save Changes' : 'Save & Continue →'),
      ),
    );
  }
}
