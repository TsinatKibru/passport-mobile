import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _success = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    const storage = FlutterSecureStorage();
    final email = await storage.read(key: 'rememberedEmail');
    if (email != null && email.isNotEmpty) {
      if (mounted) {
        setState(() {
          _emailController.text = email;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // The ICS logo art is designed for light backgrounds: a dark-blue wordmark
  // (top ~25-65% of the image) plus a pale cityscape silhouette along the
  // bottom (~70-100%), all on a transparent bg. In dark mode that reads badly —
  // the wordmark is dark-on-dark and the pale cityscape glows near-white.
  // Treatment (mirrors the web-admin's dark-mode logo handling):
  //   1) lift the dark-blue artwork with a brightness colour-matrix so it reads,
  //   2) fade out the bottom cityscape band with a vertical gradient mask so it
  //      doesn't sit as a white block on the dark surface.
  // Light mode is untouched. Fade stops / lift are gentle — tune to taste.
  Widget _brandLogo(bool isDark) {
    return Image.asset(
      isDark
          ? 'assets/images/dark_mode_brand.png'
          : 'assets/images/light_mode_brand.png',
      fit: BoxFit.cover,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _success = false;
    });
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success) {
      const storage = FlutterSecureStorage();
      if (_rememberMe) {
        await storage.write(key: 'rememberedEmail', value: _emailController.text.trim());
      } else {
        await storage.delete(key: 'rememberedEmail');
      }
      if (mounted) {
        setState(() {
          _success = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      if (mounted) {
        final l = AppLocalizations.of(context);
        final error = ref.read(authProvider).errorMessage ?? l.loginFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: context.colors.danger,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

 @override
Widget build(BuildContext context) {
  final l = AppLocalizations.of(context);
  final c = context.colors;
  final authState = ref.watch(authProvider);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: c.surface,
    body: Stack(
      children: [

        // Fixed Logo Section (bleeds edge-to-edge outside SafeArea)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.45,
          child: _brandLogo(isDark),
        ),

        // Login Card
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          bottom: keyboardHeight,
          top: screenHeight * 0.42 - keyboardHeight,

          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),

              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Text(
                        l.loginWelcome,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        l.loginSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: c.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.danger.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: c.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: TextStyle(
                                    color: c.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _emailController,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textBody,
                        ),

                        decoration: InputDecoration(
                          hintText: l.loginUsername,
                          hintStyle: TextStyle(
                            color: c.textHint,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: c.inputFill,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: c.border,
                            ),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: c.border,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: c.primary,
                              width: 2,
                            ),
                          ),

                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),

                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return l.loginUsernameRequired;
                          }
                          return null;
                        },
                      ),


                      const SizedBox(height: 14),


                      TextFormField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: _obscurePassword,

                        style: TextStyle(
                          fontSize: 14,
                          color: c.textBody,
                        ),

                        decoration: InputDecoration(
                          hintText: l.loginPassword,

                          hintStyle: TextStyle(
                            color: c.textHint,
                            fontSize: 14,
                          ),

                          filled: true,
                          fillColor: c.inputFill,

                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,

                              color: c.textSecondary,
                              size: 20,
                            ),

                            onPressed: _loading ? null : () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                          ),


                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: c.border,
                            ),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: c.border,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: c.primary,
                              width: 2,
                            ),
                          ),

                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),

                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return l.loginPasswordRequired;
                          }

                          if (val.length < 6) {
                            return l.loginPasswordMinLength;
                          }

                          return null;
                        },
                      ),


                      const SizedBox(height: 14),


                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [

                          Row(
                            children: [

                              SizedBox(
                                height: 20,
                                width: 20,

                                child: Checkbox(
                                  value: _rememberMe,

                                  onChanged: _loading ? null : (value) {
                                    setState(() {
                                      _rememberMe =
                                          value ?? false;
                                    });
                                  },

                                  activeColor:
                                      c.primary,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Text(
                                l.loginRememberMe,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.primary,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ],
                          ),


                          TextButton(
                            onPressed: _loading ? null : () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return _ForgotPasswordBottomSheet(
                                    initialEmail: _emailController.text.trim(),
                                  );
                                },
                              );
                            },

                            child: Text(
                              l.loginForgotPassword,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.primary,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),


                      const SizedBox(height: 20),


                      SizedBox(
                        width: double.infinity,
                        height: 48,

                        child: ElevatedButton(
                          onPressed: _loading || _success ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _success ? c.success : c.primary,
                            foregroundColor: c.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _success
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: c.onPrimary,
                                  size: 24,
                                )
                              : _loading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          c.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      l.loginButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
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

class _ForgotPasswordBottomSheet extends ConsumerStatefulWidget {
  final String initialEmail;

  const _ForgotPasswordBottomSheet({required this.initialEmail});

  @override
  ConsumerState<_ForgotPasswordBottomSheet> createState() =>
      __ForgotPasswordBottomSheetState();
}

class __ForgotPasswordBottomSheetState
    extends ConsumerState<_ForgotPasswordBottomSheet> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  late final _emailController = TextEditingController(text: widget.initialEmail);
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  int _step = 1; // 1: Request OTP, 2: Reset Password
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final error = await repo.requestPasswordResetOtp(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _loading = false;
        if (error == null) {
          _step = 2;
        } else {
          _errorMessage = error;
        }
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final error = await repo.resetPasswordWithOtp(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        if (error == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully. Please log in.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _errorMessage = error;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _step == 1 ? 'Forgot Password' : 'Reset Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _step == 1
                ? 'Enter your email address and we will send you a 6-digit OTP code to reset your password.'
                : 'Enter the 6-digit code sent to ${_emailController.text} and your new password.',
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: c.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.danger.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: c.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: c.danger, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_step == 1)
            Form(
              key: _emailFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    enabled: !_loading,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: c.textBody, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                      filled: true,
                      fillColor: c.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!val.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _requestOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(c.onPrimary),
                              ),
                            )
                          : Text(
                              'Send OTP',
                              style: TextStyle(
                                color: c.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            )
          else
            Form(
              key: _resetFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _otpController,
                    enabled: !_loading,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: c.textBody, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '6-digit OTP Code',
                      hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                      filled: true,
                      fillColor: c.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'OTP is required';
                      if (val.length != 6) return 'OTP must be 6 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_loading,
                    obscureText: true,
                    style: TextStyle(color: c.textBody, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'New Password',
                      hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                      filled: true,
                      fillColor: c.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_loading,
                    obscureText: true,
                    style: TextStyle(color: c.textBody, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Confirm New Password',
                      hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                      filled: true,
                      fillColor: c.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please confirm your password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(c.onPrimary),
                              ),
                            )
                          : Text(
                              'Reset Password',
                              style: TextStyle(
                                color: c.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
