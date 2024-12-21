import { useState, useEffect } from "react";
import { SDK, createDojoStore } from "@dojoengine/sdk";
import { schema, Position } from "../bindings";
import { useDojo } from "../hooks/useDojo";
import GameOver from "../components/GameOver";
import Winner from "../components/Winner";
import { createInitialPieces, PieceUI, Coordinates } from "./InitPieces";
import ControllerButton from '../connector/ControllerButton';
import BackgroundCheckers from "../assets/BackgrounCheckers.png";
import Board from "../assets/Board.png";
import PieceBlack from "../assets/PieceBlack.svg";
import PieceOrange from "../assets/PieceOrange.svg";
import QueenBlack from "../assets/QueenBlack.png";
import QueenOrange from "../assets/QueenOrange.png";
import Player1 from "../assets/Player1_0.png";
import Player2 from "../assets/Player2_0.png";
import Return from "../assets/Return.png";
import { useAccount } from "@starknet-react/core";
import { Account } from "starknet";

export const useDojoStore = createDojoStore<typeof schema>();

function Checker({ }: { sdk: SDK<typeof schema> }) {
  const {
    // account: { account },
    setup: { setupWorld },
  } = useDojo();

  const {account} = useAccount();
  const [arePiecesVisible] = useState(true);
  const [isGameOver] = useState(false);
  const [isWinner, setIsWinner] = useState(false);
  const [selectedPieceId, setSelectedPieceId] = useState<number | null>(null);
  const [validMoves, setValidMoves] = useState<Coordinates[]>([]);
  const [mustCapture, setMustCapture] = useState(false);
  const [orangeScore, setOrangeScore] = useState(12);
  const [blackScore, setBlackScore] = useState(12);

  

  const [upPieces, setUpPieces] = useState<PieceUI[]>([]);
  const [downPieces, setDownPieces] = useState<PieceUI[]>([]);

    useEffect(() => {
      if (account?.address) {
        const { initialBlackPieces, initialOrangePieces } = createInitialPieces(
          account.address
        );
        setUpPieces(initialBlackPieces);
        setDownPieces(initialOrangePieces);
      }
    }, [account]);
  const cellSize = 88;



  // Check for a winner when scores change
  useEffect(() => {
    if (orangeScore === 0) {
      setIsWinner(false);
    } else if (blackScore === 0) {
      setIsWinner(true);
    }
  }, [orangeScore, blackScore]);

  const isCellOccupied = (row: number, col: number): boolean => {
    return [...upPieces, ...downPieces].some(piece => piece.piece.row === row && piece.piece.col === col);
  };

  const calculateQueenMoves = (piece: PieceUI): Coordinates[] => {
    const moves: Coordinates[] = [];
    const directions = [
      [-1, -1], [-1, 1],
      [1, -1], [1, 1]
    ];

    for (const [deltaRow, deltaCol] of directions) {
      let currentRow = piece.piece.row + deltaRow;
      let currentCol = piece.piece.col + deltaCol;

      while (currentRow >= 0 && currentRow < 8 && currentCol >= 0 && currentCol < 8) {
        if (!isCellOccupied(currentRow, currentCol)) {
          moves.push({
            row: currentRow,
            col: currentCol,
            capturedPiece: undefined,
            isCapture: undefined
          });
        } else {
          const isEnemy = isCellOccupiedByEnemy(currentRow, currentCol, piece.piece.position);
          if (isEnemy) {
            const nextRow = currentRow + deltaRow;
            const nextCol = currentCol + deltaCol;
            if (
              nextRow >= 0 && nextRow < 8 &&
              nextCol >= 0 && nextCol < 8 &&
              !isCellOccupied(nextRow, nextCol)
            ) {
              moves.push({
                row: nextRow,
                col: nextCol,
                capturedPiece: { row: currentRow, col: currentCol },
                isCapture: true,
              });
            }
          }
          break;
        }
        currentRow += deltaRow;
        currentCol += deltaCol;
      }
    }
    return moves;
  };

  const calculateCaptureMoves = (piece: PieceUI): Coordinates[] => {
    if (piece.piece.is_king) {
      return calculateQueenMoves(piece).filter(move => move.isCapture);
    }

    const captureMoves: Coordinates[] = [];
    const { row, col } = piece.piece;
    const directions = piece.piece.is_king ? [1, -1] : [piece.piece.position === Position.Up ? 1 : -1];

    for (const dir of directions) {
      [-2, 2].forEach(deltaCol => {
        const targetRow = row + (2 * dir);
        const targetCol = col + deltaCol;
        const middleRow = row + dir;
        const middleCol = col + (deltaCol / 2);

        if (
          targetRow >= 0 && targetRow < 8 &&
          targetCol >= 0 && targetCol < 8 &&
          !isCellOccupied(targetRow, targetCol)
        ) {
          const isEnemyPiece = isCellOccupiedByEnemy(middleRow, middleCol, piece.piece.position);
          if (isEnemyPiece) {
            captureMoves.push({
              row: targetRow,
              col: targetCol,
              isCapture: true,
              capturedPiece: { row: middleRow, col: middleCol }
            });
          }
        }
      });
    }

    return captureMoves;
  };

  const ScoreCounter = ({
    orangeScore,
    blackScore,
  }: {
    orangeScore: number;
    blackScore: number;
    totalOrangePieces: number;
    totalBlackPieces: number;
  }) => {

    return (
      <div className="fixed w-full h-screen">
        {/* Orange Piece */}
        <div
          className="absolute p-4 bg-orange-100 rounded-lg shadow-lg border-2 border-black"
          style={{ top: "110px", right: "1550px", width: "95px", height: "95px" }}
        >
          <div className="text-center">
            <p className="text-2xl font-bold text-orange-800">{blackScore}</p>
            <h3 className="font-bold text-orange-600">Orange</h3>
          </div>
        </div>
        {/* Black Piece */}
        <div
          className="absolute p-4 bg-gray-100 rounded-lg shadow-lg border-2 border-black"
          style={{ top: "790px", left: "1650px", width: "95px", height: "95px" }}
        >
          <div className="text-center">
            <p className="text-2xl font-bold text-gray-800">{orangeScore}</p>
            <h3 className="font-bold text-gray-600">Black</h3>
          </div>
        </div>
      </div>
    );
}    

  const calculateValidMoves = (piece: PieceUI): Coordinates[] => {
    const allPieces = piece.piece.position === Position.Up ? upPieces : downPieces;
    const hasAnyCaptures = allPieces.some(p => calculateCaptureMoves(p).length > 0);

    if (hasAnyCaptures) {
      setMustCapture(true);
      return calculateCaptureMoves(piece);
    }

    setMustCapture(false);

    if (piece.piece.is_king) {
      return calculateQueenMoves(piece);
    }

    const regularMoves: Coordinates[] = [];
    const { row, col } = piece.piece;
    const direction = piece.piece.position === Position.Up ? 1 : -1;

    [-1, 1].forEach(deltaCol => {
      const newRow = row + direction;
      const newCol = col + deltaCol;

      if (
        newRow >= 0 && newRow < 8 &&
        newCol >= 0 && newCol < 8 &&
        !isCellOccupied(newRow, newCol)
      ) {
        regularMoves.push({
          row: newRow,
          col: newCol,
          capturedPiece: undefined,
          isCapture: undefined
        });
      }
    });

    return regularMoves;
  };

  const isCellOccupiedByEnemy = (row: number, col: number, position: Position): boolean => {
    const enemyPieces = position === Position.Up ? downPieces : upPieces;
    return enemyPieces.some(piece => piece.piece.row === row && piece.piece.col === col);
  };

  const handlePieceClick = async (piece: PieceUI) => {
    if (selectedPieceId === piece.id) {
      setSelectedPieceId(null);
      setValidMoves([]);
      return;
    }

    const moves = calculateValidMoves(piece);

    if (mustCapture && !moves.some(move => move.isCapture)) {
      return;
    }

    setSelectedPieceId(piece.id);
    setValidMoves(moves);

    try {
      if (account) {
        const { row, col } = piece.piece;
        await (await setupWorld.actions).canChoosePiece((account as Account), piece.piece.position, { row, col }, 0);
      }
    } catch (error) {
      console.error("Error verificando la pieza seleccionada:", error);
    }
  };

  const handleMoveClick = async (move: Coordinates) => {
    if (!selectedPieceId) return;

    const selectedPiece = [...upPieces, ...downPieces].find(piece => piece.id === selectedPieceId);
    if (!selectedPiece) return;
    console.log("Moviendo la pieza:", selectedPiece);
    const piecesToUpdate = selectedPiece.piece.position === Position.Up ? upPieces : downPieces;
    const enemyPieces = selectedPiece.piece.position === Position.Up ? downPieces : upPieces;

    // Handle capturing and update the score
    if (move.isCapture && move.capturedPiece) {
      const updatedEnemyPieces = enemyPieces.filter(
        piece => !(piece.piece.row === move.capturedPiece?.row && piece.piece.col === move.capturedPiece?.col)
      );

      if (selectedPiece.piece.position === Position.Up) {
        setDownPieces(updatedEnemyPieces);
        setBlackScore(prev => prev - 1);
      } else {
        setUpPieces(updatedEnemyPieces);
        setOrangeScore(prev => prev - 1);
      }
    }

    // Update the piece position and check for promotion
    const shouldPromoteToQueen =
      (selectedPiece.piece.position === Position.Up && move.row === 7) ||
      (selectedPiece.piece.position === Position.Down && move.row === 0);

    const updatedPieces = piecesToUpdate.map((piece: PieceUI) => {
      if (piece.id === selectedPieceId) {
        return {
          ...piece,
          piece: {
            ...piece.piece,
            row: move.row,
            col: move.col,
            is_king: shouldPromoteToQueen || piece.piece.is_king
          }
        };
      }
      return piece;
    });

    if (selectedPiece.piece.position === Position.Up) {
      setUpPieces(updatedPieces);
    } else {
      setDownPieces(updatedPieces);
    }
    try {
      if (account) {
        const movedPiece = await(await setupWorld.actions).movePiece(
          (account as Account),
          selectedPiece.piece,
          move
        );
        console.log(
          movedPiece.transaction_hash,
          "movePiece transaction_hash success"
        );
      }
    } catch (error) {
      console.error("Error al mover la pieza:", error);
    }


    // After handling the move, check if the game is over
    setSelectedPieceId(null);
    setValidMoves([]);
  };

  return (
    <div
      className="relative h-screen w-full"
      style={{
        backgroundImage: `url(${BackgroundCheckers})`,
        backgroundSize: "cover",
        backgroundPosition: "center",
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: '20px',
          right: '20px',
          display: 'flex',
          gap: '20px',
          zIndex: 2,
        }}
      >
      </div>

      <ScoreCounter orangeScore={orangeScore} blackScore={blackScore} totalOrangePieces={upPieces.length} totalBlackPieces={downPieces.length} />
   
    {/* CreateBurner & ControllerButton */}
    <div
        style={{
          position: 'absolute',
          top: '20px',
          right: '20px',
          display: 'flex',
          gap: '20px',
          zIndex: 2,
        }}
      >
        <ControllerButton />
      </div>
      
      {isGameOver && <GameOver />}
      {isWinner && <Winner />}

      <img
        src={Player1}
        alt="Player 1"
        className="fixed rounded-lg"
        style={{ top: "110px", left: "140px", width: "90px", border: "2px solid black" }}
      />
      <img
        src={Player2}
        alt="Player 2"
        className="fixed rounded-lg"
        style={{ top: "790px", right: "320px", width: "90px", border: "2px solid orange" }}
      />
      <div className="flex items-center justify-center h-full">
        <div className="relative">
          <img
            src={Board}
            alt="Board"
            className="w-[800px] h-[800px] object-contain"
          />
          {arePiecesVisible && (
            <>
              {upPieces.map((piece) => (
                <img
                  key={piece.id}
                  src={piece.piece.is_king ? QueenBlack : PieceBlack}
                  className="absolute"
                  style={{
                    left: `${piece.piece.col * cellSize + 63}px`,
                    top: `${piece.piece.row * cellSize + 63}px`,
                    cursor: "pointer",
                    width: "60px",
                    height: "60px",
                    border: selectedPieceId === piece.id ? "2px solid yellow" : "none",
                  }}
                  onClick={() => handlePieceClick(piece)}
                />
              ))}
              {downPieces.map((piece) => (
                <img
                  key={piece.id}
                  src={piece.piece.is_king ? QueenOrange : PieceOrange}
                  className="absolute"
                  style={{
                    left: `${piece.piece.col * cellSize + 64}px`,
                    top: `${piece.piece.row * cellSize + 55}px`,
                    cursor: "pointer",
                    width: "60px",
                    height: "60px",
                    border: selectedPieceId === piece.id ? "2px solid yellow" : "none",
                  }}
                  onClick={() => handlePieceClick(piece)}
                />
              ))}
              {validMoves.map((move, index) => (
                <div
                  key={`move-${index}`}
                  className="absolute"
                  style={{
                    left: `${move.col * cellSize + 63}px`,
                    top: `${move.row * cellSize + 63}px`,
                    width: "60px",
                    height: "60px",
                    backgroundColor: move.isCapture ? "rgba(255, 0, 0, 0.3)" : "rgba(0, 255, 0, 0.3)",
                    borderRadius: "50%",
                    cursor: "pointer",
                  }}
                  onClick={() => handleMoveClick(move)}
                />
              ))}
            </>
          )}
        </div>
        <button
          onClick={() => {
            window.location.href = '/';
          }}
          style={{
            position: 'absolute',
            top: '20px',
            left: '20px',
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            zIndex: 2,
          }}
        >
          <img
            src={Return}
            alt="Return"
            style={{
              width: '50px',
              height: '50px',
            }}
          />
        </button>
      </div>
    </div>
  );
}

export default Checker;