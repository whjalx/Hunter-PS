#!/bin/bash
# ==============================================================================
# Script: scraper2.sh (Fuente: PoseidonHD)
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
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36"
TIMEOUT=10

query=$(echo "$1" | sed 's/ /%20/g')
url="https://www.poseidonhd2.co/search?q=$query"

# 3. Petición HTTP silenciosa
html=$(curl -s -L --max-time "$TIMEOUT" -A "$USER_AGENT" "$url" || echo "")

if [ -z "$html" ]; then
  exit 0
fi

# 4. Parseo de HTML unificando líneas
html=$(echo "$html" | tr '\n' ' ')

# Extraer bloques de películas
echo "$html" | grep -oP '<li class="TPost.*?</li>' | while read -r block; do
  href=$(echo "$block" | grep -oP 'href="[^"]+"' | head -1 | cut -d'"' -f2)
  titulo=$(echo "$block" | grep -oP '<span class="Title[^>]*>[^<]+' | head -1 | sed 's/.*>//')
  imagen=$(echo "$block" | grep -oP '<img[^>]+src="[^"]+"' | grep -oP 'src="[^"]+"' | head -1 | cut -d'"' -f2)

  # Validar campos antes de continuar
  if [ -n "$href" ] && [ -n "$titulo" ]; then
    
    # Arreglar URLs relativas
    if [[ "$href" != http* ]]; then
      href="https://www.poseidonhd2.co$href"
    fi
    if [[ "$imagen" != http* ]] && [ -n "$imagen" ]; then
      imagen="https://www.poseidonhd2.co$imagen"
    fi

    # Escape básico para JSON seguro
    titulo_escapado=$(echo "$titulo" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    
    # 5. Salida JSON
    echo "{\"titulo\": \"$titulo_escapado\", \"url\": \"$href\", \"imagen\": \"$imagen\"},"
  fi
done
