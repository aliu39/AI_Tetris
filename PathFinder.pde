class PathFinder {
  
  class Position implements Comparable {
    int row;
    int col;
    int rotation;
    
    Position(int r, int c, int t) {
      this.row = r;
      this.col = c;
      this.rotation = t;
    }
    
    Position(Position oldPos, int dr, int dc, int dt) {
      this.row = oldPos.row + dr;
      this.col = oldPos.col + dc;
      this.rotation = oldPos.rotation + dt;
    }
    
    @Override
    public boolean equals(Object obj) {
      Position other = (Position)obj;
      return this.row == other.row && this.col == other.col && this.rotation == other.rotation;
    }
    
    //won't be used
    @Override
    public int hashCode() {
      return ((Integer)(this.row+this.col+this.rotation)).hashCode();
    }
    
    //arbitrary compareTo function, as this won't be used (still consistent w equals)
    @Override
    public int compareTo(Object obj) {
      if (this.equals(obj)) {
        return 0;
      } else {
        return -1;
      }
    }
    
  }
  
  float heightFactor; // [0,1) factors to rate end positions
  float linesFactor;
  float holesFactor;
  float bumpFactor;
  
  float pos1Factor;
  float pos2Factor;
  
  Stack<Position> endPositions; //possible end positions to evaluate
  Stack<Position> tempEndPositions;
  Position bestReachablePos;
  Stack<Integer> bestMoves; // most efficient sequence of moves to reach bestReachablePos
  Set<Position> visitedPositions;
  
  boolean[][] board;
  boolean[][] tempBoard;
  int rows;
  int cols;
  
  boolean[][] fallingPiece;
  int pieceID; // index of fallingPiece in global fallingPieces array
  int nextPieceID;
  int tempID;
  int fallingPieceRow;
  int fallingPieceCol;
  int numRotations; // number of unique rotations the piece has
  int tempNumRotations;
  
  PathFinder(int piece, int nextPiece, int[][][] board, int[] backgroundColor, float ah, float l, float h, float b, float f, float s) {
    // convert input game board into a boolean deep copy; initialize falling piece
    this.rows = board.length;
    this.cols = board[0].length;
    this.board = new boolean[rows][cols];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        int[] boardColor = board[r][c];
        if (boardColor[0] != backgroundColor[0] || boardColor[1] != backgroundColor[1] || boardColor[2] != backgroundColor[2]) {
          this.board[r][c] = true; //occupied by placed piece
        }
      }
    }
    this.fallingPiece = tetrisPieces[piece];
    this.pieceID = piece;
    this.nextPieceID = nextPiece;
    this.numRotations = uniquePieceRotations[piece]; // num of ways piece can be rotated
    
    // init moves, and rating heuristic factors
    this.endPositions = null;
    this.tempEndPositions = null;
    this.bestMoves = null; // initialized / overwritten by findMovesToReach()
    
    this.heightFactor = ah;
    this.linesFactor = l;
    this.holesFactor = h;
    this.bumpFactor = b;

    this.pos1Factor = f;
    this.pos2Factor = s;
    
  }
  
  // iterate through endPositions and determine if actually reachable
  // first calc rating of given pos, and if lower than found reachable ones, skip
  // if better rating than current best AND reachable, store pos and moves to reach it
  void findBestMoves() {
    findPossibleEndPositions();
    int n = endPositions.size();
    float bestRating = Float.NEGATIVE_INFINITY;
    for (int i = 0; i < n; i++) {
      Position pos = endPositions.pop();
      float pos1Rating = getRating(pos);
      float pos2Rating = Float.NEGATIVE_INFINITY;
      boolean pos2Possible = false;
      float betterRating = pos1Rating;
      
      Stack<Integer> moves = findMovesToReach(pos);
      if (moves != null) {
        nextPiece(pos);
        findPossibleEndPositions();
        int m = endPositions.size();
        for (int j = 0; j < m; j++) {
          Position pos2 = endPositions.pop();
          float rating = getRating(pos2);
          if (rating > pos2Rating) {
            if (findMovesToReach(pos2) != null) {
              pos2Rating = rating;
              pos2Possible = true;
            }
          }
        }
        restoreCurrPiece();
        if (pos2Possible) {
          float combinedRating = (pos1Rating * this.pos1Factor + pos2Rating * this.pos2Factor);
          if (combinedRating > betterRating || (combinedRating == betterRating && random(1) < 0.5)) {
            betterRating = combinedRating;
          }
        } else {
          betterRating = 0; //gives 0 rating to move causing game over next turn  
        }
        if (betterRating > bestRating || (betterRating == bestRating && random(1) < 0.5)) {
          bestRating = betterRating;
          this.bestReachablePos = pos;
          this.bestMoves = moves;
        }
      }
    }
    // assert this.bestMoves != null
    /*
    if (this.bestMoves == null) {
      System.out.println("NO REACHABLE END POSITIONS / MOVES FOUND");
    }*/
  }
  
  private void nextPiece(Position pos) {
    this.tempBoard = board;
    this.board = removeFullRows(placeFallingPiece(pos));
    this.tempID = this.pieceID;
    this.pieceID = this.nextPieceID;
    this.fallingPiece = tetrisPieces[this.pieceID];
    this.tempNumRotations = this.numRotations;
    this.numRotations = uniquePieceRotations[this.pieceID];
    this.tempEndPositions = this.endPositions;
  }
  
  private void restoreCurrPiece() {
    this.board = this.tempBoard;
    this.pieceID = this.tempID;
    this.fallingPiece = tetrisPieces[this.pieceID];
    this.numRotations = uniquePieceRotations[this.pieceID];
    this.endPositions = this.tempEndPositions;
  }
  
  private void printBestMoves() {
    for (int i = 0; i < this.bestMoves.size(); i++) {
      System.out.print(this.bestMoves.get(i) + "-");
    }
    System.out.println();
  }
  
  private void findPossibleEndPositions() {
    //int fallingPieceHeight;
    this.endPositions = new Stack<Position>();
    for (int r = 2; r <= rows; r++) { // don't include off the screen
      for (int c = 0; c < cols; c++) {
        for (int t = 0; t < numRotations; t++) {
          if (t > 0) rotateTheoreticalFallingPiece();
          if (isValidEndPos(r, c)) {
              endPositions.push(new Position(r, c, t));
          }
        }
        this.fallingPiece = tetrisPieces[this.pieceID]; //reset rotation
      }
    }
  }
  
  private boolean isValidEndPos(int r, int c) {
    if (!fallingPieceIsLegal(r, c)) {
      return false;
    }
    for (int x = 0; x < fallingPiece.length; x++) {
      for (int y = 0; y < fallingPiece[0].length; y++) {
        if (fallingPiece[x][y]) {
          int boardRow = x + r;
          int boardCol = y + c;
          if ((boardRow+1 >= this.rows) || this.board[boardRow+1][boardCol]) {
            return true;
          }
        }
      }
    }
    return false;
  }
  
  private Stack<Integer> findMovesToReach(Position endPos) {
    // if sequence of moves to get to pos exists, return true
    // in this case, OVERWRITE bestMoves if update is true
    Stack<Integer> newMoves = new Stack<Integer>();
    
    // init. falling row, col
    this.fallingPiece = tetrisPieces[this.pieceID];
    fallingPieceRow = 0;
    int numFallingPieceCols = fallingPiece[0].length;
    fallingPieceCol = cols/2 - numFallingPieceCols / 2;
    
    // conduct DFS pathfind
    Position startPos = new Position(fallingPieceRow, fallingPieceCol, 0);
    visitedPositions = new HashSet<Position>();
    if (DFS(startPos, endPos, newMoves)) {
      this.fallingPiece = tetrisPieces[this.pieceID];
      return newMoves;
    } else {
      this.fallingPiece = tetrisPieces[this.pieceID];
      return null;
    }
  }
  
  // recursive depth-first path find
  private boolean DFS(Position currPos, Position endPos, Stack<Integer> moves) {
    
    int movesMade = moves.size();
    boolean movedDown = false;
    
    // apply gravity
    if (movesMade > 0 && movesMade % numMovesBeforeGravity == 0) { // simulates gravity in game
      if (!moveFallingPiece(1,0)) {
        return currPos.equals(endPos); // piece would be placed at currPos, which != endPos
      } else {
        movedDown = true; // for future un-doing if no paths found
        currPos = new Position(currPos,1,0,0);
      }
    }
    
    // base case--check if endPos reached or impossible to reach
    if (currPos.equals(endPos)) {
      return true;
    } else if (currPos.row > endPos.row) {
      return false;
    } else if (visitedPositions.contains(currPos)) {
      return false;
    } else {
      visitedPositions.add(currPos);
    }
    
    // if currently not at correct rotation, try rotating 
    if (currPos.rotation < endPos.rotation) {
      if (tryMove(4, currPos, endPos, moves, movesMade)) return true;  
    }
    
    /*
    if (currPos.rotation != endPos.rotation) { 
      if (((currPos.rotation + 1) % this.numRotations) == endPos.rotation) {
        if (tryMove(4, currPos, endPos, moves, movesMade)) return true;
      } else if (((endPos.rotation + 1) % this.numRotations) == currPos.rotation) {
        if (tryMove(3, currPos, endPos, moves, movesMade)) return true;
      } else {
        if (random(1) < 0.5) {
          if (tryMove(3, currPos, endPos, moves, movesMade)) return true;
          if (tryMove(4, currPos, endPos, moves, movesMade)) return true;
        } else {
          if (tryMove(4, currPos, endPos, moves, movesMade)) return true;
          if (tryMove(3, currPos, endPos, moves, movesMade)) return true;
        }
      }
    } */
    
    // if already correct rotation, or rotating doesn't lead to endPos
    if (currPos.col > endPos.col) { // currPos is to right of endPos
      if (tryMove(1, currPos, endPos, moves, movesMade)) return true; //left
      if (tryMove(5, currPos, endPos, moves, movesMade)) return true; //down
      if (tryMove(2, currPos, endPos, moves, movesMade)) return true; //right
    } else if (currPos.col < endPos.col) {
      if (tryMove(2, currPos, endPos, moves, movesMade)) return true;
      if (tryMove(5, currPos, endPos, moves, movesMade)) return true;
      if (tryMove(1, currPos, endPos, moves, movesMade)) return true;
    } else {
      if (tryMove(5, currPos, endPos, moves, movesMade)) return true;
      if (tryMove(2, currPos, endPos, moves, movesMade)) return true;
      if (tryMove(1, currPos, endPos, moves, movesMade)) return true;
    }
    
    //if (tryMove(0, currPos, endPos, moves, movesMade)) return true; //stall for natural gravity to take place
    
    // all moves are either invalid or can't reach the endPos; endPos is unreachable from this position
    if (movedDown) {
      moveFallingPiece(-1,0); // undo gravity by moving up
    }
    return false;
  }
  
  /* taking in a move code, curr/target position, and moves, tries updating 
     a position and recursively calling DFS. If DFS returns false it undos the move,
     moving fallingPiece back to its old position and popping move(s) off the stack */
  private boolean tryMove(int moveCode, Position currPos, Position endPos, Stack<Integer> moves, int movesMade) {
    
    /*if (moveCode == 3 || moveCode == 4) {
      List oldFallingState;
      int drot;
      if (moveCode == 3) {
        oldFallingState = rotateFallingPiece(false);
        if (currPos.rotation - 1 < 0) {
          drot = (this.numRotations-1) - currPos.rotation;
        } else {
          drot = -1;
        } 
      } else {
        oldFallingState = rotateFallingPiece(true);
        if (currPos.rotation + 1 >= this.numRotations) {
          drot = currPos.rotation * -1;
          if (drot != 0) System.out.println("max rotations");
        } else {
          drot = 1;
        }
      }
      
      if (oldFallingState != null) {
        moves.push(moveCode); // 3 is code for rotate left, 4 for rotate right
        if (DFS(new Position(currPos,0,0,drot), endPos, moves)) {
          return true;  
        } else {
          fallingPiece = (boolean[][])oldFallingState.get(0); //undo rotation
          fallingPieceRow = (int)oldFallingState.get(1);
          fallingPieceCol = (int)oldFallingState.get(2);
          moves.pop(); //remove rotate from moves
        }
      }
    } */ 
    
    switch (moveCode) {
      case (4): {
        List oldFallingState = rotateFallingPiece(true);
        if (oldFallingState != null) {
          moves.push(moveCode); // 3 is code for rotate left, 4 for rotate right
          if (DFS(new Position(currPos,0,0,1), endPos, moves)) {
            return true;  
          } else {
            fallingPiece = (boolean[][])oldFallingState.get(0); //undo rotation
            fallingPieceRow = (int)oldFallingState.get(1);
            fallingPieceCol = (int)oldFallingState.get(2);
            moves.pop(); //remove rotate from moves
          }
        }
        break;
      } case (1): {
        if (moveFallingPiece(0, -1)) {
          moves.push(1); // 1 is code for move left
          if (DFS(new Position(currPos,0,-1,0), endPos, moves)) {
            return true;  
          } else {
            moveFallingPiece(0, 1); // undo
            moves.pop(); //remove move from moves
          }
        }
        break;
      } case (2): {
        if (moveFallingPiece(0, 1)) {
          moves.push(2); // 2 is code for move right
          if (DFS(new Position(currPos,0,1,0), endPos, moves)) {
            return true;  
          } else {
            moveFallingPiece(0, -1); // undo
            moves.pop(); //remove move from moves
          }
        }
        break;
      } case (5): {
        if (moveFallingPiece(1, 0)) {
          moves.push(5); // 2 is code for move down
          if (DFS(new Position(currPos,1,0,0), endPos, moves)) {
            return true;  
          } else {
            moveFallingPiece(-1, 0); // undo
            moves.pop(); //remove move from moves
          }
        }
        break;
      } case (0): {
        // try stalling until gravity moves piece down (stall at least one)
        int numStall = 1;
        int x = movesMade + 1;
        while (x % numMovesBeforeGravity != 0) {
          numStall++;
          x++;
        }
        // assert numStall < numMovesBeforeGravity
        
        for (int i = 0; i < numStall; i++) {
          moves.push(0); // 0 is code for do nothing
        }
        if (DFS(new Position(currPos,0,0,0), endPos, moves)) { // new call to DFS will immediately result in gravity drop
          return true;  
        } else {
          for (int i = 0; i < numStall; i++) {
            moves.pop(); // remove move from moves
          }
        }
        break;
      }
    }
    return false;
  }
  
  // fallingPieceIsLegal at give (R,C) (top-left corner of falling piece)
  private boolean fallingPieceIsLegal(int R, int C) {
    for (int r = 0; r < fallingPiece.length; r++) {
      for (int c = 0; c < fallingPiece[0].length; c++) {
        if (fallingPiece[r][c]) {
            int boardCol = C+c;
            int boardRow = R+r;
            if (boardCol < 0 || boardRow < 0 
              || boardCol >= cols || boardRow >= rows) {
              return false; //out of board bounds
            }
            if (board[boardRow][boardCol]) {
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
    if (!fallingPieceIsLegal(fallingPieceRow, fallingPieceCol)) { //undos if new position illegal
      fallingPieceRow -= drow;
      fallingPieceCol -= dcol;
      return false;
    }
    return true; 
  }
  
  // doesn't actually change anything about fallingPiece row/col, only for rating possible end positions (rotation always succeeds)
  private void rotateTheoreticalFallingPiece() {
    boolean[][] newPiece = new boolean[fallingPiece[0].length][fallingPiece.length];
    int numOldCols = fallingPiece[0].length-1;
    for (int row = 0; row < fallingPiece.length; row++) {
      for (int col = 0; col < fallingPiece[0].length; col++) {
        newPiece[numOldCols-col][row] = fallingPiece[row][col];
      }
    }
    
    //rotates piece by setting old piece to new. adjusts location.
    fallingPiece = newPiece;
  }
  
  // actually rotates for purposes of simulating a move. returns old state (for undoing) if successful, null else
  private List rotateFallingPiece(boolean right) {
    boolean[][] newPiece = new boolean[fallingPiece[0].length][fallingPiece.length];
    
    int i;
    if (right) i = 1;
    else i = 3;
    
    for (int j = 0; j < i; j++) {
      int numOldCols = fallingPiece[0].length-1;
      for (int row = 0; row < fallingPiece.length; row++) {
        for (int col = 0; col < fallingPiece[0].length; col++) {
          newPiece[numOldCols-col][row] = fallingPiece[row][col];
        }
      }
    }
    
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
    if (!fallingPieceIsLegal(fallingPieceRow, fallingPieceCol)) {
      fallingPiece = oldPiece;
      fallingPieceRow = oldRow;
      fallingPieceCol = oldCol;
      return null;
    }
    
    List oldFallingState = new ArrayList();
    oldFallingState.add(oldPiece);
    oldFallingState.add(oldRow);
    oldFallingState.add(oldCol);
    return oldFallingState;
  }
  
  // returns deep copy of board that has falling piece placed in given end position
  boolean[][] placeFallingPiece(Position pos) {
    boolean[][] newBoard = new boolean[rows][cols]; //make DEEP copy of board
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (this.board[r][c]) {
          newBoard[r][c] = true;
        }
      }
    }
    
    int R = pos.row;
    int C = pos.col;
    int t = pos.rotation;
    for (int i = 0; i < t; i++) {
      rotateTheoreticalFallingPiece();  
    }
    
    if (fallingPieceIsLegal(R, C)) {
      for (int r = 0; r < fallingPiece.length; r++) {
          for (int c = 0; c < fallingPiece[0].length; c++) {
              if (fallingPiece[r][c]) {
                  int boardRow = R+r;
                  int boardCol = C+c;
                  newBoard[boardRow][boardCol] = true;
              }
          }
      }
    } else {
      System.out.println("PATHFIND PLACEFALLINGPIECE: FALLINGPIECEISLEGAL ASSERTION ERROR");
      System.out.println(R + " " + C);
      for (int r = 0; r < fallingPiece.length; r++) {
          for (int c = 0; c < fallingPiece[0].length; c++) {
              System.out.print(fallingPiece[r][c] + " ");
          }
          System.out.println();
      }
    }
    this.fallingPiece = tetrisPieces[this.pieceID]; //reset rotation
    return newBoard;
  }
  
  // rate a confirmed-reachable end position
  private float getRating(Position pos) {
    
    boolean[][] endBoard = placeFallingPiece(pos);
    
    float rating = 0.0;
    rating -= heightFactor * calcAggregateHeight(endBoard);
    rating += linesFactor * countFullRows(endBoard);
    rating -= holesFactor * countSpaces(endBoard);
    rating -= bumpFactor * calcBumpiness(endBoard);
    
    return rating;
  }
  
  private int calcAggregateHeight(boolean[][] B) {
    int h = 0;
    //top to bottom, column-wise: first block reached is height
    for (int c = 0; c < cols; c++) {
      int r;
      for (r = 0; r < rows; r++) {
        if (B[r][c]) {
          break;
        }
      }
      h += rows - r;  
    }
    return h;
  }
  
  private int countFullRows(boolean[][] B) {
    int fullCount = 0;
    boolean full;
    for (int row = rows-1; row >= 0; row--) { //checks from bottom to top
      full = true;
      for (int col = 0; col < cols; col++) {
        if (!B[row][col]) {
            full = false;
            break;
        }
      }
      if (full) {
        fullCount++;
      }
    }
    return fullCount;
  }
  
  private int countSpaces(boolean[][] B) {
    int spaces = 0;
    boolean reachedTile;
    //top to bottom, column-wise: count spaces after reachingTile
    for (int c = 0; c < cols; c++) {
      reachedTile = false;
      for (int r = 0; r < rows; r++) {
        if (B[r][c]) {
          reachedTile = true;
        } else {
          if (reachedTile) {
            spaces++;
          }
        }
      }
    }
    return spaces;
  }
  
  // sum of absolute differences of adjacent columns' heights
  private int calcBumpiness(boolean[][] B) {
    int b = 0;
    int prevColHeight = 0;
    int currColHeight = 0;
    //top to bottom, column-wise: first block reached is height
    for (int c = 0; c < cols; c++) {
      int r;
      for (r = 0; r < rows; r++) {
        if (B[r][c]) {
          break;
        }
      }
      currColHeight = rows - r;
      if (c > 0) {
        b += abs(currColHeight - prevColHeight);
      }
      prevColHeight = currColHeight;
    }
    return b;
  }
  
  boolean[][] removeFullRows(boolean[][] oldBoard) {
    boolean[][] newBoard = new boolean[rows][cols];
    int bottomRow = rows - 1; // highest row of newBoard that hasn't been initialized
    for (int row = rows-1; row >= 0; row--) { //checks from bottom to top
      boolean hasEmpty = false;
      for (int col = 0; col < cols; col++) {
        if (!oldBoard[row][col]) {
            hasEmpty = true;
            break;
        }
      }
      if (hasEmpty) {
        for (int col = 0; col < cols; col++) {
          newBoard[row][col] = oldBoard[row][col];
        }
        bottomRow--;
      }
    }
    int rowsRemoved = bottomRow + 1; //empty rows to add on top
    for (; bottomRow >= 0; bottomRow--) {
      for (int col = 0; col < cols; col++) {
        newBoard[bottomRow][col] = false;
      }
    }
    return newBoard;
  }
  
}
