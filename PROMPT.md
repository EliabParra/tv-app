# 📱 Arquitectura y Plan de Implementación - Flutter TV Remote Corporativo

**Contexto y Rol del Agente:** Actúa como un Tech Lead y Desarrollador Senior de Flutter experto en Clean Architecture. Vas a guiar la construcción de una aplicación que funcionará como cliente para un microservicio REST local que controla televisores Fire TV mediante ADB. La aplicación se distribuirá principalmente como un **APK nativo de Android** para entornos corporativos distribuidos, y secundariamente como una **Web App contenedorizada**.

**Reglas Arquitectónicas Inquebrantables:**
1. **Cero lógica de red en la UI:** Los widgets no saben qué es un endpoint.
2. **Gestión de estado estricta:** Uso exclusivo de `flutter_riverpod`. Prohibido usar `setState` para flujos asíncronos.
3. **Cliente HTTP seguro:** Uso exclusivo de `dio`. Prohibido usar el paquete `http` básico.
4. **Tráfico Local:** La app se comunicará con IPs privadas en red local (HTTP sin SSL).
5. **Escalabilidad Multi-Dispositivo:** La IP del televisor no debe estar quemada (hardcodeada); la UI debe permitir cambiarla para controlar diferentes equipos en distintas sucursales.

Ejecuta las siguientes fases en orden secuencial. Detente al final de cada fase y espera mi confirmación antes de continuar.

---

## Fase 1: Scaffold, Entorno y Permisos de Red Nativa

Prepara el terreno para una aplicación que se comunicará sin SSL en redes locales.

1. Genera el comando `flutter pub add` para: `dio`, `flutter_riverpod`, `flutter_dotenv`.
2. Crea el archivo `.env` de ejemplo. Solo contendrá `API_KEY=tu_clave_secreta`. (La IP del TV la manejaremos dinámicamente en el estado).
3. Modifica `pubspec.yaml` para incluir el archivo `.env`.
4. **Paso Crítico de Infraestructura (Android):** Muestra exactamente cómo y dónde modificar el archivo `android/app/src/main/AndroidManifest.xml` para añadir `android:usesCleartextTraffic="true"` en la etiqueta `<application>`. Si omites esto, el sistema operativo bloqueará las peticiones HTTP del APK.
5. Genera el `main.dart` envolviendo la app en un `ProviderScope` y cargando el `dotenv` en el `main()`.

---

## Fase 2: Infraestructura - El Cliente HTTP Interceptado

Crea la capa de red resistente y dinámica en `lib/core/network/api_client.dart`.

1. Crea la clase `ApiClient` que instancie `Dio`.
2. **Interceptor de Seguridad:** Añade un `InterceptorsWrapper`. En el método `onRequest`, inyecta obligatoriamente el header `x-api-key` leyendo `dotenv.env['API_KEY']`.
3. **Manejo de Errores Global:** En el `onError`, intercepta códigos 401 (lanza `UnauthorizedException`), y 500 o timeouts (lanza `ServerException`).
4. **Base URL Dinámica:** La clase debe tener un método `updateBaseUrl(String ip)` que cambie dinámicamente el `options.baseUrl` de Dio a `http://$ip:8000/tv`. Esto es vital para cambiar de televisor en tiempo real.
5. Exporta un `apiClientProvider` de Riverpod para inyectar esta instancia.

---

## Fase 3: Capa de Dominio - El Repositorio

Abstrae la comunicación REST en `lib/features/tv_control/repositories/tv_repository.dart`.

1. Crea la clase `TvRepository` que reciba `ApiClient` vía inyección de dependencias.
2. Implementa estos métodos asíncronos devolviendo un `Future<bool>` que capture excepciones silenciosamente:
   - `checkHealth()` -> GET a `/health`
   - `connectDevice()` -> POST a `/connect`
   - `sendKeyEvent(int code)` -> POST a `/keyevent/$code`
   - `openApp(String packageName)` -> POST a `/app/$packageName`
   - `sendText(String text)` -> POST a `/text` con body `{"text": text}`
   - `mediaControl(String control)` -> POST a `/media/$control`
3. Exporta el `tvRepositoryProvider`.

---

## Fase 4: Gestión de Estado (El Cerebro)

Controla la lógica de negocio y la IP activa en `lib/features/tv_control/providers/tv_controller.dart`.

1. Crea un `Notifier` de Riverpod llamado `TvController`.
2. El estado debe ser una clase (ej. `TvState`) que contenga: `String currentIp` y un `enum ConnectionStatus { idle, loading, connected, error }`.
3. Crea un método `setTargetIp(String ip)` que llame a `apiClient.updateBaseUrl(ip)`, actualice el estado y luego dispare un `checkHealth()` a través del repositorio para verificar si ese televisor responde.
4. Crea métodos públicos (`pressButton`, `launchApp`, `inputText`) que invoquen al repositorio respectivo solo si el estado actual es `connected`.

---

## Fase 5: Capa de Presentación - UI Modular

Construye la interfaz de usuario dividida en dos vistas principales.

1. **Pantalla de Configuración / Selección (`DeviceSelectionScreen`):**
   - Un `TextField` para ingresar la IP del TV objetivo (ej. "192.168.X.X").
   - Un botón "Conectar" que invoque `setTargetIp` en el controlador de Riverpod.
   - Si la conexión es exitosa, navega a la pantalla de control. Si falla, muestra un SnackBar de error.

2. **Pantalla de Control Remoto (`RemoteScreen`):**
   - **Barra superior:** Un `TextField` para la inyección directa de texto (`/text`). Al presionar Enter, envía el string.
   - **Centro (D-Pad Ergonomico):** Diseña un control direccional en cruz. Arriba=19, Abajo=20, Izquierda=21, Derecha=22, OK/Centro=23.
   - **Controles Base:** Fila debajo del D-Pad con "Back (4)", "Home (3)", y "Play/Pause (85)".
   - **Deep Links (Inferior):** Una cuadrícula (Grid) con tarjetas para lanzar apps directas: Netflix (`com.netflix.ninja`), YouTube (`com.amazon.firetv.youtube`), Prime Video (`com.amazon.avod`).
   - *Nota de UX:* Añade `HapticFeedback.lightImpact()` a todos los botones para simular un control físico.

---

## Fase 6: Infraestructura de Despliegue (El Fallback Web)

El artefacto principal será el APK, pero empaquetaremos la versión web usando un Build Multietapa de Docker para uso administrativo de emergencia en la red.

Crea los archivos de infraestructura en la raíz del proyecto:
1. **Dockerfile:**
   - **Etapa 1 (Build):** Usa `ghcr.io/cirruslabs/flutter:stable`. Ejecuta `flutter pub get` y `flutter build web --release`.
   - **Etapa 2 (Producción):** Usa `nginx:alpine`. Copia `/app/build/web` al directorio `/usr/share/nginx/html`. Expón el puerto 80.
2. **docker-compose.yml:**
   - Define el servicio `tv-frontend`.
   - Mapea el puerto host (ej. `3000:80`).
   - *Instrucción estricta:* No vincules este contenedor a ninguna red especial con el backend. La aplicación de Flutter servida por Nginx se ejecuta en el navegador del usuario final, el cual debe tener visibilidad directa hacia la IP del Fire TV y del backend en la red local.