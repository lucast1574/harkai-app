# Harkai móvil

App Flutter Android conectada a la API Go común de Harkai. El código se separa en `core` (contratos, sesión y adaptadores), `features` (flujos funcionales) y `shared` (controles visuales). El menú lateral permite explorar zona, reportes, mascotas, lugares, alertas, historial, actualidad, ayuda y cuenta.

## Desarrollo

Flutter 3.44.5 / Dart 3.12.2. Ejecuta `flutter pub get`, `flutter analyze`, `flutter test` y `flutter build apk --debug`. `HARKAI_API_URL` permite cambiar la API con `--dart-define`; por defecto es `https://api.harkai.lat`. Usa una API y datos de pruebas aislados durante desarrollo. `HARKAI_TILE_URL` permite elegir otro proveedor de teselas compatible con OSM.

Android necesita `android/app/google-services.json` del proyecto **harkai-acceso**, paquete `com.lucast.harkai`, para identidad Google y FCM. El archivo contiene identificadores públicos del cliente; ninguna cuenta de servicio pertenece a la app. Los datos y los roles se obtienen de Go. Google se inicializa al usar ese botón, no bloquea el arranque con correo y contraseña.

La sesión de Go se guarda en almacenamiento seguro. Las solicitudes concurrentes comparten la renovación del token. El texto se clasifica con reglas en el backend; la voz se transcribe localmente y regresa como texto editable. El flujo exige revisión manual. Una foto solo se adjunta después de pasar la moderación en el servidor.

No se usa Firestore, Firebase Storage, Gemini, Google Maps, GPay ni Functions de Firebase. Los eventos se retiraron. Los enlaces compartidos usan `https://panel.harkai.lat/incidents/{id}`.

El APK debug es para revisión; la publicación exige configurar `android/key.properties`, la clave de firma definitiva y sus huellas en el proyecto de acceso. FCM requiere completar el circuito de dispositivos y entrega desde Go antes de considerarlo operativo. Actualidad es el flujo de reportes comunitarios hasta conectar una fuente editorial, y falta completar la traducción inglesa.

## Notificaciones Android

Al entrar se comprueban ubicación precisa, «Permitir siempre», GPS y notificaciones. Si falta algo se muestra la explicación y los accesos a Ajustes. Mi cuenta → Permisos del teléfono permite revisar ubicación, cámara, micrófono, avisos y restricciones de batería. Cámara y micrófono se piden al usarlos; no se solicita acceso general al almacenamiento. Go decide los destinatarios y FCM entrega avisos genéricos; al abrirlos se consulta el reporte actual, incluida su conversación. El seguimiento consentido usa un servicio en primer plano de Android con aviso persistente: continúa al minimizar o bloquear la pantalla mientras el proceso siga vivo. El cierre forzado o la terminación por Android lo detiene; se reanuda al abrir la app. El registro se liga a la sesión Go y deja de ser elegible al cerrar sesión.

El token y la zona se restauran solo para la cuenta que los activó, con almacenamiento seguro. Firebase Messaging permanece sin auto-init por defecto; la app lo activa al registrar el dispositivo. La credencial privada de envío va exclusivamente en Dokploy para el backend; google-services.json sigue fuera de Git. El botón depende de push_notifications en /v1/meta. La recepción en un teléfono real queda pendiente de prueba por el propietario.

Ayuda consulta el directorio por ciudad y distrito del backend. El mapa y Lugares de ayuda muestran centros de salud con una cruz blanca en círculo rojo, independientes de las alertas; sus fichas incluyen fuentes, fecha de consulta y contacto institucional cuando está respaldado. Los distritos sin teléfono municipal contrastado muestran las líneas nacionales y el pendiente. El directorio incluye 1.638 lugares de RENIPRESS y fichas contrastadas, en los 43 distritos de Lima, los siete del Callao y los 12 de Trujillo. Lima y Callao se presentan juntos. Se excluyen registros sin coordenadas utilizables. Los desplegables son redondeados y los controles no añaden borde ni brillo de foco.


Los lugares de salud son permanentes y no se eliminan al caducar una alerta. Con permiso de ubicación previamente concedido, el mapa localiza al usuario automáticamente; las consultas de reportes y salud se cargan en paralelo. La cercanía usa GPS real (precisión hasta 150 m), nunca el punto elegido al explorar. A menos de 500 m aparece una tarjeta de ayuda. Con notificaciones activadas puede emitirse un aviso local de importancia normal, como máximo uno por cuenta/dispositivo cada 24 horas; al tocarlo abre la ficha del establecimiento. El observador del mapa se suspende al pasar a segundo plano; el seguimiento consentido de alertas es independiente de las pantallas y no se suspende. La recepción real del aviso Android sigue pendiente de prueba en un dispositivo.

