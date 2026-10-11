import 'package:flutter/material.dart';

class ReportDraft {
  final description = TextEditingController(),
      latitude = TextEditingController(),
      longitude = TextEditingController(),
      district = TextEditingController(),
      city = TextEditingController(),
      contact = TextEditingController();
  String? type, mediaId, photoName;
  bool shareContact = false, reviewed = false;
  bool get needsPhoto => type == 'pet' || type == 'place';
  Map<String, dynamic> toJson() => {
    'type': type,
    'description': description.text.trim(),
    'latitude': double.parse(latitude.text),
    'longitude': double.parse(longitude.text),
    'district': district.text.trim(),
    'city': city.text.trim(),
    'country': 'PE',
    if (mediaId != null) 'media_id': mediaId,
    'contact_info': contact.text.trim(),
    'share_contact': shareContact,
  };
  bool dispose() {
    for (final c in [
      description,
      latitude,
      longitude,
      district,
      city,
      contact,
    ]) {
      c.dispose();
    }
    return true;
  }
}

String? coordinateValidator(String? value, double min, double max) {
  final number = double.tryParse(value ?? '');
  return number == null || !number.isFinite || number < min || number > max
      ? 'Ingresa una coordenada válida.'
      : null;
}
