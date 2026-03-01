# BUILD STAGE: Entorno Alpine ultra-ligero para compilar Flutter Web
FROM alpine:latest AS build
WORKDIR /app

# Instalar dependencias requeridas (incluido gcompat para Dart)
RUN apk add --no-cache bash curl git unzip gcompat

# Clonar SDK de Flutter (Rama estable, poca profundidad para evitar peso)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"

# Forzar descarga inicial y validar instalación mínima
RUN flutter doctor -v

# Compilar Web
COPY . .
RUN flutter config --enable-web
RUN flutter pub get
RUN flutter build web --release

# PRODUCTION STAGE: Servidor estático
FROM nginx:alpine
# Copiamos solo los estáticos renderizados
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
