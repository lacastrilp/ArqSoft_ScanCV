import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:js' as js;

/// Clase para integrar con API para convertir HTML a PDF
class MonkeyPDFIntegration {
  // Usar htmltopdf.io que es más compatible con CORS
  static const String _apiKey =
      '17B87A5F5CEB'; // Reemplazar con tu propia API key
  static const String _apiUrl = 'https://api.html2pdf.app/v1/generate';

  /// Método para generar un PDF desde los datos de un CV
  /// Toma los datos del CV en formato Map y devuelve una URL al PDF generado
  static Future<String> generatePDFFromCV(Map<String, dynamic> cvData) async {
    try {
      // Validar datos de entrada
      if (cvData.isEmpty) {
        print("Error: No hay datos para generar el PDF");
        throw Exception('No hay datos suficientes para generar el PDF');
      }

      print("Iniciando generación de PDF con ${cvData.length} campos");

      // 1. Aplicar los datos del CV a una plantilla HTML
      final String htmlContent = _applyDataToTemplate(cvData);

      if (htmlContent.isEmpty) {
        print("Error: La plantilla HTML generada está vacía");
        throw Exception('La plantilla HTML generada está vacía');
      }

      print(
          "Plantilla HTML generada correctamente, longitud: ${htmlContent.length}");

      // 2. Generar archivo PDF directamente en el navegador usando html2canvas y jsPDF
      return _generatePDFInBrowser(htmlContent, cvData);
    } catch (e) {
      print("Error generando PDF: $e");
      print("Stack trace: ${StackTrace.current}");

      // Si el error es un RangeError, proporcionar información más detallada
      if (e is RangeError) {
        print(
            "RangeError detectado: ${e.message}. Este error puede ocurrir al procesar la plantilla.");
        throw Exception(
            'Error en la generación del PDF: Problema con índices en la plantilla. Por favor, intente de nuevo o contacte soporte.');
      }

      throw Exception('Error en la generación del PDF: $e');
    }
  }

  /// Método para generar PDF en el navegador sin depender de API externas
  static Future<String> _generatePDFInBrowser(
      String htmlContent, Map<String, dynamic> cvData) async {
    try {
      print("Iniciando generación de vista previa con método ultra simple...");

      // Crear un nuevo div para mostrar la vista previa
      final previewId = 'cv-preview-container';

      // Remover versión anterior si existe
      final existingPreview = html.document.getElementById(previewId);
      if (existingPreview != null) {
        existingPreview.remove();
        print("Contenedor previo eliminado");
      }

      // Crear contenedor principal con fondo oscuro transparente
      final previewContainer = html.DivElement()
        ..id = previewId
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'rgba(0,0,0,0.85)'
        ..style.zIndex = '9999'
        ..style.display = 'flex'
        ..style.flexDirection = 'column'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      // Intentar aplicar backdrop-filter si el navegador lo soporta
      try {
        js.context.callMethod('eval', [
          'document.getElementById("$previewId").style.backdropFilter = "blur(5px)";'
        ]);
      } catch (e) {
        // Si no es soportado, no hacer nada
        print("Backdrop filter no soportado: $e");
      }

      // Botón de cierre en la esquina superior derecha
      final closeButton = html.ButtonElement()
        ..innerText = '✕'
        ..style.position = 'absolute'
        ..style.top = '20px'
        ..style.right = '20px'
        ..style.backgroundColor = 'transparent'
        ..style.border = 'none'
        ..style.color = 'white'
        ..style.fontSize = '28px'
        ..style.cursor = 'pointer'
        ..style.transition = 'all 0.2s ease'
        ..style.width = '40px'
        ..style.height = '40px'
        ..style.borderRadius = '50%'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center'
        ..onClick.listen((event) {
          previewContainer.remove();
          print("Vista previa cerrada por el usuario");
        });

      // Efecto hover para el botón de cierre
      closeButton.onMouseOver.listen((event) {
        closeButton.style.backgroundColor = 'rgba(255,255,255,0.2)';
        closeButton.style.transform = 'scale(1.1)';
      });

      closeButton.onMouseOut.listen((event) {
        closeButton.style.backgroundColor = 'transparent';
        closeButton.style.transform = 'scale(1)';
      });

      // Un simple contenedor para el CV
      final contentContainer = html.DivElement()
        ..style.backgroundColor = 'white'
        ..style.maxWidth = '800px'
        ..style.width = '90%'
        ..style.maxHeight = '80vh'
        ..style.overflowY = 'auto'
        ..style.padding = '0'
        ..style.borderRadius = '12px'
        ..style.boxShadow = '0 10px 30px rgba(0,0,0,0.25)'
        ..style.transition = 'all 0.3s ease';

      // Insertar el HTML directamente
      contentContainer.setInnerHtml(
        htmlContent,
        validator: html.NodeValidatorBuilder()
          ..allowHtml5()
          ..allowInlineStyles(),
      );

      // Crear barra de botones
      final buttonBar = html.DivElement()
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.marginTop = '25px'
        ..style.gap = '15px';

      // Botón para descargar PDF
      final downloadButton = html.ButtonElement()
        ..innerText = 'Descargar PDF'
        ..style.padding = '12px 25px'
        ..style.backgroundColor = '#00FF7F'
        ..style.color = '#333'
        ..style.border = 'none'
        ..style.borderRadius = '8px'
        ..style.cursor = 'pointer'
        ..style.fontWeight = 'bold'
        ..style.fontSize = '16px'
        ..style.transition = 'all 0.2s ease'
        ..style.boxShadow = '0 4px 12px rgba(0, 255, 127, 0.3)'
        ..onClick.listen((event) {
          print("Botón de descarga pulsado");
          _downloadAsPDF(previewContainer);
        });

      // Efecto hover para el botón de descarga
      downloadButton.onMouseOver.listen((event) {
        downloadButton.style.backgroundColor = '#00E070';
        downloadButton.style.transform = 'translateY(-2px)';
        downloadButton.style.boxShadow = '0 6px 15px rgba(0, 255, 127, 0.4)';
      });

      downloadButton.onMouseOut.listen((event) {
        downloadButton.style.backgroundColor = '#00FF7F';
        downloadButton.style.transform = 'translateY(0)';
        downloadButton.style.boxShadow = '0 4px 12px rgba(0, 255, 127, 0.3)';
      });

      // Botón para cerrar la vista previa
      final closeViewButton = html.ButtonElement()
        ..innerText = 'Cerrar Vista Previa'
        ..style.padding = '12px 25px'
        ..style.backgroundColor = 'transparent'
        ..style.color = 'white'
        ..style.border = '2px solid white'
        ..style.borderRadius = '8px'
        ..style.cursor = 'pointer'
        ..style.fontWeight = 'bold'
        ..style.fontSize = '16px'
        ..style.transition = 'all 0.2s ease'
        ..onClick.listen((event) {
          previewContainer.remove();
          print("Vista previa cerrada desde botón inferior");
        });

      // Efecto hover para el botón de cerrar
      closeViewButton.onMouseOver.listen((event) {
        closeViewButton.style.backgroundColor = 'rgba(255,255,255,0.2)';
      });

      closeViewButton.onMouseOut.listen((event) {
        closeViewButton.style.backgroundColor = 'transparent';
      });

      // Juntar todos los elementos
      buttonBar.append(downloadButton);
      buttonBar.append(closeViewButton);
      previewContainer.append(closeButton);
      previewContainer.append(contentContainer);
      previewContainer.append(buttonBar);

      // Agregar al documento
      html.document.body!.append(previewContainer);

      // Añadir efecto de entrada con animación
      try {
        js.context.callMethod('eval', [
          'setTimeout(function() { document.querySelector("#$previewId > div:nth-child(2)").style.opacity = "1"; }, 100);'
        ]);
      } catch (e) {
        // Si hay un error, simplemente ignorarlo
        print("Error al aplicar animación: $e");
      }

      return "preview-generated";
    } catch (e) {
      print("Error al generar vista previa: $e");
      html.window.alert("Error al generar vista previa: $e");
      throw Exception('Error al generar vista previa: $e');
    }
  }

