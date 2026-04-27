import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/wrapped_card.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text("Good Morning,", style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70)),
            Text("Chifundo!", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // Focus Session Card (Matches Image 1)
            WrappedCard(
              customBorderColors: [AppColors.deepViolet, AppColors.cyan],
              child: Column(
                children: [
                  const Text("START STUDY SESSION", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 30),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120, width: 120,
                        child: CircularProgressIndicator(value: 0.0, strokeWidth: 10, backgroundColor: Colors.white10, color: AppColors.deepViolet),
                      ),
                      Text("0%", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("Topic: Pharmacokinetics", style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text("from Pharmacology module", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepViolet,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text("START SESSION"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Daily Goal (Matches Image 1)
            WrappedCard(
              padding: 15,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Daily Goal: 3/6 Hours"),
                  Text("50%", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}