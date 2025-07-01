# **Informe de la Resolución del Proyecto**
 M2 Blocks - Lógica para Ciencias de la Computación - 2025
# **Comisión [`16´]:**
[Cortes Ferber Maitena]
[Elia Guadalupe Nayla]


A continuación se dará un informe sobre el desarrollo del juego M2Blocks, cuya implementación fue realizada con el lenguaje Prolog para la parte lógica, y con React para la parte visual.

# **PROLOG – PARTE LÓGICA**

**Representación de la Grilla**

La grilla de juego se modela como una lista lineal que representa un tablero bidimensional. Cada posición de esta lista puede contener un número (que representa un bloque con valor) o un guión “-“ (que representa un espacio vacío).  
Para trabajar con esta estructura, se calcula la posición real dentro de la lista a partir de la fila y columna seleccionadas, tomando en cuenta la cantidad de columnas del tablero que en este caso son 5\.

# **Generación de Bloques**

La generación de nuevos bloques está determinada dinámicamente por el valor máximo presente en la grilla. A medida que se avanza en el juego y aparecen bloques de mayor valor, el conjunto de posibles bloques que pueden generarse se actualiza.

Para esa actualización utilizamos una lógica escalonada: primero se consideran bloques básicos (como 2 y 4\) y, cuando aparecen bloques más grandes, se amplía el rango de valores posibles incluyendo nuevas potencias de 2\.

# **Inserción de Bloques**

Cuando se inserta un bloque en la grilla, este se “dispara” a una columna específica. El nuevo bloque cae hasta la primera celda libre disponible en esa columna, simulando la gravedad invertida. La forma de encontrar la posición del bloque en la columna seleccionada es buscando el primer lugar vacío de la misma, desde arriba hacia abajo. Si la columna está llena, la jugada se considera inválida y no se realiza ningún cambio.  
![Muestra Insercion](docs\images\image1.jpg)

# **Fusión de Bloques**

Una vez que un bloque cae en su posición final, se verifica si puede fusionarse con bloques adyacentes. Para que una fusión sea válida, los bloques vecinos deben tener el mismo valor que el bloque insertado, y deben encontrarse en una de las tres direcciones consideradas: izquierda, derecha o arriba. La cantidad de bloques con los que se produce una fusión determina el resultado:

 * Si hay un solo bloque igual, el valor se duplica.

 * Con dos bloques, se cuadruplica.

 * Con tres bloques, se multiplica por ocho.
![Fusion1](docs\images\image2.jpg)              ![Fusion2](docs\images\image3.jpg)
Estas fusiones eliminan los bloques involucrados y colocan el resultado en la posición donde cayó el bloque original. Si hay espacio arriba, el nuevo bloque “sube” una fila, manteniendo la idea visual de una reacción en cadena.

# **Reacciones en Cadena y Combos**

Tras una fusión, se aplica nuevamente la gravedad para que los bloques restantes caigan a ocupar los espacios libres cuando sea necesario. Esto puede provocar nuevas fusiones, generando así efectos en cadena. Esta dinámica está implementada de forma recursiva: cada vez que ocurre una fusión, se verifica si el nuevo bloque generado puede a su vez fusionarse con sus nuevos adyacentes. Cada fusión dentro de una misma jugada incrementa un contador de “combo”, que otorga bonificaciones visuales al mostrar la cantidad de bloques fusionados.  
	

![Grilla Antes de Cadena](docs\images\image4.png)             ![Grilla Despues Cadena](docs\images\image5.png)

# **Aplicación de Gravedad**

La gravedad en el juego se simula reordenando los elementos en cada columna. Los bloques válidos (con valor) suben hasta ocupar todas las primeras posiciones, y las posiciones donde no hay bloques “bajan” dejando espacio libre para disparar de nuevo.

![Antes Gravedad](docs\images\image6.png)  ![Merge](docs\images\image7.png) ![Gravedad y Merge](docs\images\image8.png)

# **Mecanismo de Fin de Juego**

El juego detecta su finalización cuando ya no se puede insertar ningún bloque en ninguna de las columnas. Esto se determina revisando si cada columna tiene al menos una celda vacía disponible. Si todas están llenas, el sistema genera una grilla vacía y marca que el jugador ha perdido, reiniciando el puntaje a 0 y, en el caso de que el puntaje obtenido en esa partida sea el primero o el mejor de todos, se guardará como mejor puntaje y se mostrará en pantalla hasta que sea superado.

![cartel Perdiste](docs\images\image9.png)    ![Reinicio](docs\images\image10.png)



# **Simulación de Jugadas (Booster de Pistas)**

