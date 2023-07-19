import processing.serial.*;

boolean GameOver = false;
boolean PauseActivated = false;
boolean PauseActivatedByButton = false;

Board MainBoard;
SnakeType Snake = new SnakeType();

void setup()
{
  size(840, 880);
  frameRate(4);
  MainBoard = new Board();
  ConnectToPort();
}

void draw()
{
  if(!ConnectedToPort)
    ConnectToPort();
    
  if(GameOver)
    Snake.GameOver();
  
  //We reset the board each time and we redraw it
  background(0);
  MainBoard.DrawBoard();
  MainBoard.GenerateFood();
  MainBoard.DrawFood();
  MainBoard.DrawScore();
  
  if(PauseActivated)
    MainBoard.DrawPause();
    
  Snake.MoveSnake();  
  Snake.DrawSnake();
  
  if(GameOver) //We will display the "Game Over" text on the screen now, but we stop the game only at the next call of draw()
      MainBoard.DrawGameOver();   
}

//  Engduino connection and initialisation code

  Serial Engduino;
  
  String PortCode = "SNAKE@";

  boolean ConnectedToPort = false;
  boolean TryingToConnectToPort = false;
  
  void ConnectToPort()
  {
    if(TryingToConnectToPort)
      return;
    
    TryingToConnectToPort = true;
    
    Serial tempEngduino = null;
    
    while(!ConnectedToPort)
    {    
      for(int port=0; port<Serial.list().length && !ConnectedToPort; port++)
      {
        tempEngduino = new Serial (this, Serial.list()[port], 9600);
        delay(100);
        if(tempEngduino.available() > 0)
        {
          String data = tempEngduino.readStringUntil('\n'); 
        
          //We check the PortCode to make sure we are connecting to the Engduino and not some other device
          if(data.substring(0,4).equals(PortCode))
          {
            ConnectedToPort = true;
            Engduino = tempEngduino;
          }
        }
      
        if(!ConnectedToPort)
          tempEngduino.stop();
      }
    }
  
  TryingToConnectToPort = false;
  }
  
  void serialEvent (Serial Engduino) //event function that is called each time we get data via the engduino port
  {
    if(!ConnectedToPort)
      return;
    if(Engduino.available() <= 0)
      return;
      
    String data = Engduino.readStringUntil('\n');
    if(data != null)
    {
      if(Snake == null)
        Snake = new SnakeType();
      Snake.ModifyState(data);
    }
  }
  
 //Board class  
class Board
{
  int BoardWidth = 40;
  int BoardHeight = 40;
  int PixelSize = 20;
  
  Point Food;
  
  //To make things simpler, we use an internal board with coordinates from 0 to 40
  //Then we use the StandardBoardCoordinates to get the actual coordinates
  Point StandardBoardCoordinates(Point p)
  {
    Point temp = new Point();
    temp.x = p.x * PixelSize + 20;
    temp.y = p.y * PixelSize + 20;
    return temp;
  }
  