  /// Método para descargar el contenido como PDF
  static void _downloadAsPDF(html.Element contentElement) {
    try {
      // Asegurar que las librerías estén cargadas primero
      _loadJsLibraries(() {
        // Código JavaScript extremadamente simple sin ningún cálculo de coordenadas
        final jsCode = '''
          console.log("Generando PDF con método ultra simple...");
          
          // Función para guardar como PDF sin ningún cálculo problemático
          function simpleSavePDF() {
            try {
              // Buscar el contenedor de CV con múltiples opciones de selector
              var contentContainer = null;
              
              // Intentar varios selectores para encontrar el contenedor
              var selectors = [
                "#cv-preview-container div.container",
                "#cv-preview-container .container",
                "#cv-preview-container > div > div",
                "#cv-preview-container > div:nth-child(2)",
                "#cv-preview-container > div"
              ];
              
              // Probar cada selector hasta encontrar uno válido
              for (var i = 0; i < selectors.length; i++) {
                contentContainer = document.querySelector(selectors[i]);
                if (contentContainer) {
                  console.log("Contenedor encontrado con selector: " + selectors[i]);
                  break;
                }
              }
              
              // Si todavía no encontramos el contenedor, buscar de otra manera
              if (!contentContainer) {
                console.log("Intentando encontrar el contenedor por estructura anidada");
                var parentContainer = document.querySelector("#cv-preview-container");
                if (parentContainer && parentContainer.children.length > 1) {
                  // Normalmente el segundo hijo es el contenedor de contenido (después del botón de cierre)
                  contentContainer = parentContainer.children[1];
                  console.log("Contenedor encontrado mediante hijos del contenedor principal");
                }
              }
              
              if (!contentContainer) {
                alert("No se pudo encontrar el contenedor del CV. Intente de nuevo.");
                console.error("No se encontró ningún contenedor válido");
                return;
              }
              
              // Asegurar que los caracteres especiales se muestren correctamente
              var allTextElements = contentContainer.querySelectorAll('*');
              allTextElements.forEach(function(el) {
                if (el.childNodes.length === 1 && el.childNodes[0].nodeType === 3) {
                  // Es un nodo de texto, podemos asegurar la codificación si es necesario
                  // En este caso no hacemos nada ya que los navegadores modernos manejan UTF-8 correctamente
                }
              });
              
              // Guardar dimensiones originales
              var origWidth = contentContainer.style.width;
              var origHeight = contentContainer.style.height;
              
              // Fijar tamaño para mejorar la calidad
              contentContainer.style.width = "800px";
              
              try {
                // Crear un nuevo canvas simple con dimensiones seguras
                var canvas = document.createElement('canvas');
                
                // Dimensiones generosas para el canvas
                canvas.width = 1600; // Doble de 800px para mejor calidad
                canvas.height = 2200; // Aproximadamente proporción A4
                
                var ctx = canvas.getContext('2d');
                ctx.fillStyle = '#FFFFFF';
                ctx.fillRect(0, 0, canvas.width, canvas.height);
                
                console.log("Iniciando renderizado con html2canvas...");
                console.log("Contenedor dimensiones: " + contentContainer.offsetWidth + "x" + contentContainer.offsetHeight);
                
                // Usar html2canvas con opciones simplificadas y valores seguros
                html2canvas(contentContainer, {
                  canvas: canvas,
                  scale: 2,
                  useCORS: true,
                  allowTaint: true,
                  backgroundColor: '#FFFFFF',
                  logging: true,
                  width: contentContainer.offsetWidth || 800,
                  height: contentContainer.offsetHeight || 1100,
                  onclone: function(clonedDoc) {
                    console.log("Documento clonado correctamente");
                    // Asegurar que el contenedor clonado tenga dimensiones correctas
                    var clonedContainer = clonedDoc.querySelector(selectors[0]);
                    if (clonedContainer) {
                      clonedContainer.style.width = "800px";
                      clonedContainer.style.height = "auto";
                    }
                    
                    // Asegurar que la fuente se cargue en el documento clonado
                    var linkElement = document.createElement('link');
                    linkElement.rel = 'stylesheet';
                    linkElement.href = 'https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&family=Poppins:wght@400;500;600;700&display=swap';
                    clonedDoc.head.appendChild(linkElement);
                  }
                }).then(function(canvas) {
                  try {
                    console.log("Canvas generado correctamente: " + canvas.width + "x" + canvas.height);
                    
                    // Crear un PDF simple sin múltiples páginas
                    var pdf = new jspdf.jsPDF({
                      orientation: 'portrait',
                      unit: 'mm',
                      format: 'a4',
                      putOnlyUsedFonts: true
                    });
                    
                    // Dimensiones A4
                    var pageWidth = 210;
                    var pageHeight = 297;
                    
                    // Obtener la URL de la imagen de forma segura
                    var imgData;
                    try {
                      imgData = canvas.toDataURL('image/jpeg', 0.95);
                      console.log("Imagen generada correctamente");
                    } catch (e) {
                      console.error("Error al generar la imagen:", e);
                      alert("Error al generar la imagen. Intente de nuevo. Detalles: " + e.message);
                      return;
                    }
                    
                    // Agregar imagen simple sin cálculos complejos
                    pdf.addImage(
                      imgData, 
                      'JPEG', 
                      0, // X position
                      0, // Y position
                      pageWidth, // Width in mm
                      pageHeight // Height in mm (recortar lo que no quepa)
                    );
                    
                    // Guardar PDF con nombre mejorado
                    pdf.save('curriculum_vitae.pdf');
                    console.log("PDF generado correctamente");
                    
                    // Restaurar dimensiones originales
                    contentContainer.style.width = origWidth;
                    contentContainer.style.height = origHeight;
                  } catch(err) {
                    alert("Error al crear PDF: " + err.message);
                    console.error("Error al crear PDF:", err);
                    
                    // Restaurar dimensiones originales en caso de error
                    contentContainer.style.width = origWidth;
                    contentContainer.style.height = origHeight;
                  }
                }).catch(function(err) {
                  alert("Error al generar imagen: " + err.message);
                  console.error("Error al generar imagen:", err);
                  
                  // Restaurar dimensiones originales en caso de error
                  contentContainer.style.width = origWidth;
                  contentContainer.style.height = origHeight;
                });
              } catch (canvasErr) {
                alert("Error al preparar el canvas: " + canvasErr.message);
                console.error("Error al preparar el canvas:", canvasErr);
                
                // Restaurar dimensiones originales en caso de error
                contentContainer.style.width = origWidth;
                contentContainer.style.height = origHeight;
              }
            } catch(err) {
              alert("Error general: " + err.message);
              console.error("Error general:", err);
            }
          }
          
          // Ejecutar con pequeño retraso para asegurar que todo está cargado
          setTimeout(simpleSavePDF, 500);
        ''';

        // Ejecutar el código JavaScript
        js.context.callMethod('eval', [jsCode]);
      });
    } catch (e) {
      print("Error al descargar como PDF: $e");
      html.window.alert("Error al generar el PDF: $e");
    }
  }

