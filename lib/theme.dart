import 'package:flutter/material.dart';

const kGold = Color(0xFFb8860b);
const kGoldLight = Color(0xFFd4a017);
const kGoldPale = Color(0xFFfdf3d0);
const kGoldBorder = Color(0xFFe8c84a);
const kMaroon = Color(0xFF7b1c1c);
const kMaroonLight = Color(0xFFa52a2a);
const kBg = Color(0xFFf7f3ec);
const kCard = Color(0xFFffffff);
const kTextPrimary = Color(0xFF1c1208);
const kTextSecondary = Color(0xFF5a4a2a);
const kTextMuted = Color(0xFF9a8060);

final appTheme = ThemeData(
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.light(
    primary: kGold,
    secondary: kMaroon,
    surface: kCard,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kMaroon,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kGold,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGoldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGoldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGold, width: 2),
    ),
    labelStyle: const TextStyle(color: kTextSecondary),
  ),
);

LinearGradient get headerGradient => const LinearGradient(
      colors: [kMaroon, kGold],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient get goldGradient => const LinearGradient(
      colors: [kGold, kGoldLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

BoxDecoration cardDecoration({double radius = 18}) => BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kGoldBorder.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: kGold.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
