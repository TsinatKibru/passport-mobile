import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // The ICS logo art is designed for light backgrounds (dark-blue wordmark
  // + faint cityscape on a transparent bg). In dark mode we mirror the
  // web-admin's logo treatment: soften (opacity) and lift the artwork with a
  // brightness/contrast colour-matrix so the dark-blue reads and blends on the
  // dark surface instead of sitting dark-on-dark. Values are gentle — tune to taste.
  Widget _brandLogo(bool isDark) {
    const asset = Image(
      image: AssetImage('assets/images/ics-logo.png'),
      fit: BoxFit.contain,
    );
    if (!isDark) return asset;
    return Opacity(
      opacity: 0.92,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 22, // R = R*1.2 + 22
          0, 1.2, 0, 0, 22, // G
          0, 0, 1.2, 0, 22, // B
          0, 0, 0, 1, 0, // A (unchanged — keeps transparency)
        ]),
        child: asset,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (mounted) {
      setState(() => _loading = false);
    }

    if (!success && mounted) {
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

 @override
Widget build(BuildContext context) {
  final l = AppLocalizations.of(context);
  final c = context.colors;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: c.surface,
    body: SafeArea(
      child: Stack(
        children: [

          // Fixed Logo Section
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: SizedBox(
                  height: 250,
                  child: _brandLogo(isDark),
                ),
              ),
            ),
          ),


          // Login Card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            top: screenHeight * 0.42 - keyboardHeight,

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


                      TextFormField(
                        controller: _emailController,
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

                            onPressed: () {
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

                                  onChanged: (value) {
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
                            onPressed: () {

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l.loginForgotPasswordHint,
                                  ),
                                ),
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

                          onPressed:
                              _loading ? null : _submit,

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                c.primary,

                            foregroundColor:
                                c.onPrimary,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            elevation: 0,
                          ),


                          child: _loading

                              ? SizedBox(
                                  height: 20,
                                  width: 20,

                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,

                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                      c.onPrimary,
                                    ),
                                  ),
                                )

                              : Text(
                                  l.loginButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w600,
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
        ],
      ),
    ),
  );
}
}

// Removed CityscapePainter - no longer needed
