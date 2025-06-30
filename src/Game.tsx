import { useEffect, useState } from 'react';
import PengineClient, { PrologTerm } from './PengineClient';
import Board from './Board';
import Block from './Block';
import { delay } from './util';

export type Grid = (number | "-")[];
interface EffectTerm extends PrologTerm {
  functor: "effect";
  args: [Grid, EffectInfoTerm[]];
}

type EffectInfoTerm = NewBlockTerm | PrologTerm;
interface NewBlockTerm extends PrologTerm {
  functor: "newBlock";
  args: [number];
}

function Game() {

  // State
  const [pengine, setPengine] = useState<any>(null);
  const [grid, setGrid] = useState<Grid | null>(null);
  const [numOfColumns, setNumOfColumns] = useState<number | null>(null);
  const [score, setScore] = useState<number>(0);
  const [shootBlock, setShootBlock] = useState<number | null>(null);
  const [waiting, setWaiting] = useState<boolean>(false);
  //estados agregados para perder y objetivos
  const [perdiste, setPerdiste] = useState(false);
  const [mostrarCartelPerdiste, setMostrarCartelPerdiste] = useState(false);
  const [objetivo, setObjetivo] = useState(512);
  const [bloquesEliminados, setBloquesEliminados] = useState<number[]>([]);
  const [mensajeObjetivo, setMensajeObjetivo] = useState<string | null>(null);
  const [mostrarCartelInicial, setMostrarCartelInicial] = useState(true);
  const [bloqueAgregado, setBloqueAgregado] = useState<number | null>(null);
  const [mejorPuntaje, setMejorPuntaje] = useState<number>(0);
  //Logica de combos
  const [comboActual, setComboActual] = useState<number | null>(null);
  const [posicionCombo, setPosicionCombo] = useState<number | null>(null);
  //Lógica del siguiente bloque junto al booster
  const [nextBlock, setNextBlock] = useState<number | null>(null);
  const [isNextBlockVisible, setIsNextBlockVisible] = useState(false);
  const [boosterTimerActive, setBoosterTimerActive] = useState(false);
  const [activeNotifications, setActiveNotifications] = useState<string[]>([]);
  //Logica para booster Hint
  const [hints, setHints] = useState<{ col: number, text: string }[]>([]);
  const [isHintActive, setIsHintActive] = useState(false);
  const bloqueAEliminarPorObjetivo: Record<number, number | null> = {
  512: null,
  1024: 2,
  2048: 4,
  4096: 8,
  8192: 8,
  16384: 16,
  32768: 32,
  65536: 64,
};

const bloqueAgregadoPorObjetivo: Record<number, number> = {
  1024: 128,
  2048: 256,
  4096: 512,
  8192: 512,
  16384: 1024,
  32768: 2048,
  65536: 4096,
};

// --- Tipo para las pistas ---
type Hint = {
    col: number;
    text: string;
};

// --- Tipo para la respuesta de simulación de Prolog ---
type SimulationResponse = {
    Result?: {
        functor: string;
        args: any[];
    }
};

  useEffect(() => {
    connectToPenginesServer();
  }, []);

  useEffect(() => {
    if (pengine) {
      initGame();
    }
  }, [pengine]);
useEffect(() => {
        if (activeNotifications.length > 0) {
            const timer = setTimeout(() => {
                // Muestra la siguiente notificación eliminando la actual de la cola
                setActiveNotifications(prev => prev.slice(1));
            }, 2500); // Duración de cada mensaje
            return () => clearTimeout(timer);
        }
    }, [activeNotifications]);

  async function connectToPenginesServer() {
    setPengine(await PengineClient.create()); // Await until the server is initialized
  }

  async function initGame() {
    const queryS = 'init(Grid, NumOfColumns), randomBlock(Grid, Block), randomBlock(Grid, NextBlock)';
    const response = await pengine!.query(queryS);
    setGrid(response['Grid']);
    setShootBlock(response['Block']);
    setNextBlock(response['NextBlock']);
    setNumOfColumns(response['NumOfColumns']);
    //agregado:
    setObjetivo(512);
    setBloquesEliminados([]);
    setScore(0);
    setMostrarCartelInicial(true);
    setIsNextBlockVisible(false);
    setTimeout(() => setMostrarCartelInicial(false), 3000);
  }

  
  //click del jugador
  async function handleLaneClick(lane: number) {
    // No effect if waiting.
    if (waiting || !grid || shootBlock === null || isHintActive) {
      return;
    }
    setWaiting(true);
    /*
    Build Prolog query, which will be something like:
    shoot(2, 2, [4,2,8,64,32,2,-,-,4,16,-,-,-,-,2,-,-,-,-,16,-,-,-,-,2,-,-,-,-,-,-,-,-,-,-], 5, Effects), last(Effects, effect(RGrid,_)), randomBlock(RGrid, Block).
    */
    const gridS = JSON.stringify(grid).replace(/"/g, '');
    const eliminadosS = JSON.stringify(bloquesEliminados).replace(/"/g, '');
    const queryS = `shoot(${shootBlock}, ${lane}, ${gridS}, ${numOfColumns}, Effects), last(Effects, effect(RGrid,_)), randomBlock(RGrid, Block)`;
    setWaiting(true);
    const response = await pengine.query(queryS);  

    if (response) {    
      const newBlock = response['Block'];
      setShootBlock(nextBlock);
      const finalGrid = await animateEffect(response.Effects);
      await checkForNewMaxBlock(finalGrid);

      
      if (newBlock === null || newBlock === undefined) {
       setPerdiste(true);
       setShootBlock(null);
       setNextBlock(null);
      } else {
        setNextBlock(newBlock);
      }
      } else {
       setWaiting(false);
      }
      
    }
  
  // --- Función para activar el boosterNextBlock ---
    function activateNextBlockBooster() {
        if (boosterTimerActive) return;
        setBoosterTimerActive(true);
        setIsNextBlockVisible(true);
        setTimeout(() => {
            setIsNextBlockVisible(false);
            setBoosterTimerActive(false);
        }, 10000);
    }

    // --- Función para activar el boosterHint ---
async function activateHintBooster() {
// 1: Guarda para evitar que se ejecute si los datos no están listos.
if (waiting || isHintActive || !pengine || !grid || shootBlock === null || numOfColumns === null) {
  return;
}

setWaiting(true);
setIsHintActive(true);

const gridS = JSON.stringify(grid).replace(/"/g, '');
const simulationPromises = [];

for (let col = 1; col <= numOfColumns; col++) {
  const queryS = `simulate_shoot(${shootBlock}, ${col}, ${gridS}, ${numOfColumns}, Result)`;
  //2: Tipado explícito para la respuesta de la promesa.
  const promise = pengine.query(queryS).then((response: SimulationResponse) => ({ col, response }));
  simulationPromises.push(promise);
}

try {
  const results = await Promise.all(simulationPromises);
  // Se usa .reduce para construir el array con el tipo correcto, evitando `null`.
  const collectedHints = results.reduce<Hint[]>((acc, { col, response }) => {
  if (response && response.Result) {
    const { functor, args } = response.Result;
    let text = '';
    if (functor === 'combo') text = `x${args[0]}`;
    else if (functor === 'block') text = `${args[0]}`;
    if (text) {
      acc.push({ col, text });
    }
  }
  return acc;
  }, []);
 setHints(collectedHints);

} catch (error) {
  console.error("Error durante simulación de pistas:", error);
  } finally {
    setWaiting(false);
    setTimeout(() => {
      setHints([]);
      setIsHintActive(false);
    }, 3000);
    }
}
// --- LÓGICA DE OBJETIVOS Y LIMPIEZA ---
async function checkForNewMaxBlock(finalGrid: Grid) {
 if (!finalGrid || !pengine || numOfColumns === null) return;
        
const maxBloque = Math.max(0, ...(finalGrid.filter(x => typeof x === 'number') as number[]));

if (maxBloque >= objetivo) {
  const notificationsToShow: string[] = [];
  let gridParaLimpiar = finalGrid;
  notificationsToShow.push(`🏆 ¡Nuevo bloque máximo: ${objetivo}!`);
  const bloqueAgregado = bloqueAgregadoPorObjetivo[objetivo];
  if (bloqueAgregado) {
     notificationsToShow.push(`Bloque agregado: ${bloqueAgregado}`);
  }
  const bloqueEliminado = bloqueAEliminarPorObjetivo[objetivo];
  if (bloqueEliminado !== null && bloqueEliminado !== undefined) {
      notificationsToShow.push(`❌ Bloque retirado: ${bloqueEliminado}`);
      // --- LLAMADA A PROLOG PARA LIMPIAR Y APLICAR GRAVEDAD ---
      const gridS = JSON.stringify(gridParaLimpiar).replace(/"/g, '');
      const queryS = `cleanup_grid(${gridS}, ${bloqueEliminado}, ${numOfColumns}, CleanedGrid)`;
      const cleanupResponse = await pengine.query(queryS);      
      if (cleanupResponse && cleanupResponse.CleanedGrid) {
        // Muestra la grilla limpia con una pequeña animación/delay
        await new Promise(resolve => setTimeout(resolve, 300));
        setGrid(cleanupResponse.CleanedGrid);
        gridParaLimpiar = cleanupResponse.CleanedGrid; // Actualiza para el siguiente paso
      }         
      setBloquesEliminados(prev => [...prev, bloqueEliminado]);
      }     
      const nuevoObjetivo = objetivo * 2;
      setObjetivo(nuevoObjetivo);
      setActiveNotifications(prev => [...prev, ...notificationsToShow]);
    }
  }
  async function animateEffect(effects: EffectTerm[]): Promise<Grid> {
  if (effects.length === 0) {
    setWaiting(false);
    return grid!;
  }

  const effect = effects[0];
  const [effectGrid, effectInfo] = effect.args;
  console.log("effectInfo recibido:", effectInfo);

  const contienePerdiste = effectInfo.some((item) => {
    if (typeof item === 'string') return item === 'perdiste';
    if (typeof item === 'object' && 'functor' in item) return item.functor === 'perdiste';
    return false;
  });

  if (contienePerdiste) {
    setMostrarCartelPerdiste(true);
    setGrid(effectGrid);
    setShootBlock(null);
    setWaiting(true);
    setTimeout(() => {
      setMostrarCartelPerdiste(false);
      setScore(0);
      initGame();
      setWaiting(false);
    }, 3000);
    return effectGrid;
  }

  // ✅ APLICAR GRID EN CADA PASO CON DELAY PARA VISUALIZAR
  setGrid(effectGrid);
  await delay(300); // <- tiempo entre cada grilla intermedia (ajustalo si querés más/menos lento)

  // Acumular puntaje, combos, etc. (esto puede ir antes o después del delay)
  let puntosNuevos = 0;
  let comboDetectado: number | null = null;
  let posComboDetectada: number | null = null;

  effectInfo.forEach((item: any) => {
    const { functor, args } = item;
    if (functor === 'newBlock') {
      puntosNuevos += args[0];
    }
    if (functor === 'combo') {
      comboDetectado = args[0];
      posComboDetectada = args[1];
    }
  });

  if (puntosNuevos > 0) {
    setScore(prev => {
      const nuevo = prev + puntosNuevos;
      if (nuevo > mejorPuntaje) setMejorPuntaje(nuevo);
      return nuevo;
    });
  }

  if (comboDetectado && comboDetectado >= 3) {
    setComboActual(comboDetectado);
    setPosicionCombo(posComboDetectada);
    setTimeout(() => {
      setComboActual(null);
      setPosicionCombo(null);
    }, 2000);
  }

  const restRGrids = effects.slice(1);

  if (restRGrids.length === 0) {
    setWaiting(false);
    return effectGrid;
  }

  return animateEffect(restRGrids);
}

if (grid === null) {
    return null;
  }
  return (
  <>
    {/* Cartel de primer objetivo */}
    {mostrarCartelInicial && (
      <div style={cartelEstilo}>
        🎯 Primer objetivo: 512
      </div>
    )}

    {/* Cartel perdiste */}
    {mostrarCartelPerdiste && (
      <div style={cartelEstilo}>
        💥 ¡Perdiste! Reiniciando...
      </div>
    )}

    {/* Cartel de objetivo */}
    {mensajeObjetivo && (
      <div style={cartelEstilo}>
        {mensajeObjetivo}
      </div>
    )}

    {/* Cartel de bloque agregado */}
    {bloqueAgregado !== null && (
      <div style={cartelEstilo}>
        🧱 Bloque agregado: {bloqueAgregado}
      </div>
    )}
{activeNotifications.length > 0 && (
  <div style={notificacionEstilo}>
    {activeNotifications[0]}
  </div>
)}
    <div className="game">
      <div className="header" style={{
        position: 'relative',
        textAlign: 'center',
        marginBottom: '1rem'
      }}>
        <div className="score" style={{ fontSize: '1.5rem', color: 'white' }}>{score}</div>

        <div style={{
          position: 'absolute',
          right: '1rem',
          top: '50%',
          transform: 'translateY(-50%)',
          backgroundColor: 'white',
          color: 'black',
          padding: '0.3rem 0.8rem',
          borderRadius: '10px',
          fontWeight: 'bold',
          display: 'flex',
          alignItems: 'center',
          fontSize: '1rem',
          gap: '0.4rem'
        }}>
          👑 {mejorPuntaje}
        </div>
      </div>

      {/* Contenedor del tablero con combo */}
      <div style={{ position: 'relative', width: 'fit-content', margin: '0 auto' }}>
        <Board
          grid={grid}
          numOfColumns={numOfColumns!}
          onLaneClick={handleLaneClick}
        />

        {comboActual && posicionCombo !== null && (
          <div
            style={{
              position: 'absolute',
              top: `${Math.floor(posicionCombo / numOfColumns!) * 80}px`,
              left: `${(posicionCombo % numOfColumns!) * 80}px`,
              transform: 'translate(10%, -100%)',
              backgroundColor: 'transparent',
              color: 'white',
              padding: '4px 10px',
              borderRadius: '8px',
              fontWeight: 'bold',
              fontSize: '1.2rem',
              pointerEvents: 'none',
              zIndex: 999
            }}
          >
             Combo x {comboActual}
          </div>
        )}
        {/* Muestra las pistas del booster */}
        {hints.map(hint => (
        <div key={`hint-${hint.col}`} style={{position: 'absolute',  
        top: `${Math.floor(numOfColumns!) * 100}px`, 
        left: `${((hint.col - 1) * (70 + 10)) + 10}px`, 
        bottom: '10px',
        transform: 'translate(10%, -100%)',
        backgroundColor: 'transparent',
        color: 'white',
        padding: '4px 10px',
        borderRadius: '8px',
        fontWeight: 'bold',
        fontSize: '1.2rem',
        pointerEvents: 'none',
        zIndex: 999
      }}>
          {hint.text}
        </div>
        ))}
      </div>

      <div
  className="footer"
  style={{
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: '1rem',
    gap: '2rem'
  }}
>
  {/* Botón de Pista 💡 */}
  <div style={{ width: '60px', height: '60px', position: 'relative', flexShrink: 0 }}>
    <button
      onClick={activateHintBooster}
      disabled={isHintActive || waiting}
      className="boosterHintButton"
      style={{
        width: '100%',
        height: '100%',
        backgroundColor: 'rgba(0,0,0,0.8)',
        color: 'white',
        fontSize: '1.5rem',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '8px',
        cursor: 'pointer',
        border: '2px dashed white',
        zIndex: 1
      }}
    >
      💡
    </button>
  </div>

  {/* Bloque a disparar */}
  <div className="blockShoot" style={{ width: '60px', height: '60px', flexShrink: 0 }}>
    <Block value={shootBlock!} position={[0, 0]} />
  </div>

  {/* Siguiente bloque ❓ */}
  <div className="boosterArea" style={{ width: '40px', height: '40px', position: 'relative', flexShrink: 0 }}>
    <div className="blockShoot" style={{ width: '40px', height: '40px', flexShrink: 0 }}>
    {isNextBlockVisible && nextBlock !== null ? (
      <Block value={nextBlock} position={[0, 0]} />
    ) : (
      <button
        onClick={activateNextBlockBooster}
        disabled={boosterTimerActive}
        className="boosterButton"
        style={{
          width: '100%',
          height: '100%',
          backgroundColor: 'rgba(0,0,0,0.8)',
          color: 'white',
          fontSize: '1.5rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          borderRadius: '8px',
          cursor: 'pointer',
          border: '2px dashed white',
          zIndex: 0 
        }}
      >
        {boosterTimerActive ? '' : '?'}
      </button>
    )}
   </div> 
  </div>
</div>
</div>
  </>
);
}

// Estilo reutilizado para ambos carteles
const cartelEstilo: React.CSSProperties = {
  position: 'fixed',
  top: 0,
  left: 0,
  width: '100vw',
  height: '100vh',
  backgroundColor: 'rgba(0, 0, 0, 0.8)',
  color: 'white',
  fontSize: '2rem',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  zIndex: 9999,
  textAlign: 'center',
  padding: '1rem',
};
const notificacionEstilo: React.CSSProperties = {
  position: 'fixed',
  top: '1rem',
  left: '50%',
  transform: 'translateX(-50%)',
  backgroundColor: '#222',
  color: 'white',
  padding: '1rem 2rem',
  borderRadius: '10px',
  fontSize: '1.5rem',
  zIndex: 9999,
  boxShadow: '0 4px 10px rgba(0, 0, 0, 0.5)',
  maxWidth: '80vw',
  textAlign: 'center'
};


export default Game;