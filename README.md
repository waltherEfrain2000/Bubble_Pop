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

✅ **Integración AdMob completada**

La app ya tiene integrada la funcionalidad de anuncios AdMob en todas las pantallas principales. Los banners aparecen automáticamente en la parte inferior de cada pantalla.

### Configuración implementada:

**1. Dependencias agregadas:**
- `google_mobile_ads: ^5.0.0` en `pubspec.yaml`

**2. Configuración nativa:**
- **Android:** App ID configurado en `AndroidManifest.xml`
  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-8618860832262188~6239080999"/>
  ```

**3. IDs de AdMob utilizados:**
- **App ID:** `ca-app-pub-8618860832262188~6239080999`
- **Banner Ad Unit ID:** `ca-app-pub-8618860832262188/9820584425`

**4. Pantallas con banners:**
- ✅ StartScreen (pantalla de inicio)
- ✅ GameScreen (pantalla de juego)
- ✅ ResultScreen (pantalla de resultados)
- ✅ PauseMenu (menú de pausa)

**5. Características técnicas:**
- Inicialización automática de MobileAds en `main.dart`
- Widget AdmobBanner reutilizable
- Manejo de errores de carga de anuncios
- Placeholder mientras cargan los anuncios

### Para desarrollo y pruebas:

Durante el desarrollo, los anuncios de prueba aparecerán automáticamente. Para usar anuncios reales en producción, asegúrate de que:
1. La app esté firmada con el certificado de release
2. La app esté publicada en Play Store
3. Los IDs de AdMob estén correctamente configurados en la consola de AdMob

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

### **Subir a Google Play Store con AdMob**

**Preparación previa:**
1. ✅ AdMob integrado y funcionando
2. ✅ App ID y Banner Ad Unit ID configurados
3. ✅ Inicialización de MobileAds implementada

**Pasos para publicar:**

1. **Crear archivo de release APK/AAB:**
   ```sh
   flutter build apk --release
   # o para App Bundle (recomendado)
   flutter build appbundle --release
   ```

2. **Verificar configuración AdMob:**
   - Confirmar que los IDs de AdMob son de producción (no de prueba)
   - Verificar que la app esté vinculada correctamente en AdMob Console

3. **Configurar Play Console:**
   - Sube el archivo generado a [Google Play Console](https://play.google.com/console/)
   - Completa la información de la app
   - **Importante:** Agrega una política de privacidad (obligatorio para apps con anuncios)

4. **Política de Privacidad para AdMob:**
   Debe incluir información sobre:
   - Uso de Google AdMob
   - Recopilación de datos para personalización de anuncios
   - Derechos del usuario sobre sus datos
   - Enlace a la política de privacidad de Google

5. **Consideraciones importantes:**
   - Las apps con anuncios requieren política de privacidad
   - Los anuncios reales solo aparecen después de la aprobación de Play Store
   - Puede tomar 24-48 horas para que los anuncios comiencen a aparecer
   - Monitorea el rendimiento en AdMob Console

**Estado actual:**
- ✅ Integración técnica completa
- ✅ Banners en todas las pantallas principales
- ✅ Configuración AdMob correcta
- 📋 Lista para builds de release y publicación

---

## Contribución

¡Contribuciones son bienvenidas!  
Puedes abrir issues, proponer mejoras o enviar pull requests.

---

## Licencia

Este proyecto está bajo la licencia MIT.  
Consulta el archivo [LICENSE](LICENSE) para más detalles.

---
