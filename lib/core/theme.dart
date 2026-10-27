import 'package:flutter/material.dart';

const navy = Color(0xff011935);
const deepNavy = Color(0xff001f3f);
const green = Color(0xff57d463);
const promotionAmber = Color(0xffe6b86a);

class CategoryVisual {
  final String id, shortLabel, callLabel, emergencyPhone;
  final Color color;
  final String? asset;
  final IconData icon;
  const CategoryVisual({
    required this.id,
    required this.shortLabel,
    required this.color,
    required this.icon,
    this.asset,
    this.callLabel = 'Llamar a Emergencias (105)',
    this.emergencyPhone = '105',
  });
}

CategoryVisual categoryVisual(String type) => switch (type) {
  'crime' => const CategoryVisual(
    id: 'crime',
    shortLabel: 'Crimen',
    color: Color(0xff573a83),
    icon: Icons.report_outlined,
    callLabel: 'Llamar a Policía (105)',
  ),
  'theft' => const CategoryVisual(
    id: 'theft',
    shortLabel: 'Robo',
    color: Color(0xff7e22ce),
    asset: 'assets/images/theft.png',
    icon: Icons.shield_outlined,
    callLabel: 'Llamar a Policía (105)',
    emergencyPhone: '105',
  ),
  'fire' => const CategoryVisual(
    id: 'fire',
    shortLabel: 'Incendio',
    color: Color(0xffea580c),
    asset: 'assets/images/fire.png',
    icon: Icons.local_fire_department_rounded,
    callLabel: 'Llamar a Bomberos (116)',
    emergencyPhone: '116',
  ),
  'emergency' => const CategoryVisual(
    id: 'emergency',
    shortLabel: 'Emergencia',
    color: Color(0xffb91c1c),
    asset: 'assets/images/alert.png',
    icon: Icons.medical_services_rounded,
    callLabel: 'Llamar a SAMU (106)',
    emergencyPhone: '106',
  ),
  'crash' => const CategoryVisual(
    id: 'crash',
    shortLabel: 'Accidente',
    color: Color(0xff2563eb),
    asset: 'assets/images/car.png',
    icon: Icons.car_crash_rounded,
    callLabel: 'Llamar a Emergencias (105)',
    emergencyPhone: '105',
  ),
  'extortion' => const CategoryVisual(
    id: 'extortion',
    shortLabel: 'Extorsión',
    color: Color(0xff4f46e5),
    asset: 'assets/images/alert.png',
    icon: Icons.gpp_maybe_rounded,
    callLabel: 'Denunciar Extorsión (1818)',
    emergencyPhone: '1818',
  ),
  'kidnapping' => const CategoryVisual(
    id: 'kidnapping',
    shortLabel: 'Secuestro',
    color: Color(0xff991b1b),
    asset: 'assets/images/alert.png',
    icon: Icons.warning_amber_rounded,
    callLabel: 'Llamar a Policía (105)',
    emergencyPhone: '105',
  ),
  'violence' => const CategoryVisual(
    id: 'violence',
    shortLabel: 'Violencia',
    color: Color(0xffbe123c),
    asset: 'assets/images/alert.png',
    icon: Icons.report_problem_rounded,
    callLabel: 'Llamar a Policía (105)',
    emergencyPhone: '105',
  ),
  'homicide' => const CategoryVisual(
    id: 'homicide',
    shortLabel: 'Alerta grave',
    color: Color(0xff7f1d1d),
    asset: 'assets/images/alert.png',
    icon: Icons.emergency_rounded,
    callLabel: 'Llamar a Policía (105)',
    emergencyPhone: '105',
  ),
  'pet' => const CategoryVisual(
    id: 'pet',
    shortLabel: 'Mascotas',
    color: Color(0xff795548),
    asset: 'assets/images/dog.png',
    icon: Icons.pets_rounded,
    callLabel: 'Llamar a Serenazgo / Ayuda',
    emergencyPhone: '105',
  ),
  'place' => const CategoryVisual(
    id: 'place',
    shortLabel: 'Lugares de ayuda',
    color: Color(0xffd97706),
    asset: 'assets/images/place_icon.png',
    icon: Icons.volunteer_activism_rounded,
    callLabel: 'Directorio de ayuda',
    emergencyPhone: '106',
  ),
  _ => const CategoryVisual(
    id: 'other',
    shortLabel: 'Alerta',
    color: Color(0xff0f766e),
    asset: 'assets/images/alert.png',
    icon: Icons.location_on_rounded,
  ),
};

class CategoryGlyph extends StatelessWidget {
  final String type;
  final double size;
  final Color color;
  const CategoryGlyph({
    super.key,
    required this.type,
    this.size = 20,
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(type);
    if (visual.asset != null) {
      return Image.asset(
        visual.asset!,
        width: size,
        height: size,
        color: color,
        errorBuilder: (_, _, _) => Icon(visual.icon, size: size, color: color),
      );
    }
    return Icon(visual.icon, size: size, color: color);
  }
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final surface = dark ? const Color(0xff0f2537) : Colors.white;
  final scaffoldBg = dark ? const Color(0xff071526) : const Color(0xfff1f5f9);
  return ThemeData(
    useMaterial3: true,
    focusColor: Colors.transparent,
    brightness: brightness,
    fontFamily: 'Roboto',
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: green,
          brightness: brightness,
          primary: dark ? green : const Color(0xff16794b),
          secondary: green,
          surface: surface,
        ).copyWith(
          surfaceContainerLowest: scaffoldBg,
          surfaceContainerLow: surface,
          surfaceContainer: dark
              ? const Color(0xff152d40)
              : const Color(0xfff1f5f9),
          surfaceContainerHigh: dark
              ? const Color(0xff1b354a)
              : const Color(0xffe8eef4),
          surfaceContainerHighest: dark
              ? const Color(0xff233f55)
              : const Color(0xffdfe7ef),
          onSurface: dark ? const Color(0xffedf3f8) : navy,
          onSurfaceVariant: dark
              ? const Color(0xffafc1ce)
              : const Color(0xff526477),
          primaryContainer: dark
              ? const Color(0xff183d36)
              : const Color(0xffdcf5e4),
        ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    scaffoldBackgroundColor: scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => dark
            ? (states.contains(WidgetState.focused)
                  ? const Color(0xff203b50)
                  : const Color(0xff193246))
            : (states.contains(WidgetState.focused)
                  ? const Color(0xffe4edf5)
                  : const Color(0xfff1f5f9)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: navy,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? const Color(0xff1e3a52) : const Color(0xffe2e8f0),
        ),
      ),
    ),
  );
}
