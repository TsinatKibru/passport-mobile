import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth_provider.dart';
import '../core/theme/app_theme.dart';

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
      final error = ref.read(authProvider).errorMessage ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

 @override
Widget build(BuildContext context) {
  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: const Color(0xFFF5F7FA),
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
                  child: Image.asset(
                    'assets/images/ics-logo.png',
                    fit: BoxFit.contain,
                  ),
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
                color: Colors.white,
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

                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),


                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),

                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
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
                            return 'Username is required';
                          }
                          return null;
                        },
                      ),


                      const SizedBox(height: 14),


                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,

                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),

                        decoration: InputDecoration(
                          hintText: 'Password',

                          hintStyle: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),

                          filled: true,
                          fillColor: AppColors.inputFill,

                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,

                              color: AppColors.textSecondary,
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
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
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
                            return 'Password is required';
                          }

                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
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
                                      AppColors.primary,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
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
                                const SnackBar(
                                  content: Text(
                                    'Contact your administrator to reset password',
                                  ),
                                ),
                              );

                            },

                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
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
                                AppColors.primary,

                            foregroundColor:
                                Colors.white,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            elevation: 0,
                          ),


                          child: _loading

                              ? const SizedBox(
                                  height: 20,
                                  width: 20,

                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,

                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )

                              : const Text(
                                  'Login',

                                  style: TextStyle(
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
