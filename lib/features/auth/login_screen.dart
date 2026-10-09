import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../shared/widgets.dart';
import 'google_login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool register = false, busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<bool> submit({bool google = false}) async {
    if (!google && !form.currentState!.validate()) return false;
    setState(() {
      busy = true;
      error = null;
    });
    final app = AppScope.of(context);
    try {
      if (google) {
        await app.exchangeGoogle(await googleIdentityToken());
      } else {
        await app.login(
          email: email.text.trim(),
          password: password.text,
          name: register ? name.text.trim() : null,
        );
      }
      if (mounted) Navigator.pop(context, true);
      return true;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Volver',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          PageHeading(
            register ? 'Tu comunidad empieza contigo' : 'Bienvenido a tu zona',
            'Una cuenta para la web y la app móvil.',
          ),
          Form(
            key: form,
            child: AutofillGroup(
              child: Column(
                children: [
                  if (register)
                    AppField(
                      label: 'Tu nombre',
                      controller: name,
                      autofillHints: const [AutofillHints.name],
                      maxLength: 80,
                      validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'Escribe al menos dos caracteres.'
                          : null,
                    ),
                  AppField(
                    label: 'Correo electrónico',
                    controller: email,
                    keyboard: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) =>
                        v == null ||
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v.trim())
                        ? 'Revisa tu correo.'
                        : null,
                  ),
                  AppField(
                    label: 'Contraseña',
                    controller: password,
                    obscure: true,
                    autofillHints: [
                      register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    validator: (v) =>
                        v == null ||
                            v.isEmpty ||
                            (register &&
                                (utf8.encode(v).length < 12 ||
                                    utf8.encode(v).length > 72))
                        ? 'Usa una contraseña de 12 a 72 bytes.'
                        : null,
                  ),
                  if (error != null) MessageCard(error!, error: true),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(
                        busy
                            ? 'Un momento…'
                            : register
                            ? 'Crear cuenta'
                            : 'Ingresar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (AppScope.of(context).capabilities['google_auth'] == true)
            OutlinedButton(
              onPressed: busy ? null : () => submit(google: true),
              child: const Text('Continuar con Google'),
            ),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    register = !register;
                    error = null;
                  }),
            child: Text(
              register ? 'Ya tengo una cuenta' : 'Crear cuenta con mi correo',
            ),
          ),
        ],
      ),
    ),
  );
}
