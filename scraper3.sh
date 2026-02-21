#!/bin/bash
# ==============================================================================
# Script: scraper3.sh (Fuente: Seriesflix)
# Descripción: Extrae información de series en la plataforma Seriesflix.
# Además de título y link, intenta extraer descripción.
# Retorna los resultados en formato JSON línea por línea.
# ==============================================================================

if [ -z "$1" ]; then
  echo "Uso: $0 <término de búsqueda>" >&2
  exit 1
fi

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
TIMEOUT=10

query=$(echo "$1" | sed 's/ /%20/g')
url="https://seriesflix.blue/?s=$query"

# Petición HTTP
html=$(curl -s -L --max-time "$TIMEOUT" -A "$USER_AGENT" "$url" || echo "")

if [ -z "$html" ]; then
  exit 0
fi

# Unificar líneas
html=$(echo "$html" | tr '\n' ' ')

# Extraer cada bloque individual
echo "$html" | grep -oP '<li class="TPostMv[^>]*>.*?</li>' | while read -r block; do
  href=$(echo "$block" | grep -oP 'href="[^"]+"' | head -1 | cut -d'"' -f2)
  titulo=$(echo "$block" | grep -oP '<h2 class="Title">[^<]+' | sed 's/.*>//')
  imagen=$(echo "$block" | grep -oP 'img[^>]+src="[^"]+"' | grep -oP 'src="[^"]+"' | cut -d'"' -f2)
  descripcion=$(echo "$block" | grep -oP '<div class="Description">.*?</div>' | sed -E 's/<[^>]+>//g' | tr -d '\n' | cut -c 1-400)

  if [ -n "$href" ] && [ -n "$titulo" ]; then
    
    # Completar URLs relativas
    if [[ "$href" != http* ]]; then
      href="https://seriesflix.blue$href"
    fi
    if [[ "$imagen" != http* ]] && [ -n "$imagen" ]; then
      imagen="https:$imagen"
    fi

    # Escapar campos de texto para integrarlo en JSON (" y \)
    titulo_escapado=$(echo "$titulo" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    descripcion_escapada=$(echo "$descripcion" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

    echo "{\"titulo\": \"$titulo_escapado\", \"url\": \"$href\", \"imagen\": \"$imagen\", \"descripcion\": \"$descripcion_escapada\"},"
  fi
done
