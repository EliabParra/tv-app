# Flutter TV Remote Corporativo 📱

Esta es la aplicación cliente oficial diseñada bajo los principios de **Clean Architecture** para interactuar con el microservicio controlador de Televisiones Fire TV / ADB.

La aplicación opera conectándose localmente a la red de tu oficina/empresa, sin restricciones de SSL (usa tráfico cifrado libre interno) y te permite cambiar ágilmente entre diferentes televisores con distintas IPs.

---

## 🚀 Instalación Rápida (Recomendado)

### Opción 1: Dispositivos Android (APK Nativo)

Si deseas controlar el TV desde tu teléfono Android sin depender de un navegador:

1. Asegúrate de tener Flutter instalado.
2. Si no tienes Flutter, puedes generar el APK usando el servicio contenedorizado:
   ```bash
   docker run --rm -v $(pwd):/app -w /app instrumentisto/flutter:latest sh -c "flutter build apk --release"
   ```
3. Alternativamente, si cuentas con el SDK local, ejecuta:
   ```bash
   flutter build apk --release
   ```
4. El archivo generado estará en: `build/app/outputs/flutter-apk/app-release.apk`.
5. Transfiere este archivo a tu dispositivo Android, instala, ignora la advertencia de orígenes desconocidos y ábrela.

### Opción 2: Versión Web (Desde cualquier PC de la Oficina)

Ideal para conserjerías o recepcionistas que necesitan operar el TV desde una computadora de escritorio con Docker instalado:

1. Levanta el contenedor web pre-configurado usando Docker Compose:
   ```bash
   docker-compose up -d --build
   ```
2. La terminal compilará efímeramente la app con la imagen base Alpine (tomará un par de minutos).
3. Una vez iniciado, abre cualquier navegador y dirígete a: [http://localhost:3000](http://localhost:3000).

---

## ⚙️ Configuración Previa

El nivel de autenticación al microservicio del backend se decide en la compilación. Para configurarlo por seguridad debes incluir tu API Key:

1. En la raíz del proyecto, busca un archivo llamado `.env` (crealo si no existe).
2. Agrega la clave secreta de tu microservicio del Fire TV en este formato:
   ```env
   API_KEY=tu_clave_secreta_aqui
   ```
   _Nota: Las variables de entorno en Flutter deben estar definidas pre-compilación, si reconstruyes para Android o Web, asegúrate de actualizar el archivo primero._

---

## 📺 Guía de Uso

1. **Pantalla de Conexión:**
   Una vez que inicies la aplicación, verás el `DeviceSelectionScreen`.
   - Ingresa la dirección IP asignada localmente al dispositivo Raspberry/Servidor en donde corre tu _Microservicio controlador ADB del FireTV_. (Ejemplo: `192.168.1.55`).
   - Clic en **Conectar**.

2. **Validación:**
   - La App se comunicará con el backend consultando `/health`.
   - Si la prueba pasa, intentará forzar una conexión `/connect` con el televisor pareado mediante ADB por debajo y te llevará al control remoto.

3. **La Interfaz de Control:**
   - Usa el **D-Pad de la pantalla** para navegar (Arriba, Abajo, Izquierda, Derecha, OK).
   - Abajo encuentras los lanzadores rápidos (**Deep Links**) que ordenan al ADB abrir Netflix, YouTube o Prime.
   - En la parte superior, hay una caja de texto: escribe y pulsa OK para mandar el texto directamente al buscador/ingreso de la TV sin tener que usar el molesto teclado en pantalla.
   - Si necesitas controlar otro televisor en otra oficina de la red, pulsa el ícono de "Salida" (arriba a la derecha) para volver y digitalizar la nueva IP destino.
