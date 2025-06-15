import 'package:flutter/material.dart';

void showDailyChallengeCompletedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
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
            'Daily Challenge Completed 🎉',
            style: TextStyle(
              fontFamily: 'Rokkitt',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: const Text(
            'You have completed today\'s challenge. Come back tomorrow for a new word!',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
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
        ),
  );
}
