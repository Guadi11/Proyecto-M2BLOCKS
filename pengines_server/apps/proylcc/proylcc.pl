:- module(proylcc, 
	[  
		randomBlock/2,
		shoot/5,
        simulate_shoot/5,  % Predicado exportado para el booster de pistas
        cleanup_grid/4
	]).
:- dynamic combo/2.
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


% Casos base para valores de Max hasta 512 
obtener_rango(Max, [2,4]) :- Max =< 8, !.
obtener_rango(16, [2,4,8]) :- !.
obtener_rango(32, [2,4,8,16]) :- !.
obtener_rango(64, [2,4,8,16,32]) :- !.
obtener_rango(Max, [2,4,8,16,32,64]) :- Max >= 128, Max =< 512, !.

% Caso general recursivo para Max >= 1024
obtener_rango(Max, Rango) :-
    Max >= 1024, !,
    %    Empezamos desde el primer caso conocido: Max_Umbral=1024, Min_Rango=4, Max_Rango=128.
    calcular_limites_rango(Max, 1024, 4, 128, MinFinal, MaxRangoFinal),
    
    % 2. Generamos la lista de potencias de 2 con los límites calculados.
    generar_potencias(MinFinal, MaxRangoFinal, Rango).

% Caso por defecto si la grilla está vacía
obtener_rango(_, [2,4]).

/**
 * calcular_limites_rango(+MaxGrilla, +MaxUmbral, +MinActual, +MaxActual, -MinFinal, -MaxRangoFinal)
 *
 * Calcula recursivamente los límites del rango. Si MaxGrilla es mayor que el doble
 * del umbral actual, se llama a sí mismo con todos los valores duplicados.
 */
% Caso base: El Max de la grilla ya no supera el siguiente umbral. Los límites actuales son los correctos.
calcular_limites_rango(MaxGrilla, MaxUmbral, MinActual, MaxActual, MinActual, MaxActual) :-
    MaxGrilla < MaxUmbral * 2, !.

% Paso recursivo: El Max de la grilla es muy grande, probamos con el siguiente nivel de rangos.
calcular_limites_rango(MaxGrilla, MaxUmbral, MinActual, MaxActual, MinFinal, MaxRangoFinal) :-
    NuevoUmbral is MaxUmbral * 2,
    NuevoMin is MinActual * 2,
    NuevoMax is MaxActual * 2,
    calcular_limites_rango(MaxGrilla, NuevoUmbral, NuevoMin, NuevoMax, MinFinal, MaxRangoFinal).


/**
 * generar_potencias(+Desde, +Hasta, -Lista)
 *
 * Genera una lista de potencias de 2, comenzando en 'Desde' y terminando
 * cuando se supera 'Hasta'.
 */
% Caso base: El número actual ('Desde') ya es mayor que el límite. Terminamos con una lista vacía.
generar_potencias(Desde, Hasta, []) :-
    Desde > Hasta, !.

% Paso recursivo: Añade el número actual a la lista y llama con el doble de su valor.
generar_potencias(Desde, Hasta, [Desde | Resto]) :-
    Siguiente is Desde * 2,
    generar_potencias(Siguiente, Hasta, Resto).


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

filtrar_iguales(Valor, [(P,V)|T], [(P,V)|R]) :- 
    V = Valor, !,
    filtrar_iguales(Valor, T, R).

filtrar_iguales(Valor, [_|T], R) :-
    filtrar_iguales(Valor, T, R).

