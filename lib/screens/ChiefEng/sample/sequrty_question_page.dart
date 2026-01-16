import 'package:flutter/material.dart';

class SecurityQuestionsScreen extends StatefulWidget {
  const SecurityQuestionsScreen({super.key});

  @override
  State<SecurityQuestionsScreen> createState() =>
      _SecurityQuestionsScreenState();
}

class _SecurityQuestionsScreenState extends State<SecurityQuestionsScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
           // backgroundColor: Colors.yellow,


      appBar: AppBar(
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        title: const Text('Securityedqw  Questions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '# Security Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Question 1
            const Text(
              'Your answer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _answerController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: 'Enter your answer',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Question 2
            const Text(
              '### Question 2',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '**What was your childhood nickname?**',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your answer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nicknameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: 'Enter your childhood nickname',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateSecurityQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  '[Update Security Questions]',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Security Tips Section
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              //  border: Border.all(color: Colors.grey[300]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '## Security Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SecurityTipItem(
                      text: 'Choose answers only you would know'),
                  const _SecurityTipItem(
                      text: 'Avoid answers found on social media'),
                  const _SecurityTipItem(text: 'Answers are case-sensitive'),
                  const _SecurityTipItem(
                      text: 'These will be used for password recovery'),
                  const _SecurityTipItem(
                      text: 'Store answers securely - do not share'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSecurityQuestions() {
    if (_answerController.text.isEmpty || _nicknameController.text.isEmpty) {
      _showSnackBar('Please answer all security questions');
      return;
    }

    // Here you would typically save the answers to your backend
    final answers = {
      'question1': _answerController.text,
      'question2': _nicknameController.text,
    };

    _showSnackBar('Security questions updated successfully!');
    print('Security Answers: $answers');

    // Clear fields after submission
    _answerController.clear();
    _nicknameController.clear();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SecurityTipItem extends StatelessWidget {
  final String text;


  const _SecurityTipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(Icons.circle, size: 6),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
