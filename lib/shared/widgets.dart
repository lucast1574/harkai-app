import 'package:flutter/material.dart';

class PageHeading extends StatelessWidget {
  final String title, description;
  const PageHeading(this.title, this.description, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HARKAI · COMUNIDAD',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class AppField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final bool obscure, readOnly;
  final int lines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboard,
    this.validator,
    this.obscure = false,
    this.readOnly = false,
    this.lines = 1,
    this.maxLength,
    this.autofillHints,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
      ),
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      maxLines: lines,
      maxLength: maxLength,
      readOnly: readOnly,
      autofillHints: autofillHints,
    ),
  );
}

class MessageCard extends StatelessWidget {
  final String message;
  final bool error;
  final VoidCallback? onRetry;
  const MessageCard(
    this.message, {
    super.key,
    this.error = false,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Card(
    color: error
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class VerificationBadge extends StatelessWidget {
  final bool verified;
  const VerificationBadge(this.verified, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: verified ? const Color(0xffdff4e4) : const Color(0xffffefd3),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      verified ? 'Confirmado por la comunidad' : 'No verificado',
      style: TextStyle(
        fontSize: 11,
        color: verified ? const Color(0xff287440) : const Color(0xff815a23),
      ),
    ),
  );
}
