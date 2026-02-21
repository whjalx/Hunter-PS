/**
 * Inicialización de elementos del DOM cuando el documento esté completo
 * para mayor seguridad y evitar múltiples consultas al document.
 */
document.addEventListener("DOMContentLoaded", () => {
  // Caché de selectores: evita consultas repetidas al DOM mejorando el rendimiento
  const btnSearch = document.querySelector("#btnSearch");
  const inputQuery = document.querySelector("#query");
  const containerMain = document.querySelector("#main");
  const elementLoader = document.querySelector("#loader");

  // URL base de la API
  const API_BASE_URL = "http://localhost:5000";

  /**
   * Función de utilidad para mostrar u ocultar el spinner de carga.
   * @param {boolean} show - Verdadero para mostrar, falso para ocultar.
   */
  const toggleLoader = (show) => {
    if (elementLoader) {
      elementLoader.style.display = show ? "block" : "none";
    }
  };

  /**
   * Muestra un mensaje de alerta en el contenedor principal usando las clases de Bootstrap.
   * @param {string} title - Título inicial del mensaje.
   * @param {string} text - Contenido del mensaje.
   * @param {string} type - Tipo de alerta según Bootstrap ('warning', 'danger', 'info').
   */
  const showMessage = (title, text, type = 'warning') => {
    containerMain.innerHTML = `
      <div class="alert alert-dismissible alert-${type} shadow-sm">
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        <h4 class="alert-heading text-capitalize">${title}</h4>
        <p class="mb-0">${text}</p>
      </div>`;
  };

  /**
   * Extrae la lógica para crear un elemento HTML para la tarjeta de película/serie.
   * @param {Object} item - Objeto con datos: titulo, imagen, fuente, descripcion, url.
   * @returns {HTMLElement} Devuelve el nodo DOM de la tarjeta ya construida.
   */
  const createCardElement = (item) => {
    const card = document.createElement("div");
    card.className = "card mb-3 shadow-sm"; // Añadido shadow para una estética ligera

    // Valor por defecto en caso de no venir descripción
    const descripcion = item.descripcion || "Sin descripción disponible por el momento.";

    // Estructura grid de bootstrap con una mejor jerarquía y ajustes móviles
    card.innerHTML = `
      <div class="row g-0">
        <div class="col-12 col-md-4 col-lg-3 text-center bg-light">
          <img src="${item.imagen}" alt="Portada de ${item.titulo}" 
               class="img-fluid rounded-start h-100" 
               style="max-height: 350px; object-fit: contain; width: 100%;">
        </div>
        <div class="col-12 col-md-8 col-lg-9">
          <div class="card-body d-flex flex-column h-100">
            <h5 class="card-title text-primary fw-bold">${item.titulo}</h5>
            <p class="card-text mb-2">
              <span class="badge bg-secondary">Fuente: ${item.fuente}</span>
            </p>
            <p class="card-text flex-grow-1">${descripcion}</p>
            <div class="mt-auto pt-3 border-top">
              <a href="${item.url}" target="_blank" rel="noopener noreferrer" class="btn btn-primary px-4">
                Ver contenido <i class="bi bi-box-arrow-up-right ms-2"></i>
              </a>
            </div>
          </div>
        </div>
      </div>
    `;
    return card;
  };

  /**
   * Función asíncrona dedicada a la búsqueda y procesamiento de información.
   * Usar async/await proporciona un código mucho más limpio que .then() chains.
   */
  const handleSearch = async () => {
    const queryTerm = inputQuery.value.trim();

    // Validación temprana
    if (!queryTerm) {
      showMessage("Oops..!", "Al parecer no has escrito nada para buscar.", "warning");
      return;
    }

    // Preparar interfaz de usuario: limpiar main y mostrar loader
    containerMain.innerHTML = "";
    containerMain.appendChild(elementLoader); // Vuelve a poner el loader si se había quitado
    toggleLoader(true);

    try {
      // Petición HTTP POST enviando la query
      const response = await fetch(`${API_BASE_URL}/buscar`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ nombre: queryTerm })
      });

      // Manejo de errores a nivel capa HTTP HTTP (500s, 400s)
      if (!response.ok) {
        throw new Error(`Error en el servidor: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();

      // Validación de datos vacíos
      if (!Array.isArray(data) || data.length === 0) {
        containerMain.innerHTML = `
          <div class="text-center mt-5 text-muted">
            <h5 class="fw-normal">No se encontraron resultados para <b>"${queryTerm}"</b>.</h5>
            <p>Intenta probar con otros nombres u otras variaciones.</p>
          </div>
        `;
        return;
      }

      // Limpiar contenedor antes de inyectar resultados (removés el loader de la pantalla)
      containerMain.innerHTML = "";

      // OPTIMIZACIÓN IMPORTANTE: 
      // Se crea un DocumentFragment para inyectar todas las tarjetas en memoria.
      // Esto previene que el navegador "redibuje" (reflow) el DOM por cada tarjeta agregada.
      const fragment = document.createDocumentFragment();
      data.forEach(item => {
        const cardNode = createCardElement(item);
        fragment.appendChild(cardNode);
      });

      // Finalmente inyectamos el fragmento que contiene todos los Nodos combinados, en una sola operación.
      containerMain.appendChild(fragment);

    } catch (error) {
      console.error("Excepción lanzada realizando la búsqueda:", error);
      showMessage("Ocurrió un error", "Hubo un problema comunicándose con el servidor para obtener los resultados.", "danger");
    } finally {
      // Sin importar el resultado, ocultamos el estado de carga
      toggleLoader(false);
    }
  };

  // Enlazar eventos
  if (btnSearch) {
    btnSearch.addEventListener("click", handleSearch);
  }

  // Evento extra: Permitir que los usuarios busquen si dan "Enter" sobre la caja de texto
  if (inputQuery) {
    inputQuery.addEventListener("keypress", (event) => {
      if (event.key === "Enter") {
        event.preventDefault(); // Evita recarga si estuviera dentro de un <form>
        handleSearch();
      }
    });
  }
});
