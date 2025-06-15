import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

final darkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark;
});

class LogoWidget extends ConsumerWidget {
  final double width;
  final double height;

  const LogoWidget({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return Image.asset(
      isDarkMode ? 'assets/images/logoinvert.png' : 'assets/images/logo.png',
      width: width,
      height: height,
    );
  }
}
