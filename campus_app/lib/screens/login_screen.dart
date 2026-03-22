import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await ApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result.containsKey('user_id')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', result['user_id']);
      await prefs.setString('user_name', result['name'] ?? 'Student');
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(
          () => _errorMessage = result['message'] ?? 'Login failed');
    }
  }

  void _showForgotPassword(BuildContext context, bool isDark) {
    final emailController = TextEditingController();
    final studentIdController = TextEditingController();
    bool isLoading = false;
    String message = '';
    bool isError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + 24,
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
                        color: isDark
                            ? Colors.white24
                            : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your college email and student ID to verify your account.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email
                  Text('College Email',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                    decoration: const InputDecoration(
                        hintText: 'you@college.edu'),
                  ),

                  const SizedBox(height: 16),

                  // Student ID
                  Text('Student ID',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: studentIdController,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                    decoration: const InputDecoration(
                        hintText: '21ECE100'),
                  ),

                  const SizedBox(height: 16),

                  // Message
                  if (message.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isError
                            ? AppTheme.errorRed.withOpacity(0.1)
                            : AppTheme.foundMatch
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isError
                              ? AppTheme.errorRed
                                  .withOpacity(0.3)
                              : AppTheme.foundMatch
                                  .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isError
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: isError
                                ? AppTheme.errorRed
                                : AppTheme.foundMatch,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: 13,
                                color: isError
                                    ? AppTheme.errorRed
                                    : AppTheme.foundMatch,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Verify button
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            if (emailController.text.isEmpty ||
                                studentIdController
                                    .text.isEmpty) {
                              setModalState(() {
                                message =
                                    'Please fill in all fields';
                                isError = true;
                              });
                              return;
                            }
                            setModalState(
                                () => isLoading = true);
                            final result =
                                await ApiService.forgotPassword(
                              email:
                                  emailController.text.trim(),
                              studentId: studentIdController
                                  .text
                                  .trim(),
                            );
                            setModalState(() {
                              isLoading = false;
                              if (result
                                  .containsKey('message')) {
                                isError = false;
                                message =
                                    'Account verified! Please contact your administrator to reset your password.';
                              } else {
                                isError = true;
                                message = result['error'] ??
                                    'Account not found';
                              }
                            });
                          },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: AppTheme.goldGlowSoft,
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5),
                              )
                            : const Text(
                                'Verify Account',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBgGradient
              : AppTheme.lightBgGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme toggle
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () =>
                        MyApp.of(context)?.toggleTheme(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppTheme.gold.withOpacity(0.3)),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: AppTheme.gold,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Gold icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.goldGlow,
                  ),
                  child: const Icon(Icons.search,
                      color: Colors.black, size: 34),
                ),

                const SizedBox(height: 28),

                // Title
                Text(
                  'Hello again,',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? Colors.white : Colors.black87,
                    height: 1.2,
                  ),
                ),
                const GoldGradientText(
                  'Student!',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to your campus account',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : Colors.black45,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                // Email
                _buildLabel('College Email', isDark),
                const SizedBox(height: 8),
                _buildShadowBox(
                  isDark: isDark,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'you@college.edu',
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(14),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password
                _buildLabel('Password', isDark),
                const SizedBox(height: 8),
                _buildShadowBox(
                  isDark: isDark,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : Colors.black87),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.gold,
                          size: 20,
                        ),
                        onPressed: () => setState(() =>
                            _obscurePassword =
                                !_obscurePassword),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        _showForgotPassword(context, isDark),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Error message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.errorRed
                              .withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorRed,
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                                color: AppTheme.errorRed,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Sign in button
                GoldButton(
                  text: 'Secure Sign In',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              isDark
                                  ? Colors.white12
                                  : Colors.black12,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : Colors.black38,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isDark
                                  ? Colors.white12
                                  : Colors.black12,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Register button
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, '/register'),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.gold.withOpacity(0.5),
                        width: 1.5,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.gold.withOpacity(0.05),
                          AppTheme.gold.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.goldGradient
                                .createShader(bounds),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.black54,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildShadowBox(
      {required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (!isDark)
            BoxShadow(
              color: AppTheme.gold.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );
  }
}