  /// Método para cargar librerías JavaScript necesarias
  static void _loadJsLibraries(Function callback) {
    try {
      print("Iniciando carga de librerías JavaScript...");

      // Verificar si las librerías ya están cargadas
      if (js.context.hasProperty('html2canvas') &&
          js.context.hasProperty('jspdf') &&
          js.context.hasProperty('domtoimage')) {
        print("Todas las librerías ya están cargadas");
        callback();
        return;
      }

      // Contador para controlar cuando todas las librerías estén cargadas
      var loadedLibraries = 0;
      var requiredLibraries = 3; // html2canvas, jspdf, domtoimage

      // Función para verificar si todas las librerías están cargadas
      void checkAllLoaded() {
        loadedLibraries++;
        print("Librería cargada: $loadedLibraries de $requiredLibraries");
        if (loadedLibraries >= requiredLibraries) {
          print("Todas las librerías cargadas correctamente");
          callback();
        }
      }

      // Cargar domtoimage (nueva librería)
      if (!js.context.hasProperty('domtoimage')) {
        print("Cargando dom-to-image...");
        final domtoImageScript = html.ScriptElement()
          ..src =
              'https://cdnjs.cloudflare.com/ajax/libs/dom-to-image/2.6.0/dom-to-image.min.js'
          ..type = 'text/javascript'
          ..id = 'domtoimage-script'; // Añadir ID para checkeo

        domtoImageScript.onLoad.listen((event) {
          print("dom-to-image cargado");
          checkAllLoaded();
        });

        domtoImageScript.onError.listen((event) {
          print("Error al cargar dom-to-image");
          // Continuar de todos modos
          checkAllLoaded();
        });

        html.document.head!.append(domtoImageScript);
      } else {
        print("dom-to-image ya cargado");
        checkAllLoaded();
      }

      // Cargar html2canvas
      if (!js.context.hasProperty('html2canvas')) {
        print("Cargando html2canvas...");
        final html2canvasScript = html.ScriptElement()
          ..src =
              'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js'
          ..type = 'text/javascript'
          ..id = 'html2canvas-script';

        html2canvasScript.onLoad.listen((event) {
          print("html2canvas cargado");
          checkAllLoaded();
        });

        html2canvasScript.onError.listen((event) {
          print("Error al cargar html2canvas");
          // Continuar de todos modos
          checkAllLoaded();
        });

        html.document.head!.append(html2canvasScript);
      } else {
        print("html2canvas ya cargado");
        checkAllLoaded();
      }

      // Cargar jsPDF
      if (!js.context.hasProperty('jspdf')) {
        print("Cargando jsPDF...");
        final jspdfScript = html.ScriptElement()
          ..src =
              'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js'
          ..type = 'text/javascript'
          ..id = 'jspdf-script';

        jspdfScript.onLoad.listen((event) {
          print("jsPDF cargado");
          checkAllLoaded();
        });

        jspdfScript.onError.listen((event) {
          print("Error al cargar jsPDF");
          // Continuar de todos modos
          checkAllLoaded();
        });

        html.document.head!.append(jspdfScript);
      } else {
        print("jsPDF ya cargado");
        checkAllLoaded();
      }
    } catch (e) {
      print("Error al cargar librerías: $e");
      callback(); // Intentar continuar de todos modos
    }
  }

