import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/wrapped_card.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo from Image 3
            const Icon(Icons.auto_stories_rounded, size: 80, color: AppColors.cyan),
            const SizedBox(height: 16),
            Text("Welcome Back", 
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Study smarter. Know where you stand.", 
              style: GoogleFonts.inter(color: Colors.white60)),
            const SizedBox(height: 40),
            
            // The Wrapped Card Input Area
            WrappedCard(
              child: Column(
                children: [
                  TextField(decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.cyan),
                  )),
                  const SizedBox(height: 20),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.cyan),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Primary Action Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () {},
                child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}