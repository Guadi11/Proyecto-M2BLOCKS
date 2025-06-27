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
  const [perdiste, setPerdiste] = useState(false);
  const [mostrarCartelPerdiste, setMostrarCartelPerdiste] = useState(false);
  useEffect(() => {
    // This is executed just once, after the first render.
    connectToPenginesServer();
  }, []);

  useEffect(() => {
    if (pengine) {
      // This is executed after pengine was set.
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
  }

  /**
   * Called when the player clicks on a lane.
   */
  async function handleLaneClick(lane: number) {
    // No effect if waiting.
    if (waiting) {
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
  /**
   * Displays each grid of the sequence as the current grid in 1sec intervals, and considers the other effect information.
   * @param effects The list of effects to be animated.
   */
  async function animateEffect(effects: EffectTerm[]) {
    const effect = effects[0];    
    const [effectGrid, effectInfo] = effect.args;

  // 🟡 Si contiene el mensaje 'perdiste', lo detectamos
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

  }



//si no perdi sigo
    setGrid(effectGrid);

    effectInfo.forEach((effectInfoItem) => {
      const { functor, args } = effectInfoItem;
      if (functor === 'newBlock'){
        setScore(score => score + args[0]);
      }
    });

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
    {mostrarCartelPerdiste && (
      <div style={{
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
        zIndex: 9999
      }}>
        💥 ¡Perdiste! Reiniciando...
      </div>
    )}

    <div className="game">
      <div className="header">
        <div className="score">{score}</div>
   
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
  );}

export default Game;