`GET /v1/support/coverage` permite comprobar la cobertura sin descargar límites ni consultar alertas. Fuera de Lima, Callao y Trujillo, la app muestra «Tu ciudad aún no tiene cobertura. Estamos trabajando para llevar Harkai a todo el Perú». Los fallos de red tienen un estado diferente; una zona cubierta sin reportes no se presenta como fuera de cobertura.

## Mapa y recorrido

El panel inferior tiene una posición colapsada y un máximo calculado con la altura real de sus controles, hasta el 65 % de la pantalla; no se puede estirar hasta dejar un gran espacio vacío. Sus categorías son la entrada para reportar; Crimen agrupa robo, extorsión, secuestro, violencia y hechos graves, conservando el subtipo en la API y los filtros. Los reportes se consultan cada 30 segundos mientras el mapa está visible. GPS centra en la posición actual con zoom 16.5; el halo azul solo pulsa con una posición reciente y respeta reducir animaciones.

El seguimiento de alertas envía la última posición precisa (hasta 100 m y antigüedad máxima de dos minutos) a `PATCH /v1/me/devices/{id}/location`, con máximo un intento cada 10 segundos y reintentos automáticos. El GPS mantiene actualizaciones incluso sin desplazamiento; el mapa y las alertas usan un único stream nativo, con prioridad del servicio foreground cuando hay consentimiento. Al cerrar sesión se elimina esa prioridad y el mapa deja de observar al minimizarse. No guarda un historial de recorridos. Las suscripciones previas requieren activar el seguimiento explícitamente. Requiere desplegar la nueva ruta del backend antes de validar el circuito real. Las pruebas de transporte usan HTTP simulado, sin cuentas ni reportes de producción. FCM anuncia nuevos reportes por radio/preferencias; entrar en una zona con un reporte antiguo no vuelve a generar ese envío.

## Reporte rápido

Las categorías del mapa abren una sola hoja inferior con descripción, audio y GPS real. Crimen no solicita subcategorías: el backend las resuelve con sus reglas al recibir `category`. Los otros tipos requieren coincidencia entre texto y categoría. Mascotas conserva evidencia y contacto. Este flujo requiere desplegar el contrato de categorías globales del backend; los clientes anteriores conservan el contrato `type`.

Emergencias consulta el último reporte de la cuenta y obtiene los teléfonos del directorio por su ubicación, priorizando el servicio asociado al tipo. Sin reporte usa la posición disponible; fuera de cobertura muestra líneas nacionales. Harki aparece como acceso a Ayuda. El panel principal ya no incluye el bloque redundante de alertas/salud.

## Inicio de la aplicación

La splash recupera el escudo y los colores originales, dura 1,7 segundos y da paso al mapa sin esperar a la API. Con reducir animaciones usa una transición breve sin movimiento. El mapa se monta desde el primer cuadro debajo de la splash y nunca se sustituye por una pantalla global de carga o error. La metadata y las consultas públicas del mapa no envían la sesión guardada; una sesión vencida se limpia sin bloquear el acceso público. Los errores de conexión aparecen dentro del panel del mapa.

## Arranque y recuperación de sesión

Antes del primer cuadro se restaura la cuenta desde almacenamiento seguro, sin esperar a la red. La validación y metadata se cargan después; un fallo de conexión no borra la sesión. La renovación guarda un ID aleatorio antes de enviar la solicitud: si se pierde la respuesta o se cierra el proceso, se reintenta la misma operación al abrir. El backend debe incluir la renovación recuperable; durante una actualización se admite el contrato anterior.

El mapa puede usar una última posición del dispositivo de hasta 10 minutos y precisión de 250 m para encuadrar la zona y consultar reportes públicos. Es provisional: no habilita avisos de cercanía ni sustituye el GPS fresco exigido al reportar. Las actualizaciones de GPS se suscriben antes de esperar la lectura puntual, evitando que un timeout detenga la localización.

## Fotos y prueba de permisos

Los reportes usan exclusivamente `ImageSource.camera`, con permiso CAMERA solicitado antes de abrir la captura nativa. Cancelar no sube ningún archivo. Los puntos de pago permiten elegir cámara o galería; ambos pasan por la moderación de medios existente.

En el emulador, el micrófono del PC se habilita manualmente en Controles extendidos → Microphone → Enable Host Microphone Access (o Virtual microphone uses host audio input). La app también debe tener RECORD_AUDIO concedido.

La verificación de Android incluye: conceder primero ubicación durante el uso y luego «Permitir siempre», volver a Harkai y comprobar el servicio `GeolocatorLocationService` con `isForeground=true` y tipo location. Repetir con la app minimizada; probar recuperación al volver del GPS apagado y la salida al cerrar sesión. Forzar cierre, revocar permisos, falta de conexión y restricciones del fabricante impiden prometer entrega continua garantizada. No se genera una alerta de producción para estas pruebas.
