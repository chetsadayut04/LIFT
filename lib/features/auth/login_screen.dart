import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      if (_isSignUp) {
        await ref.read(authProvider.notifier).signUpWithEmail(email, password);
        if (mounted) {
          _showCustomSnackBar(
            context: context,
            message:
                'สมัครสมาชิกสำเร็จแล้ว! เข้าสู่ระบบหรือตรวจสอบอีเมลของคุณเพื่อยืนยันบัญชี',
            isError: false,
          );
          setState(() {
            _isSignUp = false;
          });
        }
      } else {
        await ref.read(authProvider.notifier).signInWithEmail(email, password);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('invalid_credentials') ||
        str.contains('Invalid login credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง หรือสมัครสมาชิกหากยังไม่มีบัญชี';
    }
    if (str.contains('email_not_confirmed') ||
        str.contains('Email not confirmed')) {
      return 'กรุณายืนยันอีเมลของคุณก่อนเข้าสู่ระบบ โดยคลิกลิงก์ยืนยันในกล่องข้อความอีเมลของคุณ';
    }
    if (str.contains('user_already_exists') ||
        str.contains('User already registered') ||
        str.contains('already exists')) {
      return 'อีเมลนี้ถูกใช้งานไปแล้ว กรุณาเข้าสู่ระบบ หรือใช้อีเมลอื่นสมัครสมาชิก';
    }
    if (str.contains('weak_password') ||
        str.contains('should be at least 6 characters')) {
      return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
    }
    if (str.contains('invalid_email') ||
        str.contains('Unable to validate email')) {
      return 'รูปแบบอีเมลไม่ถูกต้อง กรุณาตรวจสอบการสะกดอีเมล';
    }
    if (str.contains('network') ||
        str.contains('SocketException') ||
        str.contains('Network')) {
      return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบเครือข่ายของคุณ';
    }
    if (str.contains('rate_limit') ||
        str.contains('rate limit exceeded') ||
        str.contains('over_email_send_rate_limit') ||
        str.contains('429')) {
      return 'คุณส่งคำขอส่งอีเมลบ่อยเกินไปเพื่อความปลอดภัย กรุณารอ 1-2 นาที แล้วลองใหม่อีกครั้งครับ';
    }
    return str
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException: ', '')
        .replaceAll('AuthApiException: ', '');
  }

  void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required bool isError,
  }) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? const Color(0xFFFF8A8A) : accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? const Color(0xFFFFC5C5)
                      : const Color(0xFFF2F5EF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFF2C1010)
            : const Color(0xFF151816),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? const Color(0xFFFF8A8A).withValues(alpha: 0.4)
                : accent.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final accent = Theme.of(context).colorScheme.primary;
        const textPrimary = Color(0xFFFFFFFF);
        const textMuted = Color(0xFF94A3B8);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF171B17), // Match rgba(23,27,23,0.92)
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: accent.withValues(alpha: 0.1)),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รีเซ็ตรหัสผ่าน',
                    style: GoogleFonts.barlowCondensed(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรอกอีเมลของคุณเพื่อรับลิงก์รีเซ็ตรหัสผ่าน',
                    style: GoogleFonts.sarabun(
                      color: textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.sarabun(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E211F),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'อีเมลของคุณ',
                    hintStyle: GoogleFonts.sarabun(color: textMuted, fontSize: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'กรุณากรอกอีเมล';
                    if (!val.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                    return null;
                  },
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSending ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E211F),
                          foregroundColor: const Color(0xFF8E9A8E),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: GoogleFonts.sarabun(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setState(() {
                                  isSending = true;
                                });
                                try {
                                  await ref
                                      .read(authProvider.notifier)
                                      .sendPasswordResetEmail(emailController.text);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    _showCustomSnackBar(
                                      context: context,
                                      message:
                                          'ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณแล้ว! กรุณาตรวจสอบกล่องข้อความ',
                                      isError: false,
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    _showCustomSnackBar(
                                      context: context,
                                      message:
                                          'เกิดข้อผิดพลาด: ${_getFriendlyErrorMessage(e)}',
                                      isError: true,
                                    );
                                  }
                                } finally {
                                  setState(() {
                                    isSending = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: const Color(0xFF0A0C0A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                        ),
                        child: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0A0C0A),
                                ),
                              )
                            : Text(
                                'ส่ง',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final accent = Theme.of(context).colorScheme.primary;
    const textPrimary = Color(0xFFFFFFFF);
    const textMuted = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Radial Gradient 1 (bottom left)
          Positioned(
            left: -150,
            bottom: -150,
            width: 400,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Radial Gradient 2 (top right)
          Positioned(
            right: -100,
            top: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Logo/Header Section (Left-aligned as in Figma)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIFT',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: -1.0,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ติดตามการฝึกซ้อม · วิเคราะห์สถิติ · เติบโตขึ้น',
                              style: GoogleFonts.sarabun(
                                fontSize: 14,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Toggle Login/SignUp mode (Glassmorphic)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1F1B).withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _isSignUp = false;
                                      _errorMessage = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !_isSignUp ? accent : Colors.transparent,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        'เข้าสู่ระบบ',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.sarabun(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: !_isSignUp ? bg : const Color(0xFF5A6A5A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _isSignUp = true;
                                      _errorMessage = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isSignUp ? accent : Colors.transparent,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        'สมัครสมาชิก',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.sarabun(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: _isSignUp ? bg : const Color(0xFF5A6A5A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error Display
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C1010).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF8A8A).withValues(alpha: 0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5A3C).withValues(alpha: 0.08),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFFF8A8A),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFFFC5C5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFFFF8A8A),
                                  size: 16,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field (Vite styles: background: rgba(27,31,27,0.6), border: 1px solid rgba(255,255,255,0.09))
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.sarabun(color: textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1B1F1B).withValues(alpha: 0.6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          hintText: 'อีเมล',
                          hintStyle: GoogleFonts.sarabun(color: const Color(0xFF5A6A5A), fontSize: 15),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF5A6A5A), size: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'กรุณากรอกอีเมล';
                          if (!val.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.sarabun(color: textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1B1F1B).withValues(alpha: 0.6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          hintText: 'รหัสผ่าน',
                          hintStyle: GoogleFonts.sarabun(color: const Color(0xFF5A6A5A), fontSize: 15),
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: Color(0xFF5A6A5A),
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                          if (val.length < 6) return 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร';
                          return null;
                        },
                      ),
                      const SizedBox(height: 5),

                      // Forgot password (Figma style)
                      if (!_isSignUp) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'ลืมรหัสผ่าน?',
                              style: GoogleFonts.sarabun(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Submit Button
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: bg,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(bg),
                                ),
                              )
                            : Text(
                                _isSignUp ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Divider "หรือ"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.07),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'หรือ',
                              style: GoogleFonts.sarabun(
                                color: const Color(0xFF5A6A5A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.07),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google Login Button (Vite style)
                      OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E211F),
                          foregroundColor: const Color(0xFFCCCCCC),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Custom G logo container
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'เข้าสู่ระบบด้วย Google',
                              style: GoogleFonts.sarabun(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFCCCCCC),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Demo Hint Text
                      Text(
                        'Demo: อีเมลใดก็ได้ + รหัสผ่าน lift123',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sarabun(
                          color: const Color(0xFF333333),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
