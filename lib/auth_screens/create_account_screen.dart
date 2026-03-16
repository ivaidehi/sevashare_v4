import 'package:flutter/material.dart';
import 'package:sevashare_v4/services/auth_service.dart';
import 'package:sevashare_v4/custom_widgets/custom_inputfield.dart';
import 'package:sevashare_v4/styles/appstyles.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _agreeToPrivacyPolicy = false;
  int _selectedTab = 0; // 0 for User, 1 for Service Provider
  bool _isLoading = false;
  String _errorMessage = '';

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_agreeToPrivacyPolicy) {
      setState(() {
        _errorMessage = 'Please agree to the privacy policy';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        mobile: _mobileController.text.trim(),
        userType: _selectedTab == 0 ? 'user' : 'service_provider',
      );

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/bottom_nav_bar');
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedTab == 0
                  ? 'User account created successfully!'
                  : 'Service Provider account created successfully!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

          // Navigate to home screen or verify email screen
          // if (!user.emailVerified) {
          //   await user.sendEmailVerification();
          //   // Show verification screen
          //   _showVerificationDialog();
          //   // Additional snackbar for verification email
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('Verification email sent to ${user.email}'),
          //       backgroundColor: Colors.blue,
          //       duration: Duration(seconds: 4),
          //     ),
          //   );
          // } else {
          //   Navigator.pushReplacementNamed(context, '/home');
          // }
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {

        // Extract user-friendly error message
        String errorMessage;
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'This email is already registered';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Check your connection';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak. Use at least 8 characters';
        } else {
          errorMessage = 'Failed to create account: ${e.toString().replaceFirst('Exception: ', '')}';
        }

        _errorMessage = e.toString();
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Email'),
        content: const Text(
          'A verification email has been sent to your email address. '
          'Please verify your email to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    // Back Button
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppStyles.primaryColor,
                        size: 24,
                      ),
                    ),
                    Text(
                      'Create Account',
                      style: AppStyles.headLineStyle.copyWith(
                        fontSize: 32,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),
                // Subtitle
                Text(
                  'Fill your information below or register with your social account.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 25),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage.isNotEmpty) const SizedBox(height: 15),

                // User/Service Provider Tabs
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      // User Tab
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTab = 0;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? AppStyles.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 0
                                    ? [
                                        BoxShadow(
                                          color: AppStyles.primaryColor
                                              .withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Register as User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Service Provider Tab
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTab = 1;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? AppStyles.primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _selectedTab == 1
                                    ? [
                                        BoxShadow(
                                          color: AppStyles.primaryColor
                                              .withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    'Register as Service Provider',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Email Address Field
                CustomInputField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  warning: "Please enter a valid email address",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Mobile Number Field
                CustomInputField(
                  controller: _mobileController,
                  labelText: 'Mobile Number',
                  warning: "Please enter a valid mobile number",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                // Password Field
                CustomInputField(
                  controller: _passwordController,
                  labelText: 'Password',
                  warning: "Password must be at least 8 characters",
                  isHide: true,
                  eyeIcon: true,
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                CustomInputField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  warning: "Passwords do not match",
                  isHide: true,
                  eyeIcon: true,
                ),
                const SizedBox(height: 20),

                // Privacy Policy Checkbox
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _agreeToPrivacyPolicy,
                        onChanged: (value) {
                          setState(() {
                            _agreeToPrivacyPolicy = value ?? false;
                          });
                        },
                        activeColor: AppStyles.primaryColor,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'I agree with ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            TextSpan(
                              text: 'privacy policy',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppStyles.secondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: _selectedTab == 1
                                  ? ' and service provider terms'
                                  : '',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppStyles.secondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _agreeToPrivacyPolicy
                        ? _signUp
                        : null,
                    style: AppStyles.primaryButtonStyle.copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey[300]!;
                          }
                          return AppStyles.primaryColor;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey[500]!;
                          }
                          return Colors.white;
                        },
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
                        : Text(
                            _selectedTab == 0
                                ? 'Sign Up as User'
                                : 'Sign Up as Service Provider',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                // Divider with "Or" text
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        'Or Sign Up with',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[300], thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Social Media Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      imagePath: "assets/google.jpg",
                      color: Colors.blue[800]!,
                      // onTap: _signInWithGoogle,
                    ),
                    const SizedBox(width: 20),
                    _buildSocialButton(
                      icon: Icons.facebook,
                      color: Colors.blue[800]!,
                      // onTap: _signInWithFacebook,
                    ),
                    const SizedBox(width: 20),
                    _buildSocialButton(
                      icon: Icons.apple,
                      color: Colors.black,
                      onTap: _signInWithApple,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Already have an account
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppStyles.secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _signInWithGoogle() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });
  //
  //   try {
  //     final user = await _authService.signInWithGoogle();
  //     if (user != null) {
  //       Navigator.pushReplacementNamed(context, '/home');
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = e.toString();
  //     });
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }
  //
  // Future<void> _signInWithFacebook() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });
  //
  //   try {
  //     final user = await _authService.signInWithFacebook();
  //     if (user != null) {
  //       Navigator.pushReplacementNamed(context, '/home');
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = e.toString();
  //     });
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await _authService.signInWithApple();
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSocialButton({
    IconData? icon,
    String? imagePath,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: IconButton(
        onPressed: _isLoading ? null : onTap,
        icon: imagePath != null
            ? Image.asset(imagePath, width: 24, height: 24)
            : Icon(icon, color: color, size: 24),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
