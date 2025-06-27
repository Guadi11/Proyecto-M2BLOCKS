:- module(proylcc, 
	[  
		randomBlock/2,
		shoot/5	
	]).

:- use_module(library(clpfd)).  % incluye transpose/2


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


/*
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
    length(Grid, Len),
    Pos < Len,
    nth0(Pos, Grid, '-'), !,
    Indice = Pos.

buscarDesdeFila(Grid, Col, NumCols, Fila, NumFilas, Indice) :-
    Fila1 is Fila + 1,
    buscarDesdeFila(Grid, Col, NumCols, Fila1, NumFilas, Indice).



/*
% Busca desde la última fila hacia arriba el primer índice libre ('-')
buscarIndiceLibre(Grid, Col, NumCols, NumFilas, Indice) :-
    UltimaFila is NumFilas - 1,
    buscarDesdeFila(Grid, Col, NumCols, UltimaFila, Indice).

buscarDesdeFila(_, _, _, -1, _) :- !, fail.

buscarDesdeFila(Grid, Col, NumCols, Fila, Indice) :-
    Pos is Fila * NumCols + Col,
    nth0(Pos, Grid, '-'), !,
    Indice = Pos.

buscarDesdeFila(Grid, Col, NumCols, Fila, Indice) :-
    Fila1 is Fila - 1,
    buscarDesdeFila(Grid, Col, NumCols, Fila1, Indice).
*/

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

fusionar_bloques(B1, B2, B3, Resultado) :-
    Suma is B1 + B2 + B3,
    calcular_nuevo_bloque(Suma, Resultado).

calcular_nuevo_bloque(Suma, Nuevo) :-
    Nuevo is Suma. 
 
% filtrar_iguales(+Valor, +Lista[(Pos,Valor)], -SoloIguales)
filtrar_iguales(_, [], []).

filtrar_iguales(Valor, [(P,V)|T], [(P,V)|R]) :- %el primer elemento adyacente coincide con el bloque shooteado
    V = Valor, !,
    filtrar_iguales(Valor, T, R).

filtrar_iguales(Valor, [_|T], R) :-
    filtrar_iguales(Valor, T, R).

aplicar_fusion(Grid, Pos, Block, [], _, _, Grid, _).

aplicar_fusion(Grid, Pos, Block, [(P1,_)], NumCols, ValorFusionado, NuevoGrid, NuevaPos) :-
    ValorFusionado is Block + Block,
    reemplazarEnIndice(Grid, P1, '-', Grid1),
    reemplazarEnIndice(Grid1, Pos, ValorFusionado, Grid2),
    Subida is Pos - NumCols,
    (   Subida >= 0,  
        nth0(Subida, Grid2, '-')
    ->  reemplazarEnIndice(Grid2, Pos, '-', Grid3),

        reemplazarEnIndice(Grid3, Subida, ValorFusionado, NuevoGrid),
        NuevaPos is Subida
    ;   NuevoGrid = Grid2,
    NuevaPos is Pos
    ).

aplicar_fusion(Grid, Pos, Block, [(P1,_),(P2,_)], NumCols, ValorFusionado, NuevoGrid, NuevaPos) :-
    ValorFusionado is Block * 4,
    reemplazarEnIndice(Grid, P1, '-', G1),
    reemplazarEnIndice(G1, P2, '-', G2),
    reemplazarEnIndice(G2, Pos, ValorFusionado, G3),
    Subida is Pos - NumCols,
    (   Subida >= 0,
        nth0(Subida, G3, '-')
    ->  reemplazarEnIndice(G3, Pos, '-', G4),
        reemplazarEnIndice(G4, Subida, ValorFusionado, NuevoGrid),
        NuevaPos is Subida
    ;   NuevoGrid = G3,
    NuevaPos is Pos
    ).

