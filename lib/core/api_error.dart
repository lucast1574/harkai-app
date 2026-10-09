class ApiException implements Exception {
  final int status;
  final String code;
  const ApiException(this.status, this.code);
  @override
  String toString() => code == 'image_rejected'
      ? 'La foto no pasó la revisión de contenido. Elige otra imagen.'
      : switch (status) {
          400 => 'Revisa los campos y vuelve a intentarlo.',
          401 => 'Inicia sesión para continuar.',
          403 => 'Tu cuenta no tiene permiso para esta acción.',
          404 => 'El contenido no está disponible.',
          409 => 'La acción ya se realizó o el estado cambió.',
          429 => 'Llegaste al límite de intentos. Inténtalo más tarde.',
          _ =>
            'El servicio no está disponible. Revisa tu conexión e inténtalo otra vez.',
        };
}
