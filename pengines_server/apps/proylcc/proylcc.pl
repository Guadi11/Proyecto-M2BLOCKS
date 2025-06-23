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
/*

subir_columnas(Grid, NumCols, NuevoGridFinal) :-
    length(Grid, Len),
    NumFilas is Len 
    subir_columnas_aux(Grid, NumCols, NumFilas, 0, NuevoGridFinal).



% subir_columnas(+Grid, +NumCols, -NuevoGrid)
subir_columnas(Grid, NumCols, NuevoGridFinal) :-
    length(Grid, Len),
    NumFilas is Len 
    subir_columnas_aux(Grid, NumCols, NumFilas, 0, NuevoGridFinal).


   subir_columnas_aux(Grid, NumCols, NumFilas, Col, Grid) :-
    Col >= NumCols, !.  % fin de columnas, no se modifica más.

subir_columnas_aux(Grid, NumCols, NumFilas, Col, GridFinal) :-
    subir_en_columna(Grid, Col, NumFilas, NumCols, GridParcial),
    ColSig is Col + 1,
    subir_columnas_aux(GridParcial, NumCols, NumFilas, ColSig, GridFinal).

% subir_en_columna(+Grid, +Col, +NumFilas, +NumCols, -NuevoGrid)
subir_en_columna(Grid, Col, NumFilas, NumCols, NuevoGrid) :-
    subir_en_columna_aux(Grid, Col, NumFilas, NumCols, 0, NuevoGrid).

% subir_en_columna_aux(+Grid, +Col, +NumFilas, +NumCols, +Fila, -GridFinal)
subir_en_columna_aux(Grid, _, NumFilas, _, Fila, Grid) :-
    Fila >= NumFilas - 1, !.  % fin de filas.

subir_en_columna_aux(Grid, Col, NumFilas, NumCols, Fila, GridFinal) :-
    Index is Fila * NumCols + Col,
    Debajo is Index + NumCols,
    nth0(Index, Grid, '-'),
    nth0(Debajo, Grid, Valor),
    Valor \= '-',
    reemplazarEnIndice(Grid, Index, Valor, GridTemp),
    reemplazarEnIndice(GridTemp, Debajo, '-', GridSubido),
    FilaSig is Fila + 1,
    subir_en_columna_aux(GridSubido, Col, NumFilas, NumCols, FilaSig, GridFinal), !.

subir_en_columna_aux(Grid, Col, NumFilas, NumCols, Fila, GridFinal) :-
    FilaSig is Fila + 1,
    subir_en_columna_aux(Grid, Col, NumFilas, NumCols, FilaSig, GridFinal).
*/


aplicar_fusion(Grid, Pos, Block, [], _, _, Grid, _).

aplicar_fusion(Grid, Pos, Block, [(P1,_)], NumCols, ValorFusionado, NuevoGrid, NuevaPos) :-
    ValorFusionado is Block + Block,
    reemplazarEnIndice(Grid, P1, '-', Grid1),
    reemplazarEnIndice(Grid1, Pos, ValorFusionado, Grid2),
    Subida is Pos - NumCols,
    (   Subida >= 0,  %hubo combinacion con bloque superior y tengo q ascender el nuevo creado
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
         Val \= '-', Idx = RightIndex); %valida que haya un bloque y no este vacío
        (UpIndex >= 0,
         nth0(UpIndex, Grid, Val),
         Val \= '-', Idx = UpIndex)
    ), Adyacentes).


efectos(Grid, Pos, Block, NumCols, NuevoGridFinal, NuevaPos2) :-
    adyacentes(Grid, Pos, NumCols, Adyacentes),
    filtrar_iguales(Block, Adyacentes, Iguales),
    aplicar_fusion(Grid, Pos, Block, Iguales, NumCols, ValorFusionado, GridFusionado, NuevaPos2),
    NuevoGridFinal = GridFusionado.


% loop_efectos(+GridActual, +Pos, +Valor, +NumCols, -GridFinal)
loop_efectos(Grid, Pos, Block, NumCols, FinalGrid) :-
    efectos(Grid, Pos, Block, NumCols, Grid2, NuevaPos),
    (
        not(Grid = Grid2)  % usamos =/2 (igualdad lógica) en lugar de ==
    ->  nth0(NuevaPos, Grid2, NuevoValor),
        loop_efectos(Grid2, NuevaPos, NuevoValor, NumCols, FinalGrid)
    ;   FinalGrid = Grid
    ).


shoot(Block, Col, Grid, NumCols, [effect(GridFinal, [])]) :-
 ColIndex is Col - 1,
    length(Grid, Len),
    NumFilas is Len // NumCols,
    buscarIndiceLibre(Grid, ColIndex, NumCols, NumFilas, Pos),
    reemplazarEnIndice(Grid, Pos, Block, NuevoGrid),
    loop_efectos(NuevoGrid, Pos, Block, NumCols, GridFinal).



