**Curso:** Arquitectura de Software  
**Integrantes:** Alejandro Castrillón, Camila Velez, Alejandro Arteaga

# Documentación del Proyecto

La documentación completa del Taller 1 se encuentra en el siguiente archivo:

[Ver documentación (Taller 1)](./Taller1.pdf)

# Guía para Compilar el Proyecto Flutter

## Requisitos Previos

1. **Instalar Flutter SDK**
   Descarga e instala Flutter desde la documentación oficial:
   [https://docs.flutter.dev/tools/sdk](https://docs.flutter.dev/tools/sdk)

2. **Clonar el repositorio**

   ```bash
   git clone https://github.com/<tu-usuario>/<tu-repo>.git
   cd <tu-repo>
   ```

---

## Configuración Inicial

Antes de compilar, realiza el siguiente cambio:

En el archivo correspondiente, **reemplaza la clave**:

```diff
- sk-or-v1-69a1d008acb699669930b119f813db4c95e2ed02bf4a3b05766886e536258a6_5
+ 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
```

---

## Compilar el Proyecto

Ejecuta los siguientes comandos en tu terminal:

```bash
flutter clean
flutter pub get
flutter build web --base-href=/ --target="C:\Users\<nombreUsuario>\folder1\folder2\Scanner_CV-main\lib\main.dart"
cd build/web
python -m http.server 8080
```

---

## Nota Importante

> **Recuerda:**
> Cambia la ruta
> `C:\Users\<nombreUsuario>\folder1\folder2\`
> por la ruta **correspondiente a tu entorno local**.

---

## Visualizar la Aplicación

Una vez que el servidor esté en ejecución, abre en tu navegador:

[http://localhost:8080](http://localhost:8080)

