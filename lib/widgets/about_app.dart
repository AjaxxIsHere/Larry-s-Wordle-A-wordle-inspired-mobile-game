import 'package:flutter/material.dart';

void showAboutAppDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
            width: 2,
          ),
        ),
        title: const Text(
          'About App',
          style: TextStyle(
            fontFamily: 'Rokkitt',
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        content: const Text(
          "Test your word skills with \"Larry's Word,\" a captivating Wordle clone featuring daily challenges and unlimited play modes. Enjoy dynamic animations, responsive design, and seamless game state saving, all wrapped in a visually appealing interface with customizable themes. Discover hidden surprises and master the art of word guessing in this engaging game! \nMade by Mohamad Ajaz with ❤️",
          style: TextStyle(fontFamily: 'Rokkitt', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Rokkitt',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.lightGreenAccent
                        : Colors.green,
              ),
            ),
          ),
        ],
      );
    },
  );
}
