import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int rating = 5;
  final TextEditingController feedbackController = TextEditingController();

  void submitFeedback() {
    String feedback = feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your feedback")));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your feedback!")));
    feedbackController.clear();
    setState(() => rating = 5);
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
        title: const Text("Feedback", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: theme.dividerColor),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Give app rating", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setState(() => rating = index + 1),
                        icon: Icon(Icons.star, color: index < rating ? AppColors.primary : AppColors.textSecondary, size: 32),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Write feedback message", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary)),
              child: TextField(
                controller: feedbackController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: "Enter your feedback here...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(text: "Submit Feedback", onPressed: submitFeedback),
          ],
        ),
      ),
    );
  }
}
