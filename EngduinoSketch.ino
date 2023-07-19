#include <EngduinoButton.h>
#include <EngduinoLEDs.h> 
#include <EngduinoAccelerometer.h>
#include <Wire.h>
#include <string.h>
#include <stdlib.h>

//In setup() we initialise the Accelerometer and the serial port
//so that we can send data to the Proccesing program on the computer
void setup() 
{
  EngduinoAccelerometer.begin();
  EngduinoButton.begin(); 
  Serial.begin(9600);
  EngduinoLEDs.begin(); 
 
  //We provide some visual feedback to the player that the engduino has started and has initialised its sensors
  EngduinoLEDs.setAll(BLUE);
  delay(1500);
  EngduinoLEDs.setAll(OFF);
}

/*
In FindDirrection we find the direction in which the engduino is 
pointed to and return a string describing the position of the engduino
This can be done due to our observation of how values are changing.
We have defined 5 main position for the engduino that are useful for this program:
0. "LEDsUp" - the engduino is positioned horizontally with the LEDs up
1. "LEDsDown" - the engduino is positioned horizontally with the LEDs down
2. "Right" - the engduino is positioned vertically with the LEDs on the right side
3. "Left" - the engduino is positioned vertically with the LEDs on the left side
4. "Onward" - the engduino is positioned vertically with the LEDs on the front side
5. "Backward" - - the engduino is positioned vertically with the LEDs on the rear side
*/

int FindDirection(float x, float y, float z)
{
  if(z < 0)
    z += 0.45; //This has the role of adjusting the value of z as we don't want to have
               // to move the engduino too much so that we can make faster moves.
    
  if(abs(z) > abs(x) && abs(z) > abs(y))
      if(z > 0)
        return 1;  //LEDs down
      else
        return 0;  //LEDs up
        
  if(abs(y) > abs(x) && abs(y) > abs(z))
    if(y > 0)
      return 2; //Right
    else
      return 3; //Left

  if(x > 0)
    return 4; //Onward
  return 5; //Backward
}

void VisualFeedback(int option)
{ 
  //We create any visual feedback for the "LEDsUp" as it's just an intermediary position without an actual role in the game
  EngduinoLEDs.setAll(OFF);
  switch(option)
  {
    case 1:
    case 6:
    {
      EngduinoLEDs.setAll(GREEN);
      break;
    }
    
    case 4:
    {
      for(int led=9; led <=13; led++)
        EngduinoLEDs.setLED(led, BLUE);
      break;
    }
    
    case 5:
    {
      for(int led=0; led <=6; led++)
        EngduinoLEDs.setLED(led, RED);
      break;
    }
    
    case 2:
    {
      for(int led=6; led <=9; led++)
        EngduinoLEDs.setLED(led, YELLOW);
      break;
    }
    
    case 3:
    {
      for(int led=13; led <=15; led++)
        EngduinoLEDs.setLED(led, MAGENTA);
      EngduinoLEDs.setLED(0, MAGENTA);
      break;
    }
  }
}

void loop() 
{  
  int option;
  //We check if the button was pressed. If it wasn't, we check the accelerometer.
  if (EngduinoButton.wasPressed())
    option = 6;
  else
  {
    float accelerations[3];
    EngduinoAccelerometer.xyz(accelerations);
    option = FindDirection(accelerations[0], accelerations[1], accelerations[2]);
  }
  
  VisualFeedback(option);
  
  char optionStr[5];
  itoa(option,optionStr,10);
  char response[30];
  memcpy(response, "SNAKE@", 4);  //Send the string "SNAKE@" at the beggining of each message so that the PC knows that the data is coming from the Engduino
  memcpy(response + 4, optionStr, strlen(optionStr) + 1); 
  Serial.println(response);
  delay(150);
}
