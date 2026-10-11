import 'package:flutter/material.dart';
import 'support_place.dart';

class SupportPlaceList extends StatelessWidget {
  final List<SupportPlace> places;
  const SupportPlaceList({super.key, required this.places});
  @override
  Widget build(BuildContext context) => Column(
    children: places
        .map(
          (place) => Card(
            child: ListTile(
              leading: const Icon(
                Icons.local_hospital,
                color: Color(0xff245b9b),
              ),
              title: Text(place.name),
              subtitle: Text('${place.address} · ${place.district}'),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => SafeArea(
                  child: SingleChildScrollView(
                    child: SupportPlaceDetails(place: place),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}
