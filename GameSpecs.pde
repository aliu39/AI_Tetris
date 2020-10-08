
/* TETRIS "RULES" GLOBALS */

int TETRIS_ROWS = 22;
int TETRIS_COLS = 10;

int numMovesBeforeGravity = 100;

// From tetris guide:
// Seven "standard" pieces (tetrominoes)
boolean[][] iPiece = {
    {  true,  true, true, true }
};

boolean[][] jPiece = {
    {  true, false, false },
    {  true,  true,  true }
};

boolean[][] lPiece = {
    { false, false,  true },
    {  true,  true,  true }
};

boolean[][] oPiece = {
    {  true,  true },
    {  true,  true }
};

boolean[][] sPiece = {
    { false,  true,  true },
    {  true,  true, false }
};

boolean[][] tPiece = {
    { false,  true, false },
    {  true,  true,  true }
};

boolean[][] zPiece = {
    {  true,  true, false },
    { false,  true,  true }
};

boolean[][][] tetrisPieces= { iPiece, jPiece, lPiece, oPiece, sPiece, tPiece, zPiece };

/*
app.tetrisPieceColors = { "red", "yellow", "indigo", 
                        "magenta", "cyan", "green", "orange" } */

int[][] tetrisPieceColors = {{255,0,0}, {255,255,0}, {75,0,130}, {255,0,255}, 
                              {0,255,255}, {0,255,0}, {255,140,0}};
                              
int[] uniquePieceRotations = { 2, 4, 4, 1, 2, 4, 2}; // number of ways the piece can be rotated
