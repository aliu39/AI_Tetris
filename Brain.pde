import java.util.Random;
import java.util.*;
/* Brain using PathFinder, an object capable of rating all possible
   end positions given a board and fallingPieceID, and then finding 
   the move sequence to the best reachable position */

class Brain {
  
  // heuristics for evaluating end positions using PathFinder. Value in [0.0, 1.0)
  float heightFactor;
  float linesFactor;
  float holesFactor;
  float bumpFactor;
  
  // heuristics for evaluating end positions of NEXT end pos. Value in [0.0, 1.0)
  float nextAH;
  float nextL;
  float nextH;
  float nextB;
  
  // for weighting immediate piece's placement vs next piece's placement
  float pos1Factor;
  float pos2Factor;
  
  int[] bestMoves;
  int numBestMoves;
  
  // default brain is randomized
  Brain() {
    heightFactor = random(1);
    linesFactor = random(1);
    holesFactor = random(1);
    bumpFactor = random(1);
    pos1Factor = random(1);
    pos2Factor = 1.0 - pos1Factor;
  }
  
  // create and run PathFinder, then store copy of found moves in allocated bestMoves array
  void findBestMoves(int piece, int nextPiece, int[][][] board, int[] backgroundColor) {
    
    PathFinder P = new PathFinder(piece, nextPiece, board, backgroundColor, heightFactor, linesFactor, holesFactor, bumpFactor, pos1Factor, pos2Factor);
    P.findBestMoves();
    
    Stack<Integer> moves = P.bestMoves;
    if (moves != null) {
      this.numBestMoves = moves.size();
      this.bestMoves = new int[numBestMoves];
      for (int i = numBestMoves-1; i >= 0; i--) {
        this.bestMoves[i] = moves.pop();
      }
    } else {
      this.numBestMoves = 0;
      this.bestMoves = null;
    }
  }
  
  //copy stats of another brain to self, for genetic algorithm
  void copy_traits(Brain other) {
    this.heightFactor = other.heightFactor;
    this.linesFactor = other.linesFactor;
    this.holesFactor = other.holesFactor;
    this.bumpFactor = other.bumpFactor;
    this.nextAH = other.nextAH;
    this.nextL = other.nextL;
    this.nextH = other.nextH;
    this.nextB = other.nextB;
    this.pos1Factor = other.pos1Factor;
    this.pos2Factor = other.pos2Factor;
  }
  
  void inherit_traits(Brain mom, Brain dad, float momWeight, float mutationRate) {
    this.heightFactor = mom.heightFactor * momWeight + dad.heightFactor * (1-momWeight);
    this.linesFactor = mom.linesFactor * momWeight + dad.linesFactor * (1-momWeight);
    this.holesFactor = mom.holesFactor * momWeight + dad.holesFactor * (1-momWeight);
    this.bumpFactor = mom.bumpFactor * momWeight + dad.bumpFactor * (1-momWeight);
    
    this.pos1Factor = mom.pos1Factor * momWeight + dad.pos1Factor * (1-momWeight);
    this.pos2Factor = 1-this.pos1Factor;
    
    //mutation
    if (random(1) < mutationRate) {
      float r = random(1);
      if (r < 0.2) {
        if (random(1) < 0.5) this.heightFactor += random(0.2);
        else this.heightFactor -= random(0.2);
        if (this.heightFactor < 0) this.heightFactor = 0;
      } else if (r < 0.4) {
        if (random(1) < 0.5) this.linesFactor += random(0.2);
        else this.linesFactor -= random(0.2);
        if (this.linesFactor < 0) this.linesFactor = 0;
      } else if (r < 0.6) {
        if (random(1) < 0.5) this.holesFactor += random(0.2);
        else this.holesFactor -= random(0.2);
        if (this.holesFactor < 0) this.holesFactor = 0;
      } else if (r < 0.8) {
        if (random(1) < 0.5) this.bumpFactor += random(0.2);
        else this.bumpFactor -= random(0.2);
        if (this.bumpFactor < 0) this.bumpFactor = 0;
      } else {
        if (random(1) < 0.5) this.pos1Factor += random(0.2);
        else this.pos1Factor -= random(0.2);
        if (this.pos1Factor < 0) this.pos1Factor = 0;
        this.pos2Factor = 1.0 - this.pos1Factor;
      }
    }
  }
}
