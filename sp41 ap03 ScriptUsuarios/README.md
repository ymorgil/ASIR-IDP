Automatización de Usuarios y Grupos en Active Directory

## Importante

Para que el script funcione correctamente el script debe estar en la misma ubicación que los archivos csv.

---

Objetivo del Ejercicio

Automatizar mediante PowerShell la creación de usuarios en Active Directory a partir de un archivo CSV, garantizando:

-  La existencia de una Unidad Organizativa (UO) llamada `appnube`.
-  La creación de usuarios con sus atributos (nombre, país, correo, etc.).
-  La creación automática de grupos si no existen.
-  La asociación de cada usuario a su grupo y país (usando el código ISO2).

---

Explicación del Funcionamiento del Script

El script realiza los siguientes pasos:

1. Carga del módulo ActiveDirectory para habilitar los cmdlets de AD.
2. Detección de la ruta del script para encontrar los archivos `CSV`.
3. Lectura del archivo `paises.csv` para construir un diccionario de nombres de países a códigos ISO2.
4. Conversión del país al código ISO2 antes de crear el usuario.
5. Creación de la Unidad Organizativa `appnube`, si no existe.
6. Procesamiento del archivo `Usuarios.csv`, creando:
   -  Usuarios nuevos si no existen aún.
   -  Grupos nuevos si no existen aún.
   -  Asociación del usuario al grupo correspondiente.
7. Ejecución automática del proceso al final del script.

---
