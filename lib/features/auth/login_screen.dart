import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/theme.dart';
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
    if (busy) return false;
    if (!google && !form.currentState!.validate()) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    final app = AppScope.of(context);
    try {
      if (google) {
        String? photo;
        final token = await googleIdentityToken(
          onPhoto: (value) => photo = value,
        );
        await app.exchangeGoogle(token, photoUrl: photo);
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
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: green),
        ),
      ),
      body: busy
          ? const SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        color: green,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Entrando a tu comunidad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Estamos preparando tu cuenta',
                      style: TextStyle(color: Color(0xffb5c7d6)),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 48,
                        height: 48,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/icon/icon.png',
                          width: 44,
                          height: 44,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'harkai',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    register
                        ? 'Tu comunidad empieza contigo'
                        : 'Bienvenido a tu zona',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Usa la misma cuenta en la app móvil y en panel.harkai.lat.',
                    style: TextStyle(color: Color(0xffb5c7d6), fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
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
                                      validator: (v) =>
                                          (v?.trim().length ?? 0) < 2
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
                                  if (error != null)
                                    MessageCard(error!, error: true),
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
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(() {
                                    register = !register;
                                    error = null;
                                  }),
                            child: Text(
                              register
                                  ? 'Ya tengo una cuenta · Ingresar'
                                  : '¿No tienes cuenta? Crear cuenta con correo',
                            ),
                          ),
                          if (AppScope.of(
                                context,
                              ).capabilities['google_auth'] ==
                              true) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'o continúa con',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff64748b),
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => submit(google: true),
                                icon: Image.asset(
                                  'assets/images/google_logo.png',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.login, size: 18),
                                ),
                                label: const Text('Continuar con Google'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}
