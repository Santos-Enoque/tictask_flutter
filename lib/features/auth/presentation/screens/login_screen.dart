import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/app/theme/text_styles.dart';
import 'package:tictask/features/auth/presentation/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true; // Toggle between login and register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuth() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isLogin) {
      context.read<AuthBloc>().add(
            SignInWithEmailAndPassword(
              email: email,
              password: password,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            CreateUserWithEmailAndPassword(
              email: email,
              password: password,
            ),
          );
    }
  }

  void _handleMagicLink() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          SignInWithMagicLink(
            email: _emailController.text.trim(),
          ),
        );
  }

  void _handleAnonymousLogin() {
    context.read<AuthBloc>().add(SignInAnonymously());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final formWidth = screenSize.width > 600 ? 450.0 : screenSize.width * 0.9;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          widget.onLoginSuccess();
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AuthLoading) {
          // Optional: Show loading indicator
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Container(
                  width: formWidth,
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App logo/title
                          Center(
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Text(
                            'TicTask',
                            style: AppTextStyles.displaySmall(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.xl),

                          // Login/Register form
                          Text(
                            _isLogin ? 'Sign In' : 'Create Account',
                            style: AppTextStyles.headlineSmall(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.lg),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd),
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppDimensions.md),

                          // Password field - only shown for login/register, not for magic link
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd),
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (!_isLogin && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppDimensions.xl),

                          // Login/Register button
                          ElevatedButton(
                            onPressed: isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                          const SizedBox(height: AppDimensions.md),

                          // Magic link option
                          Center(
                            child: TextButton.icon(
                              onPressed: isLoading ? null : _handleMagicLink,
                              icon: const Icon(Icons.link),
                              label: const Text('Sign in with Magic Link'),
                            ),
                          ),

                          // Toggle between login and register
                          Center(
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                      });
                                    },
                              child: Text(
                                _isLogin
                                    ? 'Need an account? Register'
                                    : 'Have an account? Sign In',
                              ),
                            ),
                          ),

                          const SizedBox(height: AppDimensions.md),
                          const Divider(),
                          const SizedBox(height: AppDimensions.md),

                          // Anonymous login option
                          OutlinedButton.icon(
                            onPressed: isLoading ? null : _handleAnonymousLogin,
                            icon: const Icon(Icons.person_outline),
                            label: const Text('Continue without Account'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),

                          // Note about anon accounts
                          const SizedBox(height: AppDimensions.sm),
                          Text(
                            'Anonymous accounts can sync between sessions on the same device but not across devices',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