aplicar_fusion(Grid, Pos, Block, [(P1,_),(P2,_),(P3,_)], NumCols, ValorFusionado, NuevoGrid, NuevaPos) :-

    ValorFusionado is Block * 8,
    reemplazarEnIndice(Grid, P1, '-', G1),
    reemplazarEnIndice(G1, P2, '-', G2),
    reemplazarEnIndice(G2, P3, '-', G3),
    reemplazarEnIndice(G3, Pos, ValorFusionado, G3),
    Subida is Pos - NumCols,
    (   Subida >= 0,
        nth0(Subida, G3, '-')
    ->  reemplazarEnIndice(G3, Pos, '-', G4),
        reemplazarEnIndice(G4, Subida, ValorFusionado, NuevoGrid),
        NuevaPos is Subida
    ;   NuevoGrid = G3,
       NuevaPos is Pos
    ).

% adyacentes(+Grid, +Pos, +NumCols, -Adyacentes)
adyacentes(Grid, Pos, NumCols, Adyacentes) :-
    length(Grid, Len),
    LeftIndex is Pos - 1,
    RightIndex is Pos + 1,
    UpIndex is Pos - NumCols,
    findall((Idx, Val), (
        (LeftIndex >= 0,
         Pos mod NumCols =\= 0, % no está en la primer columna
         nth0(LeftIndex, Grid, Val),
         Val \= '-', Idx = LeftIndex);
        (RightIndex < Len,
         (RightIndex) mod NumCols =\= 0, % no está en la última columna
         nth0(RightIndex, Grid, Val),
         Val \= '-', Idx = RightIndex);
        (UpIndex >= 0,
         nth0(UpIndex, Grid, Val),
         Val \= '-', Idx = UpIndex)
    ), Adyacentes).


efectos(Grid, Pos, Block, NumCols, NuevoGridFinal, NuevaPos2) :-
    adyacentes(Grid, Pos, NumCols, Adyacentes),
    filtrar_iguales(Block, Adyacentes, Iguales),
    aplicar_fusion(Grid, Pos, Block, Iguales, NumCols, ValorFusionado, GridFusionado, NuevaPos2),
    NuevoGridFinal = GridFusionado.

% Transforma grilla en columnas
grilla_a_columnas(Grid, NumCols, Columnas) :-
    length(Grid, Len),
    NumFilas is Len // NumCols,
    TopeCol is NumCols-1,
    TopeFila is NumFilas-1,
    findall(Columna, (
        between(0, TopeCol, Col),
        findall(Val, (
            between(0, TopeFila, Fila),
            Pos is Fila * NumCols + Col,
            nth0(Pos, Grid, Val)
        ), Columna)
    ), Columnas).


% Aplica gravedad a una columna (elimina '-', sube los valores)
gravedad_columna(Columna, ColumnaFinal) :-
    include(\=('-'), Columna, SoloValores),
    length(Columna, Len),
    length(SoloValores, Cant),
    R is Len - Cant,
    length(Relleno, R),
    maplist(=('-'), Relleno),
    append(SoloValores, Relleno, ColumnaFinal).

% Reconvierte columnas a grilla
columnas_a_grilla(Columnas, Grid) :-
    transpose(Columnas, FilasPorFila),
    flatten(FilasPorFila, Grid).

/*aplicar_gravedad(Grid, _, Grid).*/


aplicar_gravedad(Grid, NumCols, GridConGravedad) :-
    grilla_a_columnas(Grid, NumCols, Columnas),
    maplist(gravedad_columna, Columnas, NuevasColumnas),
    columnas_a_grilla(NuevasColumnas, GridConGravedad).

llamar_efectos_adyacentes(Grilla2, PosicionResultante, NumCols, GridFin):-
    nth0(IndexIzq, Grilla2, Block2),
    nth0(IndexDer, Grilla2, Block3),
    (
    Block2 \= '-'
    -> loop_efectos(Grilla2, IndexIzq, Block2, NumCols, GridInterm1)
    ;  GridInterm1 = Grilla2
    ),
    (
    Block3 \= '-'
    -> loop_efectos(GridInterm1, IndexDer, Block3, NumCols, GridFin)
    ;  GridFin = GridInterm1
    ).

    