Para ofrecer ayuda al jugador sin afectar el estado del juego, se puede utiliza una simulación de una jugada completa sobre una copia de la grilla (todo esto sin que lo vea el jugador). A partir de esta simulación, el sistema informa si dicha jugada generaría una fusión relevante o un combo, permitiendo así sugerencias inteligentes. Además, a la derecha del bloque a disparar se encuentra la posibilidad de visualizar cual va a ser el próximo bloque a disparar, lo que también beneficia al jugador en la planificación de su jugada.

![Booster Pistas Activado](docs\images\image11.png)

# **REACT – PARTE VISUAL/FUNCIONAL**	

### **Gestión del Estado del Juego**

La clase Game es el componente principal de React que coordina toda la interacción entre el jugador, la grilla visual y el motor lógico (Prolog). Internamente, mantiene múltiples estados (useState) que permiten representar visualmente:

* La grilla actual del juego

* El bloque activo que se va a disparar

* El siguiente bloque (visible si hay booster activado).

* El puntaje actual y el mejor puntaje histórico.

* El objetivo actual (inicia en 512 y se duplica progresivamente). 



# Indicadores visuales: 
cartel de inicio, cartel de derrota, mensajes de objetivo alcanzado, combo, booster de pista activo, etc. 

Esta estructura permite que cada cambio en la lógica se vea reflejado inmediatamente en la interfaz, sin manejar directamente reglas del juego.



### **Comunicación con el Motor Lógico**

La interfaz se comunica con Prolog utilizando PengineClient, que permite enviar consultas (ask) y recibir respuestas asincrónicas.

Cada vez que el jugador realiza una acción (como lanzar un bloque o activar un booster), se envía una consulta a Prolog que incluye:

* El valor del bloque actual

* La columna seleccionada.

* El estado actual de la grilla.

Prolog responde con una lista de efectos, que representan los pasos visuales de lo que ocurrió durante la jugada (caída del bloque, fusiones, combos, etc.).

# **Animaciones y Transición de Efectos**

En lugar de mostrar directamente el resultado final de la jugada, React reproduce efecto por efecto. Cada uno de estos pasos se muestra en pantalla con un retardo breve entre ellos, generando una animación clara y comprensible del proceso.

# Esto incluye:

* Caída del bloque a su posición.

* Fusión con vecinos adyacentes

* Formación de nuevos bloques con mayor valor.

* Movimiento de bloques tras aplicar la gravedad.

* Resaltado de combos (visual o numérico). 

Este sistema no solo mejora la comprensión de lo que ocurre, sino que refuerza la sensación de progresión y estrategia.

# 

# **Activación de Boosters**

# Booster: Ver Siguiente Bloque

El jugador puede activar un booster para visualizar el siguiente bloque durante 10 segundos. Luego de ese tiempo, el bloque vuelve a ocultarse con un signo de interrogación (?).

Esto se controla mediante un estado temporizado en React, sin afectar la lógica de Prolog.
![Booster Bloque Desactivado] (docs\images\image12.png)

![Booster Bloque Activado] (docs\images\image13.png)

# Booster: Pistas (Hint)

Cuando se activa, se simula (en paralelo) qué ocurriría si el bloque actual fuera lanzado en cada una de las columnas.

La clase Game coordina:

* El envío de una consulta especial a Prolog para cada columna.

* La recepción de los resultados, que contienen posibles fusiones o combos esperados.

* La visualización de indicadores debajo de cada columna, como guía inteligente. 

Todo esto se realiza sin alterar la grilla real del juego, permitiendo sugerencias eficientes y confiables.

# **Mecanismo de Objetivos**

Cada vez que se alcanza un nuevo objetivo (por ejemplo, formar un bloque 512 o 1024), la clase Game ejecuta una secuencia de eventos:

* Se muestra una notificación con el logro alcanzado.

* Se solicita a Prolog una limpieza del tablero, eliminando bloques pequeños.

* Se añade un bloque de bonificación de valor medio (ej. 128\) en una posición aleatoria.

* Se duplica el objetivo para la siguiente etapa (1024, 2048…).

* Estos cambios son visualizados de manera animada y permiten al jugador avanzar con mayor comodidad.

# 

# **Finalidad de la Separación Lógica \- Visual**

La estructura de este frontend busca no duplicar reglas de juego, sino actuar como intérprete visual del motor lógico. Gracias a esta separación:

* La lógica se mantiene consistente y validada en un solo lugar (Prolog).

* La interfaz es flexible, clara y fácilmente modificable sin afectar reglas.

* Se facilita el testing, mantenimiento y extensión del juego.

# 