  void DrawBoard()
  { 
      background(#FFFFCD);
      smooth();
     
      fill(#74AD92);
      stroke(0);
      strokeWeight(3);
      rect(20,20, 800, 800);
  }
  
  void DrawFood()
  {
    if(Food == null)
      GenerateFood();
    
    stroke(0);  
    strokeWeight(1);
    fill(0, 0, 255);
    Point temp = MainBoard.StandardBoardCoordinates(Food);
    rect(temp.x, temp.y, PixelSize, PixelSize);
  }
  
  void DrawScore()
  {
    PFont font = createFont ("Arial",22);
    textFont (font);
    fill(0, 102, 153);
    text("Score: " + (Snake.SnakeBody.size()-1), 400, 850);
  }
  
  void DrawGameOver()
  {
    PFont fontGO = createFont ("Serif",52);
    textFont (fontGO);
    fill(0, 0, 255);
    text("GAME OVER", 280,400);  
  }
  
  void DrawPause()
  {
    PFont fontGO = createFont ("Serif",52);
    textFont (fontGO);
    fill(0, 0, 255);
    text("PAUSE", 350,400);  
  }
  
  void GenerateFood()
  {
    if(Food != null)
      return;
      
    Food = new Point();
    Food.x = (int) random(0, BoardWidth-1);
    Food.y = (int) random(0, BoardHeight-1);
  }
}

//Point class
class Point
{
  int x, y;
  
  Point()
  {
  }
  
  Point(int x, int y)
  {
    this.x = x;
    this.y = y;
  }
  
  Point(Point p)
  {
    x = p.x;
    y = p.y;
  }
}


//Snake class
class SnakeType
{
  String Direction = "Up";
  ArrayList <Point> SnakeBody;
  
  SnakeType()
  {
    this.InitialiseSnake();
  }
 
  void InitialiseSnake()
  {
    SnakeBody = new ArrayList <Point>();
    SnakeBody.add(new Point(10,10)); // starting coordinates for the snake
    Direction = "Up"; // default direction of movement
  }
  
  void MoveSnake()
  {
    if(PauseActivated)
      return;
    
    //We make two copies of the coordinates of the head of the snake
    Point snakeHead = new Point(SnakeBody.get(0));
    Point previousSnakeHead = new Point(SnakeBody.get(0));
    
    switch(Direction)
    {
      case "Up": {snakeHead.y --; break;}
      case "Down": {snakeHead.y ++; break;}
      case "Right": {snakeHead.x ++; break;}
      case "Left": {snakeHead.x --; break;}
    }
    
    //We check to see if the snake hit its tail
    boolean SnakeHitTail = false;
    for(int i=1; i<SnakeBody.size() && !SnakeHitTail; i++)
    {
      Point tailPart = SnakeBody.get(i);
      if(snakeHead.x == tailPart.x && snakeHead.y == tailPart.y)
        SnakeHitTail = true;
    }
    
    if(SnakeHitTail || snakeHead.x < 0 || snakeHead.y < 0 || snakeHead.x >= MainBoard.BoardWidth || snakeHead.y >= MainBoard.BoardHeight) // game over
    {
      GameOver = true;
    }
    else
    {
      /*
        The snake translation mechanism is pretty straightforward.
        Rather then moving the coordinates of the head and each part of the tail, we just move the head.
        If we found food, we create another part of the tail in the place where the head was.
        (also, we mark the food as eaten = we delete it so that other food can generate)
        Otherwise, we simply move the last part of the tail in the place where the head was.
        */
      
      Point temp = SnakeBody.get(0);
      temp.x = snakeHead.x;
      temp.y = snakeHead.y;
      SnakeBody.add(1, previousSnakeHead);
      
      if(snakeHead.x == MainBoard.Food.x && snakeHead.y == MainBoard.Food.y) //the snake has found food
      {
        MainBoard.Food = null;
      }
      else
      {
        SnakeBody.remove(SnakeBody.size()-1);
      }
    }
  }
  
  void ModifyState(String data)
  {
    int option = int (data.charAt(4) - '0'); 
    
    if(option == 1) //Device is flat with the LEDs down
    {
      PauseActivated = true;
      return;
    }
    else
    {
      if(option == 6) //Button pressed
      {
        PauseActivatedByButton = !PauseActivatedByButton;
        PauseActivated =! PauseActivated; //<>//
        return;
      }
      else
      {
        if(PauseActivatedByButton)
          return;
        else
          PauseActivated = false;
        
        switch(option)
        {
           case 4:
           {
             this.Direction = "Up";
             break;
           }
           case 5:
           {
             this.Direction = "Down";
             break;
           }
           case 3:
           {
             this.Direction = "Left";
             break;
           }
           case 2:
           {
             this.Direction = "Right";
             break;
           }
        }
      }
    }
  }
  
  void DrawSnake()
  {     
    for(int i=0; i<SnakeBody.size(); i++)
    {
      stroke(220,0,50);
      strokeWeight(1);
      fill(0);
      Point p = MainBoard.StandardBoardCoordinates(SnakeBody.get(i));
      rect(p.x,p.y, MainBoard.PixelSize, MainBoard.PixelSize);
    }
  }
  
  void GameOver()
  {  //<>//
    delay(2000);
    background(0); //<>//
    MainBoard.Food = null; //<>//
    this.InitialiseSnake();
    GameOver = false;
  }
}