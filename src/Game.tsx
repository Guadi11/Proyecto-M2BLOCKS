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
  const [comboActual, setComboActual] = useState<number | null>(null);
  const [posicionCombo, setPosicionCombo] = useState<number | null>(null);
  const bloqueAEliminarPorObjetivo: Record<number, number | null> = {
  512: null,
  1024: null,
  2048: 2,
  4096: 4,
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

  useEffect(() => {
    connectToPenginesServer();
  }, []);

  useEffect(() => {
    if (pengine) {
      initGame();
    }
  }, [pengine]);

  async function connectToPenginesServer() {
    setPengine(await PengineClient.create()); // Await until the server is initialized
  }

  async function initGame() {
    const queryS = 'init(Grid, NumOfColumns), randomBlock(Grid, Block)';
    const response = await pengine!.query(queryS);
    setGrid(response['Grid']);
    setShootBlock(response['Block']);
    setNumOfColumns(response['NumOfColumns']);
    //agregado:
    setObjetivo(512);
    setBloquesEliminados([]);
    setScore(0);
    setMostrarCartelInicial(true);
    setTimeout(() => setMostrarCartelInicial(false), 3000);
  }

  
  //click del jugador
  async function handleLaneClick(lane: number) {
    // No effect if waiting.
    if (waiting || !grid || shootBlock === null) {
      return;
    }
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
      animateEffect(response['Effects']);  
      
      if (newBlock === null || newBlock === undefined) {
       setPerdiste(true);
       setShootBlock(null);
      } else {
        setShootBlock(newBlock);
      }

      } else {
       setWaiting(false);
      }
    }
  


  async function animateEffect(effects: EffectTerm[]) {
    if (effects.length === 0) {
    setWaiting(false);
    return;
  }
    const effect = effects[0];    
    const [effectGrid, effectInfo] = effect.args;
    console.log("effectInfo recibido:", effectInfo);
    //primero actualizamos el grid
    setGrid(effectGrid);
    //elimino los bloques prohibidos si estan en la grilla
    const nuevaGrilla = effectGrid.map((val) => {
    if (typeof val === 'number' && bloquesEliminados.includes(val)) {
      return '-'; // eliminamos ese bloque de la grilla
    }
    return val;
    });
    setGrid(nuevaGrilla);



  //detecto si perdi
  const contienePerdiste = effectInfo.some((item) => {
    if (typeof item === 'string') {
    return item === 'perdiste';
  }
  if (typeof item === 'object' && 'functor' in item) {
    return item.functor === 'perdiste'; // por si viene con functor también
  }
  return false;
});

  if (contienePerdiste) {
  setMostrarCartelPerdiste(true);
  setGrid(effectGrid);
  setShootBlock(null);
  setWaiting(true);

  setTimeout(() => {
    setMostrarCartelPerdiste(false);
    setScore(0);             //reinicio puntaje
    initGame();              //reinicio el juego
    setWaiting(false);
  }, 3000);
    return;
  }
//calculamos y actualizamos el puntaje inmediatamente
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
    posComboDetectada = args[1]; // La posición está en args[1]
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
  setPosicionCombo(posComboDetectada); // Usamos la posición recibida de Prolog

  setTimeout(() => {
    setComboActual(null);
    setPosicionCombo(null);
  }, 2000);
}
  //chequeamos objetivo (también sin delay)
    const maxBloque = Math.max(...(effectGrid.filter(x => typeof x === 'number') as number[]));
    if (maxBloque >= objetivo) {
    const nuevoObjetivo = objetivo * 2;
    const bloqueEliminado = bloqueAEliminarPorObjetivo[objetivo];
    const bloqueAgregadoValor = bloqueAgregadoPorObjetivo[objetivo];
    
    if (bloqueEliminado !== null) {
    const nuevaGrilla = effectGrid.map(val =>
      val === bloqueEliminado ? '-' : val
    );
    setGrid(nuevaGrilla); // actualizamos la grilla sin esos bloques
  }
  // Mostrar cartel de objetivo durante 3s
  setMensajeObjetivo(`🎉 ¡Objetivo ${objetivo} alcanzado! Próximo: ${nuevoObjetivo}. ${bloqueEliminado !== null ? 'Bloque eliminado: ${bloqueEliminado}' : ''}`);

  setTimeout(() => {
    setMensajeObjetivo(null);

    if (objetivo>= 1024 && bloqueAgregadoValor !== null){
      setBloqueAgregado(bloqueAgregadoValor);
      setTimeout(() => {
        setBloqueAgregado(null);
      }, 2500);
    }
  }, 3000);

  setObjetivo(nuevoObjetivo);
  // Actualizamos estados
  setObjetivo(nuevoObjetivo);
  if (bloqueEliminado !== null) {
    setBloquesEliminados(prev => [...prev, bloqueEliminado]);
  } 
}
const restRGrids = effects.slice(1);
  // 5. Esperamos para la siguiente animación (solo visual)
  //await delay(700); podés probar con 300 o 700 según el efecto
  //await animateEffect(effects.slice(1));
  if (restRGrids.length === 0) {
  setWaiting(false);
  return;
}
// Usar setTimeout en lugar de await
setTimeout(() => {
  animateEffect(restRGrids);
}, 500);
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
      </div>

      {/* Footer con el bloque que se va a disparar */}
      <div className="footer">
        <div className="blockShoot">
          <Block value={shootBlock!} position={[0, 0]} />
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


export default Game;