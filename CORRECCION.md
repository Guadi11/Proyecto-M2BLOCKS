### Nota: 90

### ⚙️ Funcionalidad

#### 📌 Generación aleatoria del bloque a disparar
- ✅ funciona correctamente.

#### 📌 Efecto del disparo de un bloque
- ✅ funciona correctamente.

#### 📌 Avisos “Combo x N”
- ✅ funciona correctamente.

#### 📌 Avisos de nuevo bloque máximo logrado.
- ✅ funciona correctamente.

#### 📌 Limpieza de bloques retirados.
- ✅ funciona correctamente.


#### 📌 Booster Hint jugada
- ✅ funciona correctamente.

#### 📌 Booster Bloque siguiente.
- ✅ funciona correctamente.

#### 🚀 Extras
- ➕ fin del juego, reinicio, y recuerdo del mejor puntaje de juegos anteriores.


### 📚 Documentación
- ➖ La sección [Generación de Bloques](/docs/informelogica.md#generación-de-bloques) no explica **cómo** se implementó el requerimiento. ¿Cómo se calcularon los rangos, especialmente para valores más allá de los especificados en la tabla del enunciado?
- ➖ La sección [Fusión de Bloques](/docs/informelogica.md#fusión-de-bloques) describe el efecto de la fusión del bloque disparado,
que es como funciona el juego, y por lo tanto infromación sabida. La intención del informe es explicar, a alto nivel, **cómo** se consiguió / implementó dicho
comportamiento, y no tanto **qué** es lo que hace el juego.
- ➖ Algo similar ocurre con la sección [Reacciones en Cadena y Combos](/docs/informelogica.md#reacciones-en-cadena-y-combos), donde lo único que se explica de
la estrategia de resolución es que *está implementada en forma recursiva*. Sobre esa parte, el informe dice:
    > cada vez que ocurre una fusión, se verifica si el nuevo bloque generado puede a su vez fusionarse con sus nuevos adyacentes.
    
    ¿Cómo se capturan los casos donde se originan grupos de bloques adyacentes consecuencia del efecto de gravedad invertida, y que no involucran al bloque nuevo generado? Por ejemplo, disparando un `4` en la columna 3 en la siguiente grilla, ¿como se detecta y resuelve el merge de los `8`s?
    
    ```
    init([
	8,4,-,4,-,
	-,8,-,-,-,
	-,-,-,-,-,
	-,-,-,-,-,
	-,-,-,-,-,
	-,-,-,-,-,
	-,-,-,-,-
    ], 5).
    ```
- ✅ el resto de los aspectos de la implementación están bien documentados.
- ✅ se incluyen casos de test.