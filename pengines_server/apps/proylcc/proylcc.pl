:- module(proylcc, 
	[  
		randomBlock/2,
		shoot/5	
	]).

/**
 * randomBlock(+Grid, -Block)
 */
randomBlock(Grid, Block) :-
    maximo_bloque(Grid, Max),
    obtener_rango(Max, Rango),
    random_member(Block, Rango).

 maximo_bloque(Grid, Max) :-
    include(number, Grid, Numeros),
    (   Numeros = [] -> Max = 2
    ;   max_list(Numeros, Max)
    ).

    % parte de bloques randomBlock
obtener_rango(2, [2,4]):-!.
obtener_rango(4, [2,4]):-!.
obtener_rango(8, [2,4]):-!.
obtener_rango(16, [2,4,8]):-!.
obtener_rango(32, [2,4,8,16]):-!.
obtener_rango(64, [2,4,8,16,32]):-!.
obtener_rango(128, [2,4,8,16,32,64]):-!.
obtener_rango(256, [2,4,8,16,32,64]):-!.
obtener_rango(512, [2,4,8,16,32,64]):-!.
obtener_rango(_, [2,4]).  % caso por si la grilla esta vacia 


/**
 * shoot(+Block, +Column, +Grid, +NumOfColumns, -Effects) 
 * RGrids es la lista de grillas representando el efecto, en etapas, de combinar las celdas del camino Path
 * en la grilla Grid, con número de columnas NumOfColumns. El número 0 representa que la celda está vacía. 
 */

% filaColumnaPosicion(+Fila, +Col, +NumCol, -Pos)
filaColumnaPosicion(Fila, Col, NumCol, Pos) :-
    Pos is Fila * NumCol + Col.


% Busca desde la primera fila hacia abajo el primer índice libre ('-')
buscarIndiceLibre(Grid, Col, NumCols, NumFilas, Indice) :-
    buscarDesdeFila(Grid, Col, NumCols, 0, NumFilas, Indice).

% Versión corregida para buscar de arriba hacia abajo
buscarDesdeFila(_, _, _, Fila, NumFilas, _) :-
    Fila >= NumFilas, !, fail.

buscarDesdeFila(Grid, Col, NumCols, Fila, NumFilas, Indice) :-
    Pos is Fila * NumCols + Col,
    nth0(Pos, Grid, '-'), !,
    Indice = Pos.

buscarDesdeFila(Grid, Col, NumCols, Fila, NumFilas, Indice) :-
    Fila1 is Fila + 1,
    buscarDesdeFila(Grid, Col, NumCols, Fila1, NumFilas, Indice).

insertarBloque(Bloque, Col, Grid, NumCols, NuevoGrid) :-
    length(Grid, Len),
    NumFilas is Len // NumCols,
    buscarIndiceLibre(Grid, Col, NumCols, NumFilas, IndiceLibre),
    reemplazarEnIndice(Grid, IndiceLibre, Bloque, NuevoGrid).

% reemplaza el elemento en la posición Index por X
reemplazarEnIndice(Grid, Index, X, NuevoGrid) :-
    same_length(Grid, NuevoGrid),
    reemplazarEnIndiceAux(Grid, Index, X, NuevoGrid, 0).

reemplazarEnIndiceAux([], _, _, [], _).
reemplazarEnIndiceAux([_|T], Index, X, [X|T], Index).
reemplazarEnIndiceAux([H|T], Index, X, [H|T2], N) :-
    N \= Index,
    N1 is N + 1,
    reemplazarEnIndiceAux(T, Index, X, T2, N1).


shoot(Block, Col, Grid, NumCols, [effect(NuevoGrid, [])]) :-
 ColIndex is Col - 1,
    length(Grid, Len),
    NumFilas is Len // NumCols,
    buscarIndiceLibre(Grid, ColIndex, NumCols, NumFilas, Pos),
    reemplazarEnIndice(Grid, Pos, Block, NuevoGrid).








