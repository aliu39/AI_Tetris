Population pop;
int popsize = 100;
boolean PAUSED = false;

void setup() {
  size(1000, 1200); //size of the window (processing makes width smaller) + space on right for scoring
  frameRate(50);//increase this to make the blocks go faster
  pop = new Population(popsize);
  
  textSize(24);
}


void draw() { 
  background(0);
  if (!pop.allGamesDone) {
    if (!PAUSED) pop.update();
    pop.show();
  } else {
    pop = pop.geneticAlgo();
  }
}

void keyPressed() {
  if (key == CODED) {
    switch (keyCode) {
      case (LEFT): pop.currGame.moveFallingPiece(0, -1); break;
      case (RIGHT): pop.currGame.moveFallingPiece(0, 1); break;  
      case (DOWN): {
        //HARD DROP
        while (pop.currGame.moveFallingPiece(1, 0)) { //move down til it can't
          continue; //moveFallingPiece is already called
        }
        pop.currGame.placeFallingPiece();
        pop.currGame.newFallingPiece();
        if (!pop.currGame.fallingPieceIsLegal()) { 
            pop.currGame.gameOver = true;
        }
        break;
      }
      case (UP): pop.currGame.rotateFallingPiece(true);  break;
    }
  } else {
    switch (key) {
      case (' '): PAUSED = !PAUSED; break;
      case ('r'): pop = new Population(popsize); break;
      //case ('b'): test = bestGame; break;
    }
  }
}
