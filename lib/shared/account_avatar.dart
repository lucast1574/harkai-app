import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme.dart';

class AccountAvatar extends StatelessWidget {
  final Account? account;
  final double radius;
  const AccountAvatar({super.key, this.account, this.radius = 21});
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: account == null ? const Color(0xffe2e8f0) : green,
      child: Center(
        child: account == null
            ? Icon(Icons.person_outline_rounded, color: navy, size: radius)
            : Text(
                account!.name.trim().isEmpty
                    ? 'U'
                    : account!.name.trim()[0].toUpperCase(),
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * .8,
                ),
              ),
      ),
    );
    final url = account?.photoUrl;
    return Semantics(
      label: account == null ? 'Mi cuenta' : 'Foto de ${account!.name}',
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: url == null || url.isEmpty
              ? fallback
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : fallback,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
