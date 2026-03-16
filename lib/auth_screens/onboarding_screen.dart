import 'package:flutter/material.dart';
import '../styles/appstyles.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Spacing
              const SizedBox(height: 40),

              // Logo
              // Image.asset('assets/logo.png', height: 150,),

              // Welcome Text
              Column(
                children: [
                  Text(
                    'Welcome !',
                    style: AppStyles.headLineStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login or Sign up to continue',
                    style: AppStyles.subHeadLineStyle,
                  ),

                  // vector illustration img
                  Image.asset('assets/onboarding_ill.png', height: 200,)
                ],
              ),

              // Sub-Title/ Desc
              Column(
                children: [
                  Text(
                    'Lorem Ipsum is simply dummy text',
                    textAlign: TextAlign.center,
                    style: AppStyles.subHeadLineStyle,
                  ),
                  Text(
                    'the printing and typesetting industry.',
                    textAlign: TextAlign.center,
                    style: AppStyles.subHeadLineStyle.copyWith(color: AppStyles.secondaryColor),
                  ),
                  SizedBox(height: 10,)
                ],
              ),

              // Buttons Section
              Column(
                children: [
                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () {
                          // Call onComplete if provided
                          widget.onComplete?.call();
                          // Navigate to create account
                          Navigator.pushNamed(context, '/create_acc');
                        },
                        style: AppStyles.primaryButtonStyle,
                        child: Text(
                            'Create Account',
                            style: AppStyles.subHeadLineStyle.copyWith(color: Colors.white))
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Call onComplete if provided
                        widget.onComplete?.call();
                        // Navigate to login
                        Navigator.pushNamed(context, '/login');
                      },
                      style: AppStyles.outLinedButtonStyle,
                      child: Text(
                        'Login',
                        style: AppStyles.subHeadLineStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Continue as Guest Text Button
                  TextButton(
                    onPressed: () {
                      // Handle continue as guest
                      // Call onComplete if provided
                      widget.onComplete?.call();
                      // Navigate as guest (you might want to create a guest mode)
                    },
                    child: Text(
                      'Continue as a guest ?',
                      style: AppStyles.subHeadLineStyle.copyWith(color: AppStyles.secondaryColor),
                    ),
                  ),
                ],
              ),

              // Bottom Spacing
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}