aplicar_fusion(Grid, Pos, Block, [], _, 0, Grid, Pos).

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
    reemplazarEnIndice(G3, Pos, ValorFusionado, G4),
    Subida is Pos - NumCols,
    (   Subida >= 0,
        nth0(Subida, G3, '-')
    ->  reemplazarEnIndice(G4, Pos, '-', G5),
        reemplazarEnIndice(G5, Subida, ValorFusionado, NuevoGrid),
        NuevaPos is Subida
    ;   NuevoGrid = G4,
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


efectos(Grid, Pos, Block, NumCols, NuevoGridFinal, NuevaPos2, PuntosGanados) :-
    adyacentes(Grid, Pos, NumCols, Adyacentes),
    filtrar_iguales(Block, Adyacentes, Iguales),
    (
        Iguales \= [] ->
            aplicar_fusion(Grid, Pos, Block, Iguales, NumCols, ValorFusionado, GridFusionado, NuevaPos2),
            PuntosGanados is ValorFusionado,
            NuevoGridFinal = GridFusionado
    ;
        NuevoGridFinal = Grid,
        NuevaPos2 = Pos,
        PuntosGanados = 0
    ).

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

/*llamar_efectos_adyacentes(Grilla2, PosicionResultante, NumCols, GridFin):-
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
    ).*/
   

loop_efectos(Grid, Pos, Block, NumCols, FinalGrid, PuntajeTotal, ComboCount, ComboPos, Efectos1) :-
    efectos(Grid, Pos, Block, NumCols, Grid2, NuevaPos, PuntosFusion),
    (   Grid \= Grid2 -> % Hubo una fusión
        aplicar_gravedad(Grid2, NumCols, GridGravedad),
        Efecto_Grav = [effect(GridGravedad, [])],
        nth0(NuevaPos, GridGravedad, NuevoValor),
        (   number(NuevoValor) ->
            % Llamada recursiva: contamos el siguiente eslabón del combo
            loop_efectos(GridGravedad, NuevaPos, NuevoValor, NumCols, FinalGrid, PuntosRecursivos, ComboRecursivo, PosRecursiva, EfectosRec),
            PuntajeTotal is PuntosFusion + PuntosRecursivos,
            ComboCount is 1 + ComboRecursivo, % Sumamos 1 al combo
            ComboPos = PosRecursiva, % La posición final es la de la última fusión en la cadena
            ( PuntosRecursivos > 0 -> MensajesExtra = [newBlock(PuntosRecursivos)] ; MensajesExtra = [] ),
            append(EfectosRec, [effect(FinalGrid, MensajesExtra)], E1),
            append(Efecto_Grav, E1, Efectos1)
        ;   % Esta fue la última fusión de la cadena
            FinalGrid = GridGravedad,
            PuntajeTotal is PuntosFusion,
            ComboCount = 1, % El combo es de 1
            ComboPos = NuevaPos, % La posición es donde cayó el nuevo bloque
            Efectos1 = Efecto_Grav
        )
    ;   % No hubo fusión
        FinalGrid = Grid,
        Efectos1 = [effect(FinalGrid, [])],
        PuntajeTotal = 0,
        ComboCount = 0, % No hay combo
        ComboPos = Pos
    ).

loop_efectos(Grid, _, '-', _, Grid, 0, 0, _, [effect(Grid, [])]):-!.

recorrer_grilla_efectos(Grilla, _NumCols, Pos, Len, Grilla, 0, []) :-
    Pos >= Len, !.  

recorrer_grilla_efectos(Grilla, NumCols, Pos, Len, GrillaFinal, PuntajeTotal, EfectosRecorrido) :-
    Pos < Len,
    nth0(Pos, Grilla, Val),
    ( number(Val) ->
        loop_efectos(Grilla, Pos, Val, NumCols, GrillaIntermedia, PuntosBloque, ContadorComb, PosiCombo, EfectosL),
        ( GrillaIntermedia \= Grilla ->
        ( recorrer_grilla_efectos(GrillaIntermedia, NumCols, 0, Len, GrillaFinal, PuntosRestantes, EfectosRec1),
        PuntajeTotal is PuntosBloque + PuntosRestantes,
        append(EfectosL, EfectosRec1, E2),
        append(E2, [effect(GrillaFinal, [])], EfectosRecorrido)
        )
    ;   
        ( Pos1 is Pos + 1,
        recorrer_grilla_efectos(Grilla, NumCols, Pos1, Len, GrillaFinal, PuntajeTotal, EfectosRec2),
        append(EfectosL, EfectosRec2, E3),
        append(E3, [effect(GrillaFinal, [])], EfectosRecorrido)
        )
    )
    ;
       (
        Pos1 is Pos + 1,
        recorrer_grilla_efectos(Grilla, NumCols, Pos1, Len, GrillaFinal, PuntajeTotal, EfectosRec3),
        append(EfectosRec3, [effect(GrillaFinal, [])], EfectosRecorrido)
        )
    ).


chequear_efectos_general(Grilla, NumCols, GrillaFinal, PuntajeTotal, EfectosChequeo) :-
    chequear_efectos_general(Grilla, NumCols, GrillaFinal, 20, PuntajeTotal, EfectosChequeo).  % hasta 20 iteraciones

chequear_efectos_general(Grilla, NumCols, GrillaFinal, Iter, PuntajeTotal, EfectosChequeo) :-
    ( Iter =< 0 ->
        GrillaFinal = Grilla,
        PuntajeTotal = 0,
        EfectosChequeo = []
    ;
        length(Grilla, Len),
        recorrer_grilla_efectos(Grilla, NumCols, 0, Len, GrillaIntermedia, PuntosIteracion, EfectosChequeo1),
    
        ( GrillaIntermedia \= Grilla ->
            Iter1 is Iter - 1,
            chequear_efectos_general(GrillaIntermedia, NumCols, GrillaFinal, Iter1, PuntosRestantes, EfectosC),
            PuntajeTotal is PuntosIteracion + PuntosRestantes,
            append(EfectosChequeo1, EfectosC, EfectosChequeo)
            
    ;       GrillaFinal = Grilla,
            EfectosChequeo = [], 
            PuntajeTotal = 0
        )
    ).

    chequear_efectos_general(Grilla, _, Grilla, 0, 0, []) :- !.  


generar_grilla_vacia(NumFilas, GridVacia) :-
    NumCols = 5,  
    Tam is NumCols * NumFilas,
    length(GridVacia, Tam),
    maplist(=('-'), GridVacia).


perdiste(Grid, NumCols) :-
    length(Grid, Len),
    NumFilas is Len // NumCols,
    NumColsLim is NumCols - 1,
    forall(
        between(0, NumColsLim, Col),
        \+ buscarIndiceLibre(Grid, Col, NumCols, NumFilas, _)
    ).
/**
 * replace_all(?Old, ?New, +ListIn, -ListOut)
 *
 * Reemplaza todas las ocurrencias de 'Old' por 'New' en una lista.
 */
replace_all(_, _, [], []).
replace_all(Old, New, [Old|T], [New|T2]) :- !, 
    replace_all(Old, New, T, T2).
replace_all(Old, New, [H|T], [H|T2]) :- 
    H \= Old, 
    replace_all(Old, New, T, T2).

/**
 * cleanup_grid(+Grid, +BlockToEliminate, +NumCols, -CleanedGrid)
 *
 * Elimina todas las instancias de un bloque de la grilla y luego
 * aplica la gravedad para reacomodar los bloques restantes.
 */
cleanup_grid(Grid, BlockToEliminate, NumCols, CleanedGrid) :-
    % 1. Reemplaza el bloque a eliminar por celdas vacías ('-')
    replace_all(BlockToEliminate, '-', Grid, GridWithHoles),
    
    % 2. Aplica la lógica de gravedad existente a la nueva grilla con huecos
    aplicar_gravedad(GridWithHoles, NumCols, CleanedGrid).

shoot(Block, Col, Grid, NumCols, EfectosFinales) :-
    ColIndex is Col - 1,
    length(Grid, Len),
    NumFilas is Len // NumCols,
    buscarIndiceLibre(Grid, ColIndex, NumCols, NumFilas, Pos),
    reemplazarEnIndice(Grid, Pos, Block, GridInsertado),
    Acc1 = [effect(GridInsertado, [])],

    loop_efectos(GridInsertado, Pos, Block, NumCols, GridFusiones, PuntosFusiones1, ComboCount, UltimaPosFusion, EfectosLoop),

    chequear_efectos_general(GridFusiones, NumCols, GridDespues, PuntosFusiones2, EfectosExtra),
    
    PuntajeTotal is PuntosFusiones1 + PuntosFusiones2,
    (
        perdiste(GridDespues, NumCols) ->
            generar_grilla_vacia(7, GridFinal),
            Mensajes = ['perdiste']
        ;
            GridFinal = GridDespues,
            ( PuntajeTotal > 0 -> Mensajes = [newBlock(PuntajeTotal)] ; Mensajes = [] )
    ),

    ( ComboCount >= 3 -> Combo = [combo(ComboCount, UltimaPosFusion)] ; Combo = [] ),

    append(Mensajes, Combo, MensajesFinal),
    Ultimo = effect(GridFinal, MensajesFinal),
    % Limpiamos la lista de efectos para evitar duplicados vacíos.
    flatten([Acc1, EfectosLoop, EfectosExtra, [Ultimo]], EfectosFinalesTemp),
    include(\=(effect([],_)), EfectosFinalesTemp, EfectosFinales).

% simulate_shoot(+Block, +Column, +Grid, +NumCols, -Result)
%
% Simula un disparo en una columna y devuelve el resultado principal sin
% alterar el estado del juego ni generar una lista completa de efectos.
% El resultado puede ser:
% - combo(N): Si se produjo un combo de N fusiones.
% - block(Value): Si se creó un nuevo bloque de valor Value.
% - none: Si no ocurrió ninguna fusión o evento notable.

simulate_shoot(Block, Col, Grid, NumCols, Result) :-
    ColIndex is Col - 1,
    length(Grid, Len),
    NumFilas is Len // NumCols,
    
    % Primero, verifica si la columna está llena. Si no se encuentra un índice libre, la jugada no es posible.
    (   \+ buscarIndiceLibre(Grid, ColIndex, NumCols, NumFilas, _) ->
        Result = none
    ;
        % Si la columna no está llena, procede con la simulación.
        buscarIndiceLibre(Grid, ColIndex, NumCols, NumFilas, Pos),
        reemplazarEnIndice(Grid, Pos, Block, GridInsertado),
        
        % Ejecuta la misma lógica de efectos en cadena para obtener el resultado.
        % Los guiones bajos (_) indican que no nos interesan esos valores de salida aquí.
        loop_efectos(GridInsertado, Pos, Block, NumCols, GridFinal, PuntosFusion, ComboCount, ComboPos, _Efectos),

        % Determina el resultado más relevante para mostrar como pista.
        (   ComboCount >= 3 ->
            Result = combo(ComboCount)         % El resultado principal es un combo.
        ;   PuntosFusion > 0 ->
            nth0(ComboPos, GridFinal, ValorMax),
            Result = block(ValorMax)      % El resultado es un nuevo bloque.
        ;   
            Result = none                      % No pasó nada interesante.
        )
    ).
