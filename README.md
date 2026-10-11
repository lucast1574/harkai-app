# Harkai móvil

App Flutter Android conectada a la API Go común de Harkai. El código se separa en `core` (contratos, sesión y adaptadores), `features` (flujos funcionales) y `shared` (controles visuales). El menú lateral permite explorar zona, reportes, mascotas, lugares, alertas, historial, actualidad, ayuda y cuenta.

## Desarrollo

Flutter 3.44.5 / Dart 3.12.2. Ejecuta `flutter pub get`, `flutter analyze`, `flutter test` y `flutter build apk --debug`. `HARKAI_API_URL` permite cambiar la API con `--dart-define`; por defecto es `https://api.harkai.lat`. Usa una API y datos de pruebas aislados durante desarrollo. `HARKAI_TILE_URL` permite elegir otro proveedor de teselas compatible con OSM.

Android necesita `android/app/google-services.json` del proyecto **harkai-acceso**, paquete `com.lucast.harkai`, para identidad Google y FCM. El archivo contiene identificadores públicos del cliente; ninguna cuenta de servicio pertenece a la app. Los datos y los roles se obtienen de Go. Google se inicializa al usar ese botón, no bloquea el arranque con correo y contraseña.

La sesión de Go se guarda en almacenamiento seguro. Las solicitudes concurrentes comparten la renovación del token. El texto se clasifica con reglas en el backend; la voz se transcribe localmente y regresa como texto editable. El flujo exige revisión manual. Una foto solo se adjunta después de pasar la moderación en el servidor.

No se usa Firestore, Firebase Storage, Gemini, Google Maps, GPay ni Functions de Firebase. Los eventos se retiraron. Los enlaces compartidos usan `https://panel.harkai.lat/incidents/{id}`.

El APK debug es para revisión; la publicación exige configurar `android/key.properties`, la clave de firma definitiva y sus huellas en el proyecto de acceso. FCM requiere completar el circuito de dispositivos y entrega desde Go antes de considerarlo operativo. Actualidad es el flujo de reportes comunitarios hasta conectar una fuente editorial, y falta completar la traducción inglesa.

## Notificaciones Android

Mi cuenta permite registrar una zona con GPS en primer plano y consentimiento de notificaciones. Go decide los destinatarios y FCM entrega avisos genéricos; al abrirlos se consulta el reporte actual, incluida su conversación. No hay seguimiento de ubicación en segundo plano. El registro se liga a la sesión Go y deja de ser elegible al cerrar sesión.

El token y la zona se restauran solo para la cuenta que los activó, con almacenamiento seguro. Firebase Messaging permanece sin auto-init por defecto; la app lo activa al registrar el dispositivo. La credencial privada de envío va exclusivamente en Dokploy para el backend; google-services.json sigue fuera de Git. El botón depende de push_notifications en /v1/meta. La recepción en un teléfono real queda pendiente de prueba por el propietario.

Ayuda consulta el directorio por ciudad y distrito del backend. El mapa y Lugares de ayuda muestran centros de salud con marcadores azules, independientes de las alertas; sus fichas incluyen fuentes, fecha de consulta y contacto institucional cuando está respaldado. Los distritos sin teléfono municipal contrastado muestran las líneas nacionales y el pendiente. El inventario inicial de establecimientos es parcial. Los desplegables son redondeados y los controles no añaden borde ni brillo de foco.
