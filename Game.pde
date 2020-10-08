import java.util.Random;

class Game {
  
  //int[] windowSize = {800, 1600};
  
  float[] gameDimensions(int[] windowSize) { // {rows, cols, cellSize, margin}
    float[] res = new float[4];
    res[0] = TETRIS_ROWS;
    res[1] = TETRIS_COLS;
    res[2] = (windowSize[1] * 0.8) / res[0];
    res[3] = windowSize[1] * 0.1;
    return res;
  }
  
  int[][][] makeBoard(int R, int C, int[] initialColor) {
    int[][][] arr = new int[R][C][3];
    for (int r = 0; r < R; r++) {
      for (int c = 0; c < C; c++) {
        arr[r][c][0] = initialColor[0];
        arr[r][c][1] = initialColor[1];
        arr[r][c][2] = initialColor[2];
      }
    }
    return arr;
  }
  
  int rows;
  int cols;
  float cellSize;
  float cellColorSize;
  float cellMargin;
  float boardMargin;
  int[][][] board;
  int[] backgroundColor = {255,255,255}; //white (dArK MOdE)
  
  int score;
  int linesCleared;
  boolean gameOver;
  int level;
  
  Random rand;
  boolean[][] fallingPiece;
  int[] fallingPieceColor;
  int fallingPieceID;
  int fallingPieceRow;
  int fallingPieceCol;
  
  boolean[][] nextFallingPiece;
  int[] nextFallingPieceColor;
  int nextFallingPieceID;
  List<Integer> piecesLeft;
  
  Brain brain;
  int[] brainMoves = null;
  int currMove = 0;
  int numBrainMoves = 0;
  
  Game(int[] windowSize) {
    
    float[] dims = gameDimensions(windowSize);
    
    rows = (int)dims[0];
    cols = (int)dims[1];
    cellSize = dims[2];
    cellColorSize = cellSize * 0.97;
    cellMargin = cellSize * 0.015;
    boardMargin = dims[3];
    board = makeBoard(rows, cols, backgroundColor);
    
    score = 0;
    linesCleared = 0;
    gameOver = false;
    level = 5;
    
    rand = new Random();
    piecesLeft = new ArrayList<Integer>();
    newFallingPiece();
    newFallingPiece();
    
    brain = new Brain();
    determineNextMoves();
  }
  
  void newFallingPiece() {
    if (nextFallingPiece != null) {
      fallingPiece = nextFallingPiece;
      fallingPieceColor = nextFallingPieceColor;
      fallingPieceID = nextFallingPieceID;
      fallingPieceRow = 0;
      int numFallingPieceCols = fallingPiece[0].length;
      fallingPieceCol = cols/2 - numFallingPieceCols / 2;
    } else {
      fallingPieceID = -1;
    }
     // "7-die" (original NES) tetris piece generation
     /*
     int roll = rand.nextInt(8); // 7 is num of tetris pieces
     int finalRoll;
     if (roll == 7 || roll == fallingPieceID) {
       finalRoll = rand.nextInt(7); //re-roll
     } else {  
       finalRoll = roll;
     }
     nextFallingPieceID = finalRoll; 
     nextFallingPiece = tetrisPieces[nextFallingPieceID];
     nextFallingPieceColor = tetrisPieceColors[nextFallingPieceID];
     */
     
     // "draw from bag" (modern) tetris piece generation
     int n = piecesLeft.size();
     if (n == 0) {
       for (int i = 0; i < 7; i++) {
         piecesLeft.add(i);
       }
       n = 7;
     }
     int randIndex = rand.nextInt(n);
     nextFallingPieceID = piecesLeft.remove(randIndex);
     nextFallingPiece = tetrisPieces[nextFallingPieceID];
     nextFallingPieceColor = tetrisPieceColors[nextFallingPieceID];
     
  }
  
