# Bubble Pop

¡Bienvenido a **Bubble Pop**!  
Un juego relajante donde explotas burbujas para sumar puntos. Ideal para pasar el rato y competir contra tus amigos.  

---

## Tabla de Contenidos

- [Características](#características)
- [Instalación](#instalación)
- [Ejecución](#ejecución)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Configuración de Iconos](#configuración-de-iconos)
- [Configuración de Anuncios (AdMob)](#configuración-de-anuncios-admob)
- [Compilación y Publicación](#compilación-y-publicación)
- [Contribución](#contribución)
- [Licencia](#licencia)

---

## Características

- Juego casual de explotar burbujas con animaciones suaves.
- Efectos de sonido y música de fondo (usando `audioplayers`).
- Guardado de puntuación máxima (`shared_preferences`).
- Icono personalizado y diseño amigable.
- Listo para integración de anuncios con AdMob.
- Compatible con Android e iOS.

---

## Instalación

1. **Clona el repositorio:**
   ```sh
   git clone https://github.com/waltherEfrain2000/bubble_pop.git
   cd bubble_pop
   ```

2. **Instala dependencias:**
   ```sh
   flutter pub get
   ```

3. **Agrega los assets**  
   Asegúrate de tener la siguiente estructura de archivos:

   ```
   assets/
     images/
       bubble1.png
       bubble2.png
       bubble3.png
     sounds/
       pop.mp3
       music.mp3
       bubble_spawn.mp3
     icon/
       icon.png
   ```

---

## Ejecución

1. **Conecta tu dispositivo o emulador.**
2. **Ejecuta el juego:**
   ```sh
   flutter run
   ```

---

## Estructura del Proyecto

```
bubble_pop/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   └── ... (otros archivos Dart)
├── assets/
│   ├── images/
│   ├── sounds/
│   └── icon/
├── pubspec.yaml
└── README.md
```

- **lib/main.dart**: Punto de entrada de la app y lógica principal del juego.
- **assets/**: Imágenes, sonidos y recursos del juego.
- **pubspec.yaml**: Configuración de dependencias y assets.

---

## Configuración de Iconos

El ícono de la app debe estar en `assets/icon/icon.png` con **dimensiones 512x512 px**, fondo preferentemente transparente, formato PNG.

Para generar los iconos de launcher:

```sh
flutter pub run flutter_launcher_icons:main
```

Esto creará los iconos para Android e iOS automáticamente.

---

## Configuración de Anuncios (AdMob)

1. **Crea una cuenta en [Google AdMob](https://admob.google.com/).**
2. **Registra tu app y obtén el App ID y los Block IDs** (banner, intersticial, rewarded, etc.).
3. **Agrega el plugin en `pubspec.yaml`:**
   ```yaml
   google_mobile_ads: ^5.0.0
   ```
4. **Implementa los anuncios en tu código:**
   - Importa el paquete:  
     ```dart
     import 'package:google_mobile_ads/google_mobile_ads.dart';
     ```
   - Inicializa y muestra los anuncios usando los IDs obtenidos de AdMob.
   - Usa IDs de prueba durante el desarrollo.

5. **Configura el App ID en los archivos nativos:**

   - **Android:**  
     Edita `android/app/src/main/AndroidManifest.xml` y agrega dentro de `<application>`:
     ```xml
     <meta-data
         android:name="com.google.android.gms.ads.APPLICATION_ID"
         android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
     ```
   - **iOS:**  
     Edita `ios/Runner/Info.plist` y agrega:
     ```xml
     <key>GADApplicationIdentifier</key>
     <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
     ```

---

## Compilación y Publicación

### **Cambiar el nombre de la app**

- **Android:**  
  Edita `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <application
      android:label="Bubble Pop"
      ...>
  ```

- **iOS:**  
  Edita `ios/Runner/Info.plist`:
  ```xml
  <key>CFBundleDisplayName</key>
  <string>Bubble Pop</string>
  ```

### **Subir a Google Play**

1. Genera el APK o AAB:
   ```sh
   flutter build apk --release
   # o
   flutter build appbundle --release
   ```
2. Sube el archivo generado a la [Google Play Console](https://play.google.com/console/).
3. Completa la información requerida y publica.

**Nota:**  
Asegúrate de cumplir con las políticas de Google Play y de incluir una política de privacidad si usas anuncios.

---

## Contribución

¡Contribuciones son bienvenidas!  
Puedes abrir issues, proponer mejoras o enviar pull requests.

---

## Licencia

Este proyecto está bajo la licencia MIT.  
Consulta el archivo [LICENSE](LICENSE) para más detalles.

---