loop_efectos(Grid, _, '-', _, Grid):-!.


loop_efectos(Grid, Pos, Block, NumCols, FinalGrid) :-
    efectos(Grid, Pos, Block, NumCols, Grid2, NuevaPos),
    (
        not(Grid = Grid2 )
    ->  (
        aplicar_gravedad(Grid2, NumCols, GridGravedad),
        nth0(NuevaPos, GridGravedad, NuevoValor),
        loop_efectos(GridGravedad, NuevaPos, NuevoValor, NumCols, FinalGrid)
        )
    ;   FinalGrid = Grid
    ).

recorrer_grilla_efectos(Grilla, _, Pos, Len, Grilla) :-
    Pos >= Len, !.  

recorrer_grilla_efectos(Grilla, NumCols, Pos, Len, Resultado) :-
    nth0(Pos, Grilla, Val),
    ( number(Val) ->
        loop_efectos(Grilla, Pos, Val, NumCols, GrillaIntermedia),
        GrillaIntermedia \= Grilla  % hubo cambio
    ->  recorrer_grilla_efectos(GrillaIntermedia, NumCols, 0, Len, Resultado)
    ;   Pos1 is Pos + 1,
        recorrer_grilla_efectos(Grilla, NumCols, Pos1, Len, Resultado)
    ).


recorrer_grilla_efectos(Grilla, _, Pos, Len, Grilla) :-
    Pos >= Len, !.  

chequear_efectos_general(Grid, _, Grid).

chequear_efectos_general(Grid, _, Grid).

chequear_efectos_general(Grilla, NumCols, GrillaFinal) :-
    chequear_efectos_general(Grilla, NumCols, GrillaFinal, 20).  % hasta 20 iteraciones

chequear_efectos_general(Grilla, _, Grilla, 0) :- !.  % caso base

chequear_efectos_general(Grilla, NumCols, GrillaFinal, Iter) :-
    length(Grilla, Len),
    recorrer_grilla_efectos(Grilla, NumCols, 0, Len, GrillaIntermedia),
    ( GrillaIntermedia \= Grilla ->
        Iter1 is Iter - 1,
        chequear_efectos_general(GrillaIntermedia, NumCols, GrillaFinal, Iter1)
    ;   GrillaFinal = Grilla
    ).


/*chequear_efectos_general(Grilla, NumCols, GrillaFinal) :-
    length(Grilla, Len),
    recorrer_grilla_efectos(Grilla, NumCols, 0, Len, GrillaFinal).*/

generar_grilla_vacia(NumFilas, GridVacia) :-
    NumCols = 5,  
    Tam is NumCols * NumFilas,
    length(GridVacia, Tam),
    maplist(=('-'), GridVacia).

/*% Se pierde si la fila superior está completamente llena (sin '-')*/
perdiste(Grid, NumCols) :-
    length(Grid, Len),
    NumFilas is Len // NumCols,
    NumColsLim is NumCols - 1,
    forall(
        between(0, NumColsLim, Col),
        \+ buscarIndiceLibre(Grid, Col, NumCols, NumFilas, _)
    ).

shoot(Block, Col, Grid, NumCols, [effect(GridFinal, [])]) :-
    ( perdiste(Grid, NumCols) ->
        generar_grilla_vacia(6, GridFinal)
    ;
        ColIndex is Col - 1,
        length(Grid, Len),
        NumFilas is Len // NumCols,
        buscarIndiceLibre(Grid, ColIndex, NumCols, NumFilas, Pos),
        reemplazarEnIndice(Grid, Pos, Block, GridInsertado),
        loop_efectos(GridInsertado, Pos, Block, NumCols, GridFusiones),
        chequear_efectos_general(GridFusiones, NumCols, GridFinal)
   ).    
