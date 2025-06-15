import 'package:dynamic_background/domain/enums/scroller_shape.dart';
import 'package:dynamic_background/domain/enums/scroller_shape_offset.dart';
import 'package:dynamic_background/domain/models/color_schemes.dart';
import 'package:dynamic_background/domain/models/painter_data/scroller_painter_data.dart';
import 'package:dynamic_background/widgets/views/dynamic_bg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordle_clone/providers/theme_provider.dart';
import 'package:wordle_clone/widgets/about_app.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  ConsumerState<Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: DynamicBg(
        key: ValueKey(themeMode),
        painterData:
            themeMode == ThemeMode.light
                ? ScrollerPainterData(
                  shape: ScrollerShape.circles,
                  backgroundColor: ColorSchemes.gentleWhiteBg,
                  color: ColorSchemes.gentleWhiteFg,
                  shapeOffset: ScrollerShapeOffset.shiftAndMesh,
                )
                : ScrollerPainterData(
                  shape: ScrollerShape.circles,
                  backgroundColor: ColorSchemes.vibrantBlackFg,
                  // color: ColorSchemes.gentleBlackBg,
                  // backgroundColor: const Color.fromARGB(255, 81, 81, 81),
                  color: const Color.fromARGB(255, 45, 45, 45),
                  shapeOffset: ScrollerShapeOffset.shiftAndMesh,
                ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.02,
                horizontal: screenWidth * 0.02,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Rokkitt',
                      fontSize: screenWidth * 0.07,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                children: [
                  ListTile(
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontFamily: 'Rokkitt',
                        fontSize: screenWidth * 0.07,
                      ),
                    ),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        ref.read(themeModeProvider.notifier).state =
                            value ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'About App',
                      style: TextStyle(
                        fontFamily: 'Rokkitt',
                        fontSize: screenWidth * 0.07,
                      ),
                    ),
                    onTap: () {
                      showAboutAppDialog(context);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              child: Text(
                'Version 1.4.3',
                style: TextStyle(
                  fontFamily: 'Rokkitt',
                  fontSize: screenWidth * 0.05,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