  void placeFallingPiece() { //pieces that can't move down placed into board
    // assert(!moveFallingPiece(1,0))
    for (int r = 0; r < fallingPiece.length; r++) {
        for (int c = 0; c < fallingPiece[0].length; c++) {
            if (fallingPiece[r][c]) {
                int boardRow = fallingPieceRow+r;
                int boardCol = fallingPieceCol+c;
                int[] boardColor = board[boardRow][boardCol];
                boardColor[0] = fallingPieceColor[0];
                boardColor[1] = fallingPieceColor[1];
                boardColor[2] = fallingPieceColor[2];
            }
        }
    }
    score++; //each placed piece is a point
  }
  
  boolean fallingPieceIsLegal() {
    for (int r = 0; r < fallingPiece.length; r++) {
      for (int c = 0; c < fallingPiece[0].length; c++) {
        if (fallingPiece[r][c]) {
            int boardCol = fallingPieceCol+c;
            int boardRow = fallingPieceRow+r;
            if (boardCol < 0 || boardRow < 0 
              || boardCol >= cols || boardRow >= rows) {
              return false; //out of board bounds
            }
            int[] boardColor = board[boardRow][boardCol];
            if (boardColor[0] != backgroundColor[0] || boardColor[1] != backgroundColor[1] || boardColor[2] != backgroundColor[2]) {
                return false; //occupied by placed piece
            }
        }
      }
    }
    return true; 
  }
  
  boolean moveFallingPiece(int drow, int dcol) {
    fallingPieceRow += drow;
    fallingPieceCol += dcol;
    if (!fallingPieceIsLegal()) { //undos if new position illegal
        fallingPieceRow -= drow;
        fallingPieceCol -= dcol;
        return false;
    }
    return true; 
  }
  
  void rotateFallingPiece(boolean right) {
    boolean[][] newPiece = new boolean[fallingPiece[0].length][fallingPiece.length];
    
    int i;
    if (right) i = 1;
    else i = 3;
    
    boolean[][] piece = null;
    for (int j = 0; j < i; j++) {
      piece = new boolean[fallingPiece[0].length][fallingPiece.length];
      int numOldCols = fallingPiece[0].length-1;
      for (int row = 0; row < fallingPiece.length; row++) {
        for (int col = 0; col < fallingPiece[0].length; col++) {
          piece[numOldCols-col][row] = fallingPiece[row][col];
        }
      }
    }
    newPiece = piece;
    
    // store old values to revert to if illegal
    boolean[][] oldPiece = fallingPiece;
    int oldRow = fallingPieceRow;
    int oldCol = fallingPieceCol;
    int oldNumRows = fallingPiece.length;
    int oldNumCols = fallingPiece[0].length;
    int newNumRows = oldNumCols;
    int newNumCols = oldNumRows;

    //adjust top left cell row to keep center row same
    int newRow = oldRow + oldNumRows/2 - newNumRows/2;
    //adjust top left cell col to keep center col same
    int newCol = oldCol + oldNumCols/2 - newNumCols/2;
    
    //rotates piece by setting old piece to new. adjusts location.
    fallingPiece = newPiece;
    fallingPieceRow = newRow; 
    fallingPieceCol = newCol;

    //undos if new position illegal
    if (!fallingPieceIsLegal()) {
        fallingPiece = oldPiece;
        fallingPieceRow = oldRow;
        fallingPieceCol = oldCol;
    }
  }
  
  void removeFullRows() {
    int[][][] newBoard = new int[rows][cols][3];
    int bottomRow = rows - 1; // highest row of newBoard that hasn't been initialized
    for (int row = rows-1; row >= 0; row--) { //checks from bottom to top
      boolean hasEmpty = false;
      for (int col = 0; col < cols; col++) {
        int[] boardColor = board[row][col];
        if (boardColor[0] == backgroundColor[0] && boardColor[1] == backgroundColor[1] && boardColor[2] == backgroundColor[2]) {
            hasEmpty = true;
            break;
        }
      }
      if (hasEmpty) {
        int[][] currRow = board[row];
        int[][] newBoardTopRow = newBoard[bottomRow];
        int[] currColor;
        int[] newCurrColor;
        for (int col = 0; col < cols; col++) {
          currColor = currRow[col];
          newCurrColor = newBoardTopRow[col];
          newCurrColor[0] = currColor[0];
          newCurrColor[1] = currColor[1];
          newCurrColor[2] = currColor[2];
        }
        bottomRow--;
      }
    }
    int rowsRemoved = bottomRow + 1; //empty rows to add on top
    for (; bottomRow >= 0; bottomRow--) {
      int[][] newBoardRow = newBoard[bottomRow];
      int[] currColor;
      for (int col = 0; col < cols; col++) {
        currColor = newBoardRow[col];
        currColor[0] = backgroundColor[0];
        currColor[1] = backgroundColor[1];
        currColor[2] = backgroundColor[2];
      }
    }
    this.board = newBoard;
    if (rowsRemoved == 1) {
      this.score += 40 * (this.level+1);
    } else if (rowsRemoved == 2) {
      this.score += 100 * (this.level+1);
    } else if (rowsRemoved == 3) {
      this.score += 300 * (this.level+1);
    } else if (rowsRemoved >= 4) {
      this.score += 1200 * (this.level+1);
    }
    this.linesCleared += rowsRemoved;
    if (this.linesCleared >= 60) {
      this.level = this.linesCleared / 10;
    }
  }
  