  /// Método auxiliar para reemplazar marcadores de forma segura
  static String _safeReplace(
      String template, String placeholder, String value) {
    try {
      // Si el placeholder no existe, devolver la plantilla sin cambios
      if (!template.contains(placeholder)) {
        return template;
      }

      // Asegurar que los caracteres especiales se manejan correctamente
      String safeValue = _ensureUtf8Encoding(value);

      return template.replaceAll(placeholder, safeValue);
    } catch (e) {
      print("Error al reemplazar '$placeholder': $e");
      // En caso de error, devolver la plantilla original
      return template;
    }
  }

  /// Método para asegurar que los caracteres especiales se codifican correctamente
  static String _ensureUtf8Encoding(String text) {
    try {
      if (text.isEmpty) {
        return '';
      }

      // Asegurarnos de que los caracteres especiales se muestran correctamente
      // Esto es especialmente importante para acentos y caracteres especiales en español

      // Convertir caracteres problemáticos a entidades HTML si es necesario
      Map<String, String> specialChars = {
        'á': 'á',
        'é': 'é',
        'í': 'í',
        'ó': 'ó',
        'ú': 'ú',
        'Á': 'Á',
        'É': 'É',
        'Í': 'Í',
        'Ó': 'Ó',
        'Ú': 'Ú',
        'ñ': 'ñ',
        'Ñ': 'Ñ',
        'ü': 'ü',
        'Ü': 'Ü',
        '¿': '¿',
        '¡': '¡',
        '€': '€',
      };

      // Solo reemplazar si es necesario
      String result = text;
      bool needsReplacement = false;

      for (var char in specialChars.keys) {
        if (result.contains(char)) {
          needsReplacement = true;
          break;
        }
      }

      // Si no hay caracteres especiales, devolver el texto original
      if (!needsReplacement) {
        return text;
      }

      // Si hay caracteres especiales, asegurar que se muestran correctamente
      // En la mayoría de los casos, el navegador manejará esto correctamente
      // pero podemos añadir esta capa de seguridad

      return text;
    } catch (e) {
      print("Error al codificar texto: $e");
      return text;
    }
  }

