import 'package:flutter/material.dart';

class ErrorMessage extends StatefulWidget {
  final String message;

  const ErrorMessage({super.key, required this.message});

  @override
  ErrorMessageState createState() => ErrorMessageState();
}

class ErrorMessageState extends State<ErrorMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Starts from the bottom of the screen
      end: Offset.zero, // Ends at its natural position (center for AlertDialog)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // Dispose of the controller after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) {
          Navigator.of(context).pop(); // Close the dialog
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Align(
        // Use Align to position the dialog at the bottom
        alignment: Alignment.bottomCenter,
        child: Material(
          // Wrap in Material to avoid direct AlertDialog sizing issues with Align
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 50.0,
              left: 20.0,
              right: 20.0,
            ), 
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800] // Dark mode background for bubble
                      : Colors.grey[200], // Light mode background for bubble
              borderRadius: BorderRadius.circular(
                10,
              ), // Rounded corners for the speech bubble look
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black, // Text color based on theme
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent, // Make the background transparent
    builder: (BuildContext context) {
      return ErrorMessage(message: message);
    },
  );
}
