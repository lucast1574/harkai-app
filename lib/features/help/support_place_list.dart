import 'package:flutter/material.dart';
import 'support_place.dart';

class SupportPlaceList extends StatelessWidget {
  final List<SupportPlace> places;
  final ValueChanged<SupportPlace>? onSelect;
  const SupportPlaceList({super.key, required this.places, this.onSelect});
  @override
  Widget build(BuildContext context) => Column(
    children: places
        .map(
          (place) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xffd94750),
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: Text(place.name),
              subtitle: Text('${place.address} · ${place.district}'),
              onTap: onSelect != null
                  ? () => onSelect!(place)
                  : () => showModalBottomSheet(
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
