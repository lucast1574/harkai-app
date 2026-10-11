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

Ayuda consulta el directorio por ciudad y distrito del backend. El mapa y Lugares de ayuda muestran centros de salud con una cruz blanca en círculo rojo, independientes de las alertas; sus fichas incluyen fuentes, fecha de consulta y contacto institucional cuando está respaldado. Los distritos sin teléfono municipal contrastado muestran las líneas nacionales y el pendiente. El directorio incluye 1.638 lugares de RENIPRESS y fichas contrastadas, en los 43 distritos de Lima, los siete del Callao y los 12 de Trujillo. Lima y Callao se presentan juntos. Se excluyen registros sin coordenadas utilizables. Los desplegables son redondeados y los controles no añaden borde ni brillo de foco.


Los lugares de salud son permanentes y no se eliminan al caducar una alerta. Con permiso de ubicación previamente concedido, el mapa localiza al usuario automáticamente; las consultas de reportes y salud se cargan en paralelo. La cercanía usa GPS real (precisión hasta 150 m), nunca el punto elegido al explorar. A menos de 500 m aparece una tarjeta de ayuda. Con notificaciones activadas puede emitirse un aviso local de importancia normal, como máximo uno por cuenta/dispositivo cada 24 horas; al tocarlo abre la ficha del establecimiento. La observación de posición se suspende al pasar a segundo plano. La recepción real del aviso Android sigue pendiente de prueba en un dispositivo.

`GET /v1/support/coverage` permite comprobar la cobertura sin descargar límites ni consultar alertas. Fuera de Lima, Callao y Trujillo, la app muestra «Tu ciudad aún no tiene cobertura. Estamos trabajando para llevar Harkai a todo el Perú». Los fallos de red tienen un estado diferente; una zona cubierta sin reportes no se presenta como fuera de cobertura.
