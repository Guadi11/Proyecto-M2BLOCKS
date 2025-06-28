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
    const effect = effects[0];    
    const [effectGrid, effectInfo] = effect.args;

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



//si no perdi sigo
    setGrid(effectGrid);

    effectInfo.forEach((item : any) => {
      const { functor, args } = item;
      if (functor === 'newBlock'){
        setScore(prevscore => {//score + args[0], suma el puntaje recibido
        const nuevoScore = prevscore + args[0];
      if (nuevoScore > mejorPuntaje) {
        setMejorPuntaje(nuevoScore);
      }
      return nuevoScore;
    });
  }
});

//si alcancé el objetivo
    const maxBloque = Math.max(...(effectGrid.filter(x => typeof x === 'number') as number[]));
    if(maxBloque >= objetivo){
    const nuevoObjetivo = objetivo * 2;
    const bloqueAEliminar = objetivo === 512 ? 2 : objetivo / 2;
    const bloqueAgregadoValor = objetivo / 16;

    setMensajeObjetivo(`🎉 ¡Objetivo ${objetivo} alcanzado! Próximo: ${nuevoObjetivo}. Bloque eliminado: ${bloqueAEliminar}`);
  
  // Mostrar cartel de objetivo durante 3s
    setTimeout(() => {
    setMensajeObjetivo(null);

    // Luego del objetivo, mostramos el cartel de bloque agregado
    setBloqueAgregado(bloqueAgregadoValor);
    setTimeout(() => {
      setBloqueAgregado(null);
    }, 2500); // duración del cartel de bloque agregado

  }, 3000); // duración del cartel de objetivo

  // Actualizamos el estado del objetivo y los bloques eliminados
  setObjetivo(nuevoObjetivo);
  setBloquesEliminados(prev => [...prev, bloqueAEliminar]);
}

    const restRGrids = effects.slice(1);
    if (restRGrids.length === 0) {
      setWaiting(false);
      return;
    }

    await delay(1000);
    animateEffect(restRGrids);
  }

  if (grid === null) {
    return null;
  }
  return (
    <>
      {/*cartel de primer objetivo}*/}
      {mostrarCartelInicial && (
      <div style={cartelEstilo}>
        🎯 Primer objetivo: 512
      </div>
      )}
      {/*cartel perdiste*/}
      {mostrarCartelPerdiste && (
        <div style={cartelEstilo}>
          💥 ¡Perdiste! Reiniciando...
        </div>
      )}

      {/*cartel de objetivo*/}
      {mensajeObjetivo && (
        <div style={cartelEstilo}>
          {mensajeObjetivo}
        </div>
      )}

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
          //backgroundColor: 'white',
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

        <Board
          grid={grid}
          numOfColumns={numOfColumns!}
          onLaneClick={handleLaneClick}
        />

        <div className='footer'>
          <div className='blockShoot'>
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
