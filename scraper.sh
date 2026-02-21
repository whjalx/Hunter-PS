#!/bin/bash
# ==============================================================================
# Script: scraper.sh (Fuente: Cuevana)
# Descripción: Scraper simple escrito en Bash para buscar películas o series.
# Retorna los resultados en formato JSON línea por línea.
# Dependencias necesarias: curl, grep, sed, tr, cut
# ==============================================================================

# 1. Validar argumentos
if [ -z "$1" ]; then
  echo "Uso: $0 <término de búsqueda>" >&2
  exit 1
fi

# 2. Configuración
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
TIMEOUT=10 # Segundos máximos para la petición HTTP

# Codificar espacios en la URL (básico)
query=$(echo "$1" | sed 's/ /%20/g')
url="https://cuevana.bi/explorar?s=$query"

# 3. Petición HTTP silenciosa, siguiendo redirecciones y con timeout
html=$(curl -s -L --max-time "$TIMEOUT" -A "$USER_AGENT" "$url" || echo "")

if [ -z "$html" ]; then
  # Salir limpiamente si cURL falla o devuelve vacío
  exit 0
fi

# 4. Parseo del HTML
# Extraemos cada bloque <div class="movie-item">...</div> y lo procesamos uno por uno
echo "$html" | tr '\n' ' ' | grep -oP '<div class="movie-item">.*?</a></div>' | while read -r block; do
  
  # Extraer campos mediante expresiones regulares Perl (PCRE)
  # Nos apoyamos en \K para hacer match solo en lo que sigue después
  href=$(echo "$block" | grep -oP 'href="?\K[^" >]+' | head -1)
  titulo=$(echo "$block" | grep -oP '<div class="item-detail">\s*<p>\K[^<]+' | head -1)
  imagen=$(echo "$block" | grep -oP '<img [^>]*src="?\K[^" >]+' | head -1)

  # Validar que al menos tengamos la URL y el Título
  if [ -n "$href" ] && [ -n "$titulo" ]; then
    
    # Limpiar cadenas para evitar romper el formato JSON
    titulo_escapado=$(echo "$titulo" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    
    # Completar URLs relativas si es necesario (con el nuevo dominio .bi)
    if [[ "$imagen" != http* ]] && [ -n "$imagen" ]; then
      imagen="https://cuevana.bi$imagen"
    fi
    if [[ "$href" != http* ]]; then
      href="https://cuevana.bi$href"
    fi

    # 5. Imprimir objeto JSON al stdout
    echo "{\"titulo\": \"$titulo_escapado\", \"url\": \"$href\", \"imagen\": \"$imagen\"},"
  fi
done
