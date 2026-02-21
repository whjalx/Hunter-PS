# Hunter-PS
Un buscador de películas, series y animes (gratis). La aplicación utiliza **Flask** en el backend y delega la lógica de scraping o recolección de enlaces a diversos scripts en **Bash**.

## Fuentes de Búsqueda Soportadas
- Cuevana
- PoseidonHD
- Seriesflix
- Katanime

## Requisitos Previos

Para que el proyecto funcione a la perfección, necesitas tener instalados en tu sistema los siguientes componentes:

### 1. Dependencias del Sistema (Bash, cURL, GNU grep)
Los scripts que hacen el scraping de información requieren las siguientes herramientas de línea de comandos, que suelen venir preinstaladas en la mayoría de distribuciones Linux:
- `bash`
- `curl` (para realizar las peticiones HTTP)
- `grep` (requiere GNU grep con soporte para la bandera `-P` o Perl-compatible regex)
- `sed`, `tr`, `cut`, `head`

> **Nota para usuarios de macOS:** El comando `grep` en macOS (`BSD grep`) no soporta la bandera `-P`. Deberás instalar GNU grep a través de Homebrew (`brew install grep`) e invocarlo como `ggrep`, o bien actualizar los scripts para ser compatibles.

### 2. Python 3
Necesitas Python 3 instalado en tu máquina.

## Instalación y Configuración

Sigue estos pasos para arrancar el proyecto en tu entorno local:

### Paso 1: Clonar el repositorio y acceder a la carpeta
Desplázate al directorio del proyecto:
```bash
cd Hunter-PS
```

### Paso 2: Dar permisos de ejecución a los scrapers
Los scripts de Bash necesitan tener permisos de ejecución para que el backend (Flask) pueda llamarlos. Ejecuta:
```bash
chmod +x scraper*.sh
```

### Paso 3: (Opcional pero recomendado) Crear un entorno virtual
Para no mezclar las dependencias de este proyecto con tu sistema:
```bash
python3 -m venv venv
source venv/bin/activate  # En Linux/macOS
# En Windows: venv\Scripts\activate
```

### Paso 4: Instalar las dependencias de Python
El proyecto utiliza Flask y Flask-CORS. Instálalos mediante el archivo `requirements.txt`:
```bash
pip install -r requirements.txt
```
*(Si no tienes el archivo, puedes instalarlos manualmente ejecutando `pip install Flask flask-cors`)*.

### Paso 5: Ejecutar la aplicación
Inicia el servidor backend y la página web ejecutando:
```bash
python3 app.py
```

### Paso 6: Abrir en el navegador
Por defecto, la aplicación se ejecutará en:
[http://localhost:5000](http://localhost:5000)

Entra a esa URL en tu navegador de preferencia y ya podrás realizar búsquedas de forma simultánea en todas las plataformas soportadas.


## Solución de Problemas (Troubleshooting)
- **Error 500 al buscar:** Verifica que tienes permisos de ejecución en los scripts de bash (`chmod +x scraper.sh scraper2.sh scraper3.sh scraper4.sh`).
- **No se muestran resultados:** Es posible que alguna de las fuentes haya cambiado la estructura de su página web (HTML), por lo que las expresiones regulares de los scripts (`grep -oP`) podrían necesitar una actualización para coincidir con la nueva estructura.