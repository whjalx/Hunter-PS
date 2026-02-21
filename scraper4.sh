#!/bin/bash
# ==============================================================================
# Script: scraper4.sh (Fuente: Katanime)
# Descripción: Scraper de anime que extrae título, enlace, imagen, año y tipo.
# Retorna los resultados en formato JSON línea por línea.
# ==============================================================================

if [ -z "$1" ]; then
  echo "Uso: $0 <término de búsqueda>" >&2
  exit 1
fi

query=$(echo "$1" | sed 's/ /%20/g')
base="https://katanime.net"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
TIMEOUT=10

# 1. Petición HTTP
html=$(curl -s -L --max-time "$TIMEOUT" -A "$USER_AGENT" "$base/buscar?q=$query" || echo "")

if [ -z "$html" ]; then
  exit 0
fi

# 2. Parseo HTML mediante regex (Punto de inicio/fin de cada tarjeta)
echo "$html" | tr '\n' ' ' | grep -oP '(?<=<div class="_135yj _2FQAt full _2mJki">).*?(?=<div class="_135yj _2FQAt full _2mJki">|$)' | while read -r block; do
  
  # URL
  url=$(echo "$block" | grep -oP 'href="\K[^"]+' | head -1)
  if [[ ! $url =~ ^https?:// ]] && [ -n "$url" ]; then
    url="$base$url"
  fi

  # Imagen
  img=$(echo "$block" | grep -oP '<img src="\K[^"]+')

  # Título
  title=$(echo "$block" | grep -oP '<div class="_2NNxg">.*?<a[^>]*>([^<]+)</a>' | sed -E 's/.*<a[^>]*>([^<]+)<\/a>.*/\1/')

  # Año
  year=$(echo "$block" | grep -oP '<div class="_2y8kd">\s*\K[0-9]{4}')

  # Tipo (Anime TV, OVA, etc.)
  type=$(echo "$block" | grep -oP '<span class="_2y8kd etag tag[0-9]+">\K[^<]+')

  if [ -n "$title" ] && [ -n "$url" ]; then
    # Limpieza básica para evitar formato JSON inválido
    title_escapado=$(echo "$title" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    
    echo "{\"titulo\":\"$title_escapado\",\"url\":\"$url\",\"imagen\":\"$img\",\"year\":\"$year\",\"type\":\"$type\"},"
  fi
done
