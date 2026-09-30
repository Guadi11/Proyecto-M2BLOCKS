# Proyecto: M2 Blocks - Comisión 16

## Descripción
El *M2 Blocks* (o *Merge 2 Blocks*) es un juego de puzzle y estrategia cuyo objetivo es lanzar y combinar bloques numerados para crear bloques de mayor valor y ganar puntos. Este proyecto fue desarrollado para la materia Lógica para Ciencias de la Computación (2025) por Guadalupe Nayla Elia y Maitena Cortes Ferber.

## Arquitectura y Tecnologías
El proyecto utiliza una arquitectura separada donde la lógica central del juego corre en un servidor Prolog y la interfaz gráfica interactiva está construida con React. Esta separación permite que la interfaz sea flexible y clara sin necesidad de duplicar las reglas del juego en el código frontend.

### Motor Lógico (Prolog)
* **Representación:** La grilla de juego se modela como una lista lineal que representa un tablero bidimensional de 5 columnas.
* **Generación y Gravedad:** La generación de nuevos bloques es dinámica y el rango de números se actualiza según el bloque máximo presente en la partida. Al insertar un bloque, este cae simulando una gravedad invertida hacia la primera celda libre de la columna elegida.
* **Fusiones y Combos en Cadena:** Si un bloque coincide con sus vecinos adyacentes, se fusionan multiplicando su valor (duplicando, cuadruplicando o multiplicando por ocho). Estas fusiones reacomodan la grilla aplicando gravedad nuevamente, lo que permite generar reacciones en cadena y combos calculados de forma recursiva.
* **Fin de Juego:** La partida termina cuando todas las columnas están llenas y no es posible insertar nuevos bloques.

### Interfaz Visual (React)
* **Gestión de Estado:** La clase principal `Game` coordina la interacción manteniendo el estado de la grilla, el bloque activo, los objetivos y el puntaje máximo histórico.
* **Comunicación Asincrónica:** Utiliza `PengineClient` para enviar las acciones del usuario (columna seleccionada y bloque) como consultas a Prolog y recibir los efectos resultantes.
* **Animaciones:** En lugar de mostrar el resultado de golpe, React reproduce los efectos de caída, fusión y reacomodamiento paso a paso mediante retardos breves para una comprensión visual clara de la jugada

## Funcionalidades Especiales y Boosters
* **Booster de Pistas (Hint):** Al activarse, simula una jugada completa de forma invisible en Prolog y muestra debajo de cada columna qué fusiones o combos se generarían, funcionando como una guía inteligente.
* **Booster Siguiente Bloque:** Permite visualizar el próximo bloque a disparar durante un tiempo límite de 10 segundos antes de volver a ocultarse.
* **Progresión de Objetivos:** Al alcanzar nuevos hitos (ej. bloque de 512 o 1024), el juego notifica al jugador, limpia los bloques menores que ya no se generarán, añade bloques de bonificación y duplica la meta de la siguiente etapa.

## Instalación y Ejecución Local

### 1. Servidor Prolog (Backend)
1. Descargar e instalar SWI-Prolog.
2. Navegar a la carpeta `pengines_server` y levantar el servidor ejecutando `swipl run.pl`.
3. El servidor escuchará en `http://localhost:3030` (durante la primera ejecución se pedirá definir un usuario y contraseña para la consola web admin).

### 2. Cliente React (Frontend)
1. Descargar una versión reciente de Node.js.
2. Navegar al directorio del proyecto `proyecto-m2blocks-com-16` y ejecutar `npm install` para instalar todas las dependencias locales en `node_modules`.
3. Ejecutar `npm start` para correr la aplicación en modo desarrollo.
4. Abrir `http://localhost:3000` en el navegador para comenzar a jugar.

## Notas de Rendimiento y Estado
* Frente a cadenas de combos excesivamente grandes o reacomodamientos complejos, la aplicación puede presentar una demora de unos segundos en la actualización visual de la grilla y el puntaje.
* Existe un detalle visual documentado donde ciertos bloques avanzados (como 512 y 1024) pueden renderizarse con colores múltiples a pesar de su configuración base.
