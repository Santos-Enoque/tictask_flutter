import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/app/theme/text_styles.dart';
import 'package:tictask/app/services/auth_service.dart';

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
  
  bool _isLoading = false;
  bool _isLogin = true; // Toggle between login and register
  String? _errorMessage;
  
  final AuthService _authService = GetIt.I<AuthService>();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleAuth() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_isLogin) {
        // Login
        await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Register
        await _authService.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      
      // Call success callback
      widget.onLoginSuccess();
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      debugPrint('Auth error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _handleMagicLink() async {
    // Validate email
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _authService.signInWithMagicLink(
        email: _emailController.text.trim(),
      );
      
      // Show confirmation dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email for the login link!'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send magic link. Please try again.';
      });
      debugPrint('Magic link error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _handleAnonymousLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _authService.signInAnonymously();
      
      // Call success callback
      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in anonymously. Please try again.';
      });
      debugPrint('Anonymous login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo/title
                  Icon(
                    Icons.timer,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    'TicTask',
                    style: AppTextStyles.displaySmall(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  
                  // Login/Register form
                  Text(
                    _isLogin ? 'Sign In' : 'Create Account',
                    style: AppTextStyles.headlineSmall(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  
                  // Error message if any
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                  ],
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  
                  // Password field - only shown for login/register, not for magic link
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock),
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
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  
                  // Login/Register button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isLogin ? 'Sign In' : 'Create Account'),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  
                  // Magic link option
                  TextButton.icon(
                    onPressed: _isLoading ? null : _handleMagicLink,
                    icon: const Icon(Icons.link),
                    label: const Text('Sign in with Magic Link'),
                  ),
                  
                  // Toggle between login and register
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? 'Need an account? Register'
                          : 'Have an account? Sign In',
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.md),
                  const Divider(),
                  const SizedBox(height: AppDimensions.md),
                  
                  // Anonymous login option
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleAnonymousLogin,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Continue without Account'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                  
                  // Note about anon accounts
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Anonymous accounts can sync between sessions on the same device but not across devices',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}