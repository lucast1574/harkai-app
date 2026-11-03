import 'package:flutter/material.dart';
import '../../shared/app_choice_field.dart';

class ChatDistrictPicker extends StatefulWidget {
  final List<Map<String, dynamic>> catalog;
  final String? currentId;
  const ChatDistrictPicker({super.key, required this.catalog, this.currentId});
  @override
  State<ChatDistrictPicker> createState() => _ChatDistrictPickerState();
}

class _ChatDistrictPickerState extends State<ChatDistrictPicker> {
  late String department = widget.currentId?.substring(0, 2) ?? '';
  late String province = widget.currentId?.substring(0, 4) ?? '';
  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.catalog]
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige el distrito del chat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes conversar en cualquier distrito, estés donde estés.',
            ),
            const SizedBox(height: 24),
            AppChoiceField(
              label: 'Departamento',
              value: department,
              options: {
                '': 'Elige un departamento',
                for (final d in sorted)
                  (d['id'] as String).substring(0, 2):
                      d['department'] as String,
              },
              onChanged: (v) => setState(() {
                department = v;
                province = '';
              }),
            ),
            const SizedBox(height: 16),
            AppChoiceField(
              label: 'Provincia',
              value: province,
              options: {
                '': 'Elige una provincia',
                for (final d in sorted.where(
                  (d) =>
                      (d['id'] as String).startsWith(department) &&
                      department.isNotEmpty,
                ))
                  (d['id'] as String).substring(0, 4): d['province'] as String,
              },
              onChanged: department.isEmpty
                  ? null
                  : (v) => setState(() => province = v),
            ),
            const SizedBox(height: 16),
            AppChoiceField(
              label: 'Distrito',
              value: widget.currentId ?? '',
              options: {
                '': 'Elige un distrito',
                for (final d in sorted.where(
                  (d) =>
                      (d['id'] as String).startsWith(province) &&
                      province.isNotEmpty,
                ))
                  d['id'] as String: d['name'] as String,
              },
              onChanged: province.isEmpty
                  ? null
                  : (v) {
                      if (v.isNotEmpty) {
                        Navigator.pop(
                          context,
                          widget.catalog.firstWhere((d) => d['id'] == v),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
