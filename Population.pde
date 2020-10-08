class Population {
  Game[] games;
  int size;
  int[] windowSize = {900, 1200}; // window size available to game board
  Game currGame;
  int currGameNum;
  Game[] sortedGames; // sorted from high score to low
  int gen = 0;
  boolean allGamesDone = false;
  int genTotal = 0;
  int genAvg = 0;
  int highScore = 0;
  int[] allTimeHigh = {0, 0};
  int[] allTimeAvg = {0, 0};
  
  // advanced stats
  float[] totalStats;
  float[] eliteStats;
  
  /* ordering of stats within stat arrays
  float avgAH;
  float avgL;
  float avgH;
  float avgB;
  float avgNAH;
  float avgNL;
  float avgNH;
  float avgNB;
  float avgPos1F;
  float avgPos2F;
  */
  
  Population(int s) {
    this.size = s;
    this.games = new Game[size];
    for (int i = 0; i < size; i++) {
      this.games[i] = new Game(windowSize);
    }
    this.currGame = games[0];
    this.sortedGames = new Game[size];
    
    this.totalStats = new float[10];
    this.eliteStats = new float[10];
  }
  
  void update() {
    if (!currGame.gameOver) {
      currGame.update();
    } else {
      //insert game to sorted position in sortedGames
      int currScore = currGame.score;
      int i = 0;
      while (i < currGameNum && currScore <= sortedGames[i].score) i++;
      Game temp1 = currGame;
      Game temp2 = null;
      while (i < currGameNum) {
        temp2 = sortedGames[i];
        this.sortedGames[i] = temp1;
        temp1 = temp2;
        i++;
      }
      this.sortedGames[i] = temp1;
      
      //update currGame + scores
      this.currGameNum++;
      
      this.highScore = sortedGames[0].score;
      this.genTotal += currScore;
      this.genAvg = this.genTotal / currGameNum;
      
      //update advanced stats
      updateTotalStats(currGame.brain);
      
      if (highScore > allTimeHigh[0]) {
        this.allTimeHigh[0] = highScore;
        this.allTimeHigh[1] = gen;
      }
      
      //update currGame
      if (currGameNum < size) {
        this.currGame = games[currGameNum];
      } else {
        //update genAvg high score after whole generation finished
        if (genAvg > allTimeAvg[0]) {
          allTimeAvg[0] = genAvg;
          allTimeAvg[1] = gen;
        }
        //wait for Tetris main to create next gen (via geneticAlgo())
        this.allGamesDone = true;
      }
    }
      
  }
  
  void show() {
    currGame.show();
    text("Game " + (pop.currGameNum+1) + " of " + pop.size, 675, 675);
    text("Generation: " + pop.gen, 675, 725);
    text("Generation Avg: " + pop.genAvg, 575, 775);
    text("Generation High: " + pop.highScore, 575, 825);
    text("All-time Best Avg: " + pop.allTimeAvg[0] + " (" + pop.allTimeAvg[1] + ")", 575, 875);
    text("All-time High: " + pop.allTimeHigh[0] + " (" + pop.allTimeHigh[1] + ")", 575, 925);
  }
  
  /*
  Population geneticAlgo() {
    
      Population next = new Population(size);
      next.gen = gen + 1;
      next.allTimeHigh = this.allTimeHigh;
      next.allTimeAvg = this.allTimeAvg;
      
      int numElite = int(size * 0.03) + 1;
      int numReproduce = int(size * 0.33) + 1;
      float mutationRate = 0.05;
      
      Random rand = new Random();
      
      // elite (top 3%) survive to next gen
      for (int i = 0; i < numElite; i++) {
        next.games[i].brain.copy_traits(sortedGames[i].brain);
        updateEliteStats(sortedGames[i].brain);
      }
      
      printAvgStats(this.size, numElite);
      
      // top 33% reproduce to form rest of new generation, with small chance of mutation
      for (int i = numElite; i < size; i++) {
        Brain mom = sortedGames[abs(rand.nextInt()) % numReproduce].brain;
        Brain dad = sortedGames[abs(rand.nextInt()) % numReproduce].brain;
        next.games[i].brain.inherit_traits(mom, dad, mutationRate);
      }
      
      return next;
  } */
  
  Population geneticAlgo() {
      printAvgStats(this.size);
    
      Population next = new Population(size);
      next.gen = gen + 1;
      next.allTimeHigh = this.allTimeHigh;
      next.allTimeAvg = this.allTimeAvg;
      
      int numReproduce = int(size * 0.7);
      float mutationRate = 0.05;
      Random rand = new Random();
      
      // worst 30% replaced with new offspring, with small chance of mutation
      int i;
      int[] top2 = new int[2];
      for (i = this.size-1; i >= this.size - numReproduce; i--) {
        top2[0] = rand.nextInt(numReproduce);
        top2[1] = rand.nextInt(numReproduce);
        while (top2[1] == top2[0]) top2[1] = rand.nextInt(numReproduce);
        for (int j = 0; j < 8; j++) {
          int r = rand.nextInt(numReproduce);
          while (r == top2[0] || r == top2[1]) r = rand.nextInt(numReproduce);
          if (top2[0] > top2[1]) {
            if (r < top2[0]) top2[0] = r;
          } else {
            if (r < top2[1]) top2[1] = r;
          }
        }
        Game mom = sortedGames[top2[0]];
        Game dad = sortedGames[top2[1]];        
        Brain momBrain = mom.brain;
        Brain dadBrain = dad.brain;
        float momWeight = mom.score/(mom.score+dad.score);
        next.games[i].brain.inherit_traits(momBrain, dadBrain, momWeight, mutationRate);
      }
      for (; i >= 0; i--) {
        next.games[i].brain.copy_traits(sortedGames[i].brain);
      }
      
      return next;
  }
  
  private void updateTotalStats(Brain B) {
    this.totalStats[0] += B.heightFactor;
    this.totalStats[1] += B.linesFactor;
    this.totalStats[2] += B.holesFactor;
    this.totalStats[3] += B.bumpFactor;
    this.totalStats[4] += B.nextAH;
    this.totalStats[5] += B.nextL;
    this.totalStats[6] += B.nextH;
    this.totalStats[7] += B.nextB;
    this.totalStats[8] += B.pos1Factor;
    this.totalStats[9] += B.pos2Factor;
  }
  
  private void updateEliteStats(Brain B) {
    this.eliteStats[0] += B.heightFactor;
    this.eliteStats[1] += B.linesFactor;
    this.eliteStats[2] += B.holesFactor;
    this.eliteStats[3] += B.bumpFactor;
    this.eliteStats[4] += B.nextAH;
    this.eliteStats[5] += B.nextL;
    this.eliteStats[6] += B.nextH;
    this.eliteStats[7] += B.nextB;
    this.eliteStats[8] += B.pos1Factor;
    this.eliteStats[9] += B.pos2Factor;
  }
  
  private void printAvgStats(int n) {
      System.out.println("--------------------------------------------------");
      System.out.println();
      System.out.println("GENERATION " + this.gen);
      System.out.println();
      
      // total
      System.out.println("TOTAL POPULATION");
      System.out.println("HeightFactor:     " + this.totalStats[0]/n);
      System.out.println("LinesFactor:      " + this.totalStats[1]/n);
      System.out.println("HolesFactor:      " + this.totalStats[2]/n);
      System.out.println("BumpinessFactor:  " + this.totalStats[3]/n);
      System.out.println("Weight:           " + this.totalStats[8]/n);
      System.out.println();
      
      // elite
      /*System.out.println("ELITE (TOP " + e + ")");
      System.out.println("HeightFactor:     " + this.eliteStats[0]/e + "   " + this.eliteStats[4]/e);
      System.out.println("LinesFactor:      " + this.eliteStats[1]/e + "   " + this.eliteStats[5]/e);
      System.out.println("HolesFactor:      " + this.eliteStats[2]/e + "   " + this.eliteStats[6]/e);
      System.out.println("BumpinessFactor:  " + this.eliteStats[3]/e + "   " + this.eliteStats[7]/e);
      System.out.println("Weight:           " + this.eliteStats[8]/e + "   " + this.eliteStats[9]/e);
      System.out.println(); */
      
      System.out.println("--------------------------------------------------");
      System.out.println();
      System.out.println();
  }
}
