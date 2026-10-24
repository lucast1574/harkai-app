import 'package:flutter/material.dart';

/// Sections shared by the bottom navigation and compact destination sheet.
abstract final class AppDestinations {
  static const entries = [
    (Icons.map_outlined, 'Mi zona'),
    (Icons.view_agenda_outlined, 'Comunidad'),
    (Icons.pets_outlined, 'Mascotas'),
    (Icons.location_on_outlined, 'Lugares de ayuda'),
    (Icons.storefront_outlined, 'Ponte en el mapa'),
    (Icons.support_agent_rounded, 'Harki y ayuda'),
    (Icons.person_outline, 'Mi cuenta'),
  ];
}