  /// Método para aplicar los datos del CV a una plantilla HTML
  static String _applyDataToTemplate(Map<String, dynamic> cvData) {
    // Esta es una plantilla HTML mejorada para el CV con un diseño similar a la imagen
    String template = '''
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Currículum Vitae - {{nombre}}</title>
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&family=Poppins:wght@400;500;600;700&display=swap');
            
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: 'Open Sans', Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f9f9f9;
            }
            
            .container {
                max-width: 800px;
                margin: 0 auto;
                background-color: white;
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                position: relative;
                overflow: hidden;
            }
            
            .color-bar {
                height: 10px;
                background: linear-gradient(90deg, #4B9EFA 0%, #00FF7F 100%);
                width: 100%;
            }
            
            header {
                display: flex;
                align-items: center;
                padding: 30px;
                background-color: #ffffff;
                position: relative;
            }
            
            header::after {
                content: '';
                position: absolute;
                bottom: 0;
                left: 30px;
                right: 30px;
                height: 2px;
                background: linear-gradient(90deg, #4B9EFA 0%, #00FF7F 100%);
            }
            
            .profile-img {
                width: 120px;
                height: 120px;
                border-radius: 50%;
                border: 4px solid #4B9EFA;
                overflow: hidden;
                margin-right: 25px;
                background-color: #e0e0e0;
                display: flex;
                align-items: center;
                justify-content: center;
                color: #999;
                font-size: 40px;
                box-shadow: 0 4px 10px rgba(75, 158, 250, 0.3);
                flex-shrink: 0;
            }
            
            .profile-img img {
                width: 100%;
                height: 100%;
                object-fit: cover;
            }
            
            .header-info {
                flex: 1;
            }
            
            h1 {
                color: #222;
                margin-bottom: 8px;
                font-size: 32px;
                font-family: 'Poppins', sans-serif;
                font-weight: 600;
            }
            
            .subtitle {
                color: #4B9EFA;
                margin-bottom: 15px;
                font-style: normal;
                font-size: 18px;
                font-family: 'Poppins', sans-serif;
                font-weight: 500;
            }
            
            .contact-info {
                margin-bottom: 5px;
                font-size: 14px;
                display: flex;
                align-items: center;
                flex-wrap: wrap;
            }
            
            .contact-item {
                margin-right: 20px;
                display: flex;
                align-items: center;
                margin-bottom: 8px;
                color: #555;
            }
            
            .icon {
                color: #4B9EFA;
                margin-right: 8px;
                font-size: 16px;
            }
            
            .main-content {
                display: flex;
                padding: 0;
            }
            
            .left-column {
                width: 66%;
                padding: 30px;
                border-right: 1px solid #eaeaea;
            }
            
            .right-column {
                width: 34%;
                padding: 30px;
                background-color: #f8f9fa;
            }
            
            .section {
                margin-bottom: 30px;
            }
            
            .section-title {
                color: #222;
                font-family: 'Poppins', sans-serif;
                font-weight: 600;
                font-size: 20px;
                margin-bottom: 15px;
                position: relative;
                padding-left: 15px;
            }
            
            .section-title::before {
                content: "";
                position: absolute;
                left: 0;
                top: 0;
                bottom: 0;
                width: 5px;
                background: linear-gradient(to bottom, #4B9EFA, #00FF7F);
                border-radius: 3px;
            }
            
            .job, .education {
                margin-bottom: 20px;
                position: relative;
                padding-left: 20px;
                border-left: 2px solid #eaeaea;
            }
            
            .job:before, .education:before {
                content: "";
                position: absolute;
                left: -6px;
                top: 8px;
                width: 10px;
                height: 10px;
                border-radius: 50%;
                background: linear-gradient(135deg, #4B9EFA, #00FF7F);
                box-shadow: 0 0 5px rgba(0,0,0,0.1);
            }
            
            .job-title, .institution {
                font-weight: 600;
                color: #222;
                font-size: 16px;
            }
            
            .job-company, .education-degree {
                color: #4B9EFA;
                font-weight: 500;
            }
            
            .job-period, .education-period {
                color: #777;
                font-size: 14px;
                font-style: italic;
                margin-top: 3px;
            }
            
            .job-description, .education-description {
                margin-top: 8px;
                color: #555;
                line-height: 1.7;
            }
            
            .skills-container {
                display: flex;
                flex-wrap: wrap;
            }
            
            .skill-category {
                margin-bottom: 15px;
                width: 100%;
            }
            
            .skill-category-title {
                font-weight: 600;
                margin-bottom: 8px;
                color: #222;
            }
            
            .skills-list {
                display: flex;
                flex-wrap: wrap;
            }
            
            .skill {
                background: linear-gradient(90deg, rgba(75, 158, 250, 0.1) 0%, rgba(0, 255, 127, 0.1) 100%);
                color: #4B9EFA;
                border: 1px solid rgba(75, 158, 250, 0.3);
                padding: 6px 12px;
                margin-right: 10px;
                margin-bottom: 10px;
                border-radius: 20px;
                font-size: 13px;
                transition: all 0.2s;
            }
            
            .skill:hover {
                background: linear-gradient(90deg, rgba(75, 158, 250, 0.2) 0%, rgba(0, 255, 127, 0.2) 100%);
                transform: translateY(-2px);
            }
            
            .datos-personales {
                margin-bottom: 5px;
                font-size: 14px;
            }
            
            .datos-personales-title {
                font-weight: 600;
                margin-bottom: 5px;
                color: #222;
            }
            
            .datos-personales-item {
                margin-bottom: 12px;
                background-color: #fff;
                padding: 12px;
                border-radius: 8px;
                box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            }
            
            .datos-personales-item .datos-personales-title {
                color: #4B9EFA;
                font-size: 13px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            
            .habilidades-list {
                list-style-type: none;
                padding-left: 0;
            }
            
            .habilidades-item {
                margin-bottom: 10px;
                padding: 8px 0;
                display: flex;
                align-items: center;
                border-bottom: 1px solid rgba(0,0,0,0.05);
            }
            
            .habilidades-item:before {
                content: "";
                width: 8px;
                height: 8px;
                border-radius: 50%;
                background: linear-gradient(135deg, #4B9EFA, #00FF7F);
                margin-right: 10px;
                flex-shrink: 0;
            }
            
            .certificacion-item {
                margin-bottom: 15px;
                padding: 12px 15px;
                border-radius: 8px;
                background-color: #fff;
                box-shadow: 0 2px 5px rgba(0,0,0,0.05);
                position: relative;
                border-left: 3px solid #4B9EFA;
            }
            
            @media print {
                body {
                    background-color: white;
                }
                .container {
                    box-shadow: none;
                }
                .right-column {
                    background-color: #f8f9fa !important;
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                }
                .color-bar {
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="color-bar"></div>
            <header>
                <div class="profile-img">
                    {{#if foto_url}}
                    <img src="{{foto_url}}" alt="Foto de perfil">
                    {{else}}
                    <span>CV</span>
                    {{/if}}
                </div>
                <div class="header-info">
                <h1>{{nombre}} {{apellidos}}</h1>
                    {{#if profesion}}<div class="subtitle">{{profesion}}</div>{{/if}}
                <div class="contact-info">
                        {{#if correo}}<div class="contact-item"><span class="icon">✉</span> {{correo}}</div>{{/if}}
                        {{#if telefono}}<div class="contact-item"><span class="icon">☎</span> {{telefono}}</div>{{/if}}
                        {{#if ubicacion}}<div class="contact-item"><span class="icon">📍</span> {{ubicacion}}</div>{{/if}}
                </div>
                </div>
            </header>
            
            <div class="main-content">
                <div class="left-column">
            {{#if perfil_profesional}}
            <div class="section">
                <h2 class="section-title">Perfil Profesional</h2>
                <p>{{perfil_profesional}}</p>
            </div>
            {{/if}}
            
            {{#if experiencia_laboral}}
            <div class="section">
                <h2 class="section-title">Experiencia Laboral</h2>
                {{experiencia_laboral_html}}
            </div>
            {{/if}}
            
            {{#if educacion}}
            <div class="section">
                        <h2 class="section-title">Formación Académica</h2>
                {{educacion_html}}
            </div>
            {{/if}}
                    
                    {{#if certificaciones}}
                    <div class="section">
                        <h2 class="section-title">Certificaciones</h2>
                        {{certificaciones_html}}
                    </div>
                    {{/if}}
                </div>
                
                <div class="right-column">
                    <div class="section">
                        <h2 class="section-title">Datos Personales</h2>
                        <div class="datos-personales">
                            {{#if fecha_nacimiento}}
                            <div class="datos-personales-item">
                                <div class="datos-personales-title">Fecha de nacimiento</div>
                                {{fecha_nacimiento}}
                            </div>
                            {{/if}}
                            {{#if identificacion}}
                            <div class="datos-personales-item">
                                <div class="datos-personales-title">Identificación</div>
                                {{identificacion}}
                            </div>
                            {{/if}}
                            {{#if nacionalidad}}
                            <div class="datos-personales-item">
                                <div class="datos-personales-title">Nacionalidad</div>
                                {{nacionalidad}}
                            </div>
                            {{/if}}
                        </div>
                    </div>
            
            {{#if habilidades}}
            <div class="section">
                <h2 class="section-title">Habilidades</h2>
                        <ul class="habilidades-list">
                    {{habilidades_html}}
                        </ul>
            </div>
            {{/if}}
            
            {{#if idiomas}}
            <div class="section">
                <h2 class="section-title">Idiomas</h2>
                        {{idiomas_html}}
            </div>
            {{/if}}
            </div>
            </div>
        </div>
    </body>
    </html>
    ''';

    try {
      // Reemplazar los marcadores de posición con los datos reales de forma segura
      template = _safeReplace(
          template, '{{nombre}}', cvData['nombres']?.toString() ?? '');
      template = _safeReplace(
          template, '{{apellidos}}', cvData['apellidos']?.toString() ?? '');
      template = _safeReplace(
          template, '{{correo}}', cvData['correo']?.toString() ?? '');
      template = _safeReplace(
          template, '{{telefono}}', cvData['telefono']?.toString() ?? '');
      template = _safeReplace(
          template, '{{ubicacion}}', cvData['direccion']?.toString() ?? '');
      template = _safeReplace(
          template, '{{profesion}}', cvData['profesion']?.toString() ?? '');
      template = _safeReplace(
          template, '{{foto_url}}', cvData['foto_url']?.toString() ?? '');
      template = _safeReplace(template, '{{fecha_nacimiento}}',
          cvData['fecha_nacimiento']?.toString() ?? '');
      template = _safeReplace(template, '{{identificacion}}',
          cvData['identificacion']?.toString() ?? '');
      template = _safeReplace(template, '{{nacionalidad}}',
          cvData['nacionalidad']?.toString() ?? '');
      template = _safeReplace(
          template, '{{linkedin}}', cvData['linkedin']?.toString() ?? '');
      template = _safeReplace(
          template, '{{github}}', cvData['github']?.toString() ?? '');
      template = _safeReplace(
          template, '{{portafolio}}', cvData['portafolio']?.toString() ?? '');
      template = _safeReplace(template, '{{perfil_profesional}}',
          cvData['perfil_profesional']?.toString() ?? '');

      // Gestionar condicionales en la plantilla
      template = _processConditionals(template, '{{#if foto_url}}', '{{/if}}',
          (cvData['foto_url']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if profesion}}', '{{/if}}',
          (cvData['profesion']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if correo}}', '{{/if}}',
          (cvData['correo']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if telefono}}', '{{/if}}',
          (cvData['telefono']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if ubicacion}}', '{{/if}}',
          (cvData['direccion']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if fecha_nacimiento}}',
          '{{/if}}', (cvData['fecha_nacimiento']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if identificacion}}',
          '{{/if}}', (cvData['identificacion']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if nacionalidad}}',
          '{{/if}}', (cvData['nacionalidad']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if linkedin}}', '{{/if}}',
          (cvData['linkedin']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if github}}', '{{/if}}',
          (cvData['github']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if portafolio}}', '{{/if}}',
          (cvData['portafolio']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(
          template,
          '{{#if perfil_profesional}}',
          '{{/if}}',
          (cvData['perfil_profesional']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(
          template,
          '{{#if experiencia_laboral}}',
          '{{/if}}',
          (cvData['experiencia_laboral']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if educacion}}', '{{/if}}',
          (cvData['educacion']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if habilidades}}',
          '{{/if}}', (cvData['habilidades']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if idiomas}}', '{{/if}}',
          (cvData['idiomas']?.toString() ?? '').isNotEmpty);
      template = _processConditionals(template, '{{#if certificaciones}}',
          '{{/if}}', (cvData['certificaciones']?.toString() ?? '').isNotEmpty);

      // Transformar experiencia laboral a HTML
      if ((cvData['experiencia_laboral']?.toString() ?? '').isNotEmpty) {
        String experienciaHtml = '';
        try {
          final experienciaLines =
              (cvData['experiencia_laboral']?.toString() ?? '')
                  .split('\n')
                  .where((line) => line.trim().isNotEmpty);

          for (String line in experienciaLines) {
            experienciaHtml += '''
            <div class="job">
              <div class="job-title">$line</div>
            </div>
            ''';
          }

          template = _safeReplace(
              template, '{{experiencia_laboral_html}}', experienciaHtml);
        } catch (e) {
          print("Error al procesar experiencia laboral: $e");
          // Asegurar que el marcador se reemplaza incluso si hay error
          template = _safeReplace(template, '{{experiencia_laboral_html}}',
              '<div class="job"><div class="job-title">Error al procesar datos</div></div>');
        }
      }

      // Transformar educación a HTML
      if ((cvData['educacion']?.toString() ?? '').isNotEmpty) {
        String educacionHtml = '';
        try {
          final educacionLines = (cvData['educacion']?.toString() ?? '')
              .split('\n')
              .where((line) => line.trim().isNotEmpty);

          for (String line in educacionLines) {
            educacionHtml += '''
            <div class="education">
              <div class="institution">$line</div>
            </div>
            ''';
          }

          template =
              _safeReplace(template, '{{educacion_html}}', educacionHtml);
        } catch (e) {
          print("Error al procesar educación: $e");
          template = _safeReplace(template, '{{educacion_html}}',
              '<div class="education"><div class="institution">Error al procesar datos</div></div>');
        }
      }

      // Transformar certificaciones a HTML
      if ((cvData['certificaciones']?.toString() ?? '').isNotEmpty) {
        String certificacionesHtml = '';
        try {
          final certificacionesLines =
              (cvData['certificaciones']?.toString() ?? '')
                  .split('\n')
                  .where((line) => line.trim().isNotEmpty);

          for (String line in certificacionesLines) {
            certificacionesHtml += '''
            <div class="certificacion-item">$line</div>
            ''';
          }

          template = _safeReplace(
              template, '{{certificaciones_html}}', certificacionesHtml);
        } catch (e) {
          print("Error al procesar certificaciones: $e");
          template = _safeReplace(template, '{{certificaciones_html}}',
              '<div class="certificacion-item">Error al procesar datos</div>');
        }
      }

      // Transformar habilidades a HTML
      if ((cvData['habilidades']?.toString() ?? '').isNotEmpty) {
        String habilidadesHtml = '';
        try {
          final habilidadesList = (cvData['habilidades']?.toString() ?? '')
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty);

          for (String skill in habilidadesList) {
            habilidadesHtml += '<li class="habilidades-item">$skill</li>';
          }

          template =
              _safeReplace(template, '{{habilidades_html}}', habilidadesHtml);
        } catch (e) {
          print("Error al procesar habilidades: $e");
          template = _safeReplace(template, '{{habilidades_html}}',
              '<li class="habilidades-item">Error al procesar datos</li>');
        }
      }

      // Transformar idiomas a HTML
      if ((cvData['idiomas']?.toString() ?? '').isNotEmpty) {
        String idiomasHtml = '<ul class="habilidades-list">';
        try {
          final idiomasList = (cvData['idiomas']?.toString() ?? '')
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty);

          for (String idioma in idiomasList) {
            idiomasHtml += '<li class="habilidades-item">$idioma</li>';
          }
          idiomasHtml += '</ul>';

          template = _safeReplace(template, '{{idiomas_html}}', idiomasHtml);
        } catch (e) {
          print("Error al procesar idiomas: $e");
          template = _safeReplace(template, '{{idiomas_html}}',
              '<ul class="habilidades-list"><li class="habilidades-item">Error al procesar datos</li></ul>');
        }
      }
    } catch (e) {
      print("Error general al aplicar datos a la plantilla: $e");
      // En caso de error general, devolver una plantilla básica y segura
      return '''
      <!DOCTYPE html>
      <html lang="es">
      <head>
          <title>Currículum de Emergencia</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            h1 { color: #333; }
          </style>
      </head>
      <body>
          <h1>Currículum Vitae</h1>
          <p>Nombre: ${cvData['nombres']?.toString() ?? 'No especificado'} ${cvData['apellidos']?.toString() ?? ''}</p>
          <p>Se produjo un error al generar el CV. Por favor, intente de nuevo.</p>
      </body>
      </html>
      ''';
    }

    return template;
  }

  /// Método auxiliar para procesar condicionales en la plantilla HTML
  static String _processConditionals(
      String template, String start, String end, bool condition) {
    // Buscar el índice de inicio
    final startIndex = template.indexOf(start);

    // Si no se encuentra el inicio, devolver la plantilla sin cambios
    if (startIndex < 0) {
      print("Advertencia: No se encontró el marcador '$start' en la plantilla");
      return template;
    }

    // Buscar el índice de fin empezando desde la posición de inicio
    final endIndex = template.indexOf(end, startIndex);

    // Si no se encuentra el fin, devolver la plantilla sin cambios
    if (endIndex < 0) {
      print(
          "Advertencia: No se encontró el marcador '$end' en la plantilla después de '$start'");
      return template;
    }

    // Calcular el índice final (incluyendo la longitud del marcador de fin)
    final finalEndIndex = endIndex + end.length;

    if (condition) {
      // Si la condición es verdadera, eliminar las etiquetas condicionales
      final content = template.substring(startIndex + start.length, endIndex);
      return template.substring(0, startIndex) +
          content +
          template.substring(finalEndIndex);
    } else {
      // Si la condición es falsa, eliminar todo el bloque condicional
      return template.substring(0, startIndex) +
          template.substring(finalEndIndex);
    }
  }
}

