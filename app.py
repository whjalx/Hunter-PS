import json
import logging
import subprocess
from typing import Any, Dict, List, Optional, Tuple, Union

from flask import Flask, jsonify, render_template, request, Response
from flask_cors import CORS

# Configurar logging para documentar errores importantes sin detener la app
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Inicializar la aplicación Flask
app = Flask(__name__, static_folder='static', template_folder='templates')
CORS(app)

# Diccionario que mapea nombres de fuentes a sus respectivos scripts
SCRIPTS: Dict[str, str] = {
    "Cuevana": "./scraper.sh",
    "Poseidon": "./scraper2.sh",
    "Seriesflix": "./scraper3.sh",
    "Katanime": "./scraper4.sh"
}

@app.route("/")
def index() -> str:
    """
    Ruta principal de la aplicación.
    
    Renderiza y devuelve el archivo HTML del frontend.
    
    Returns:
        str: El contenido HTML renderizado de index.html.
    """
    return render_template("index.html")

@app.route("/buscar", methods=["POST"])
def buscar() -> Union[Tuple[Response, int], Response]:
    """
    Endpoint para buscar películas o series en múltiples fuentes.
    
    Espera una petición POST con un JSON que contenga la clave 'nombre'.
    Ejecuta cada uno de los scripts bash y devuelve los resultados 
    ordenados según qué tan cerca estén del término buscado.
    
    Returns:
        Response: Un JSON con la lista de resultados, o un mensaje de error
                  con su respectivo código de estado HTTP 400.
    """
    # Intentar obtener el cuerpo JSON de forma segura
    data: Optional[Dict[str, Any]] = request.get_json(silent=True)
    
    if not data:
        return jsonify({"error": "No se proporcionó un JSON válido en la petición"}), 400

    nombre: str = data.get("nombre", "").strip()

    if not nombre:
        return jsonify({"error": "El campo 'nombre' está vacío o no se proporcionó"}), 400

    resultados: List[Dict[str, Any]] = []

    # Consultar a través de las distintas fuentes mediante subprocesos
    for fuente, script in SCRIPTS.items():
        try:
            # Ejecutar script (stderr a DEVNULL evita imprimir errores del bash en consola principal)
            result: str = subprocess.check_output(
                [script, nombre],
                universal_newlines=True,
                stderr=subprocess.DEVNULL
            )
            
            # Procesar el output por líneas
            lines: List[str] = result.strip().split("\n")
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                try:
                    # Fallback de limpieza extra: quitar comas al final de un JSON por mala sintaxis
                    obj: Dict[str, Any] = json.loads(line.rstrip(","))
                    obj["fuente"] = fuente
                    resultados.append(obj)
                except json.JSONDecodeError as e:
                    logging.warning(f"Error decodificando la línea JSON de {fuente}: {e}")
                    
        except subprocess.CalledProcessError as e:
            logging.error(f"Fallo ejecutando {script} ({fuente}) con código: {e.returncode}")
        except FileNotFoundError:
            logging.error(f"No se encontró el archivo ejecutable: {script}")
        except Exception as e:
            logging.error(f"Error inesperado procesando la fuente {fuente}: {e}")

    # Función auxiliar para puntuar los resultados
    def score(item: Dict[str, Any]) -> float:
        """
        Calcula qué tan exacto es un resultado. Relación (0.0=Mejor, 1.0=Peor).
        Prioriza los títulos que contengan la búsqueda exacta.
        """
        titulo: str = item.get("titulo", "").lower()
        termino: str = nombre.lower()
        
        # 0.0 si contiene término, 1.0 si no lo contiene
        contiene_termino: float = 0.0 if termino in titulo else 1.0
        
        # Penaliza diferencias de longitud del título
        diferencia_longitud: float = abs(len(titulo) - len(nombre)) * 0.01
        
        return contiene_termino + diferencia_longitud

    # Ordenar los resultados (menor puntuación primero)
    resultados.sort(key=score)

    return jsonify(resultados)

if __name__ == "__main__":
    app.run(debug=True)