  void determineNextMoves() {
    brain.findBestMoves(fallingPieceID, nextFallingPieceID, board, backgroundColor);
    brainMoves = brain.bestMoves;
    numBrainMoves = brain.numBestMoves;
    currMove = 0;
  }
  
  void makeMove() {
    if (currMove < numBrainMoves) {
      int newMove = brainMoves[currMove];
      switch (newMove) {
        case(1): moveFallingPiece(0, -1); break;
        case (2): moveFallingPiece(0, 1); break;
        case (3): System.out.println("invalid move 3"); break; //rotateFallingPiece(false); 
        case (4): rotateFallingPiece(true); break;
        case (5): moveFallingPiece(1, 0); break;
      }
      currMove++;
    } else {
      //System.out.println("out of moves");
      //System.out.println();
    }
  }
  
  void update() {
    
    if (!gameOver) {
        // make moves according to what's determined by brain
        if (this.currMove < this.numBrainMoves && this.currMove < numMovesBeforeGravity) {
          int speedFactor = 5;
          for (int i = 0; i < speedFactor; i++) makeMove();
        } else {
          // gravity
          if (!moveFallingPiece(1, 0)) {
              placeFallingPiece();
              removeFullRows();
              newFallingPiece();
              if (!fallingPieceIsLegal()) { 
                gameOver = true; //game ends if new piece is immmediately illegal
              } else {
                determineNextMoves();
              }
          }
        }
    }
  }
  
  void drawBoard() {
    //TOP TWO ROWS HIDDEN
    for (int r = 2; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
            int[] Color = board[r][c];
            fill(Color[0], Color[1], Color[2]);
            rect(boardMargin + cellMargin + cellSize * c, boardMargin + cellMargin + cellSize * (r-2), cellColorSize, cellColorSize);
        }
    }
  }
  
  void drawFallingPiece() {
   for (int r = 0; r < fallingPiece.length; r++) {
      for (int c = 0; c < fallingPiece[0].length; c++) {
        if (fallingPiece[r][c]) {
          fill(fallingPieceColor[0], fallingPieceColor[1], fallingPieceColor[2]);
          rect(boardMargin + cellMargin + cellSize * (fallingPieceCol+c), boardMargin + cellMargin + cellSize * (fallingPieceRow+r-2), cellColorSize, cellColorSize);
        }
      }
    }
  }
  
  void drawNextFallingPiece(int x, int y) {
    for (int r = 0; r < nextFallingPiece.length; r++) {
      for (int c = 0; c < nextFallingPiece[0].length; c++) {
        if (nextFallingPiece[r][c]) {
          fill(nextFallingPieceColor[0], nextFallingPieceColor[1], nextFallingPieceColor[2]);
          rect(x + cellSize * c, y + cellSize * r, cellColorSize, cellColorSize);
        }
      }
    }
  }
  
  void show() {
    drawNextFallingPiece(725, 250);
    drawBoard();
    drawFallingPiece();
    fill(255);
    text("Score: " + this.score, 675, 570);
    text("Lines: " + this.linesCleared, 675, 600);
    text("Level: " + this.level, 675, 630);
  }
}