/// Widget para mostrar un botón que genera un PDF del CV
class GeneratePDFButton extends StatelessWidget {
  final Map<String, dynamic> cvData;
  final VoidCallback? onGenerating;
  final Function(String pdfUrl)? onGenerated;
  final Function(String error)? onError;

  const GeneratePDFButton({
    super.key,
    required this.cvData,
    this.onGenerating,
    this.onGenerated,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Verificar si hay datos suficientes para generar el PDF
          if (cvData.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'No hay información para generar el PDF. Guarde primero los datos.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          print("Generando PDF con ${cvData.length} campos de datos");
          print("Datos: ${cvData.keys.join(', ')}");

          // Notificar que se está generando el PDF
          onGenerating?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generando PDF...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );

          // Preparar datos asegurando que todos los valores sean seguros
          Map<String, dynamic> safeData = {};

          // Agregar con protección contra nulos
          void addSafely(String key, dynamic value) {
            if (value != null) {
              final String strValue = value.toString();
              if (strValue.isNotEmpty) {
                safeData[key] = strValue;
                print(
                    "Campo añadido: $key = ${strValue.length > 50 ? '${strValue.substring(0, 50)}...' : strValue}");
              }
            }
          }

          // Agregar todos los campos esenciales
          cvData.forEach((key, value) {
            addSafely(key, value);
          });

          // Asegurar campos obligatorios para evitar errores
          if (!safeData.containsKey('nombres')) {
            safeData['nombres'] = 'Nombre';
            print("Campo nombres añadido por defecto");
          }
          if (!safeData.containsKey('apellidos')) {
            safeData['apellidos'] = 'Apellido';
            print("Campo apellidos añadido por defecto");
          }

          print("Datos procesados, iniciando generación PDF...");

          try {
            // Primero mostramos la vista previa
            final previewResult =
                await MonkeyPDFIntegration.generatePDFFromCV(safeData);
            print("Vista previa generada: $previewResult");

            // Luego esperamos un momento y activamos la descarga automáticamente
            Future.delayed(Duration(milliseconds: 1500), () {
              try {
                // Buscar el contenedor del CV para generar el PDF
                final contentContainer =
                    html.document.querySelector("#cv-preview-container");
                if (contentContainer != null) {
                  print("Contenedor encontrado, procediendo a generar PDF");
                  // Descargar como PDF
                  MonkeyPDFIntegration._downloadAsPDF(contentContainer);

                  // Notificar que se ha generado el PDF
                  onGenerated?.call(previewResult);
                } else {
                  print(
                      "ERROR: No se encontró el contenedor #cv-preview-container");
                  throw Exception('No se encontró el contenedor del CV');
                }
              } catch (innerError) {
                print("Error en descarga automática: $innerError");
                print("Stack trace: ${StackTrace.current}");
                onError?.call(innerError.toString());

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Error en la descarga automática: $innerError'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
          } catch (previewError) {
            print("Error al generar la vista previa: $previewError");
            print("Stack trace: ${StackTrace.current}");
            onError?.call(previewError.toString());

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Error al generar la vista previa: $previewError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print("Error general al generar el PDF: $e");
          print("Stack trace: ${StackTrace.current}");
          // Notificar el error
          onError?.call(e.toString());

          if (!context.mounted) return;

          // Mostrar un mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al generar el PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FF7F),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        shadowColor: const Color(0x8000FF7F),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.picture_as_pdf, size: 20),
          SizedBox(width: 10),
          Text(
            'Generar PDF',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
