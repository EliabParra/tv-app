# 📱 Plan de Implementación de Arquitectura - Flutter TV Remote

**Instrucción inicial para el Agente:** Actúa como un Tech Lead y Desarrollador Senior de Flutter experto en Clean Architecture y principios SOLID. Vas a guiar la construcción de una aplicación móvil/web que funcionará como cliente para un microservicio REST local. 
Reglas absolutas para todo el código generado:
1. **Cero lógica de red en la UI.**
2. **Uso estricto de Riverpod para gestión de estado.**
3. **Uso estricto de `dio` para el cliente HTTP (prohibido usar `http`).**
4. **Ninguna IP o API Key debe estar "hardcodeada" en el código fuente.**

A continuación, ejecuta las siguientes fases en orden. No avances a la siguiente fase sin mi autorización explícita.

---

## Fase 1: Configuración Base y Variables de Entorno

Ejecuta lo siguiente:
1. Proporciona el comando `flutter pub add` para instalar: `dio`, `flutter_riverpod`, `flutter_dotenv`.
2. Genera el código para un archivo `.env` de ejemplo que contenga `API_URL=http://<IP_DEL_HOST>:8000/tv` y `API_KEY=tu_clave_secreta`.
3. Muestra cómo modificar `pubspec.yaml` para incluir el archivo `.env` en los assets.
4. Escribe el archivo `main.dart` asegurando que la inicialización de `dotenv.load()` ocurra antes de `runApp`, envolviendo la aplicación en un `ProviderScope` de Riverpod.

---

## Fase 2: Infraestructura - El Cliente HTTP Seguro

Vamos a crear la capa de red resistente a fallos.
Crea el archivo `lib/core/network/api_client.dart`.

Especificaciones:
1. Crea una clase `ApiClient` que instancie un objeto `Dio`.
2. Configura el `BaseOptions` de Dio leyendo la `API_URL` desde `dotenv.env`.
3. **Crítico:** Añade un `InterceptorsWrapper` a Dio. En el método `onRequest`, inyecta obligatoriamente el header `x-api-key` leyendo el valor de `dotenv.env['API_KEY']`.
4. Añade un manejo global de errores en el método `onError` del interceptor. Si el status code es 401, lanza una excepción personalizada `UnauthorizedException`. Si es 500 o timeout, lanza `ServerException`.
5. Proporciona el provider de Riverpod (`apiClientProvider`) para inyectar esta clase en el resto de la app.

---

## Fase 3: Capa de Dominio - El Repositorio del TV

No queremos que el resto de la app sepa que existen endpoints REST.
Crea el archivo `lib/features/tv_control/repositories/tv_repository.dart`.

Especificaciones:
1. Crea la clase `TvRepository` que reciba el `ApiClient` en su constructor.
2. Implementa los siguientes métodos asíncronos (todos deben retornar un `Future<bool>` indicando éxito o fracaso, capturando las excepciones de Dio):
   - `checkHealth()` -> Hace un GET a `/health` (ajustando el path relativo si es necesario).
   - `connectDevice()` -> Hace un POST a `/connect`.
   - `sendKeyEvent(int code)` -> Hace un POST a `/keyevent/$code`.
   - `openApp(String packageName)` -> Hace un POST a `/app/$packageName`.
   - `sendText(String text)` -> Hace un POST a `/text` enviando un JSON `{"text": text}`.
   - `mediaControl(String control)` -> Hace un POST a `/media/$control` (ej. playpause, volup).
3. Crea el provider `tvRepositoryProvider` usando Riverpod para exponer esta instancia.

---

## Fase 4: Gestión de Estado Estratégica

La interfaz no debe hacer peticiones directamente, debe llamar a un controlador de estado.
Crea el archivo `lib/features/tv_control/providers/tv_controller.dart`.

Especificaciones:
1. Crea un `Notifier` (o `AsyncNotifier`) de Riverpod llamado `TvController`.
2. El estado (`state`) debe representar el estado de la conexión con el microservicio: `enum ConnectionState { connected, disconnected, error, loading }`.
3. En el método `build`, ejecuta un `checkHealth()` usando el `TvRepository` para establecer el estado inicial.
4. Crea métodos públicos en este controlador que envuelvan las llamadas al repositorio (ej. `pressButton(int code)`, `launchNetflix()`). 
5. Estos métodos no deben cambiar el estado global a "loading" por cada pulsación rápida (para no bloquear la UI), pero sí deben manejar errores silenciosamente o emitir alertas si la conexión se pierde permanentemente.

---

## Fase 5: Capa de Presentación - La Interfaz (UI)

Construye la interfaz de usuario enfocada en la ergonomía.
Crea el archivo `lib/features/tv_control/presentation/remote_screen.dart`.

Especificaciones:
1. La pantalla debe ser un `ConsumerWidget` para escuchar el estado del `tvControllerProvider`.
2. Si el estado es `error` o `disconnected`, muestra un banner superior rojo o un indicador visual claro, pero **no** destruyas la interfaz entera. Permite un botón de "Reconectar".
3. **Layout Principal (Top to Bottom):**
   - **Barra superior:** Un `TextField` para la inyección de texto (`/text`). Al presionar 'Submit' en el teclado virtual, envía el string.
   - **Centro (D-Pad):** Diseña un control direccional (Arriba=19, Abajo=20, Izquierda=21, Derecha=22, Centro/OK=23). Utiliza un layout en cruz (Cross) con íconos identificativos.
   - **Controles base:** Una fila debajo del D-Pad con los botones "Back (4)", "Home (3)" y "Play/Pause (85)".
   - **Sección inferior (Deep Links):** Un `GridView` o `Wrap` con botones grandes (estilo tarjeta) para accesos directos de aplicaciones. Incluye Netflix (`com.netflix.ninja`), YouTube (`com.amazon.firetv.youtube`) y Prime Video (`com.amazon.avod`).
4. Cada botón debe estar conectado al método correspondiente del controlador de Riverpod, no directamente al repositorio. Asegúrate de proporcionar retroalimentación táctil (HapticFeedback) en cada pulsación.