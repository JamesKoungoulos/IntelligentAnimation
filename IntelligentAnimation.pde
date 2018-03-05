/*
* James Koungoulos
* SID: 450325236
*/
import processing.video.*;
import processing.sound.*;
import beads.*;
import java.util.*;
import java.lang.*;

// sound  objects
SoundFile bgTrack;
SoundFile hitSound;

AudioContext audioCon;
Glide fgA;
Glide fgB;
WavePlayer wpA;
WavePlayer wpB;
Gain audioGain;

PImage monkeyFrame, bg;
int bgFramecount, characterFramecount;

int [][] pixKernel = {{0, 1, 0},
                   {1, 1, 1},
                   {0, 1, 0}};

float[][] centres = new float[5][2];
float[][] prevCentres = new float[5][2];

float fistX = 0;
float fistY = 0;

int attackRadius = 10;
float orbitCount = 0;

int xDisplacement = 375;
int yDisplacement = 200;
int score = 0; 
int health = 99999999; 

ArrayList<PImage> limbImages;
ArrayList<PImage> projectileImages;
ArrayList<float[]> alienPositions;

PImage fist;
PImage alien;
PImage hitEffect;

int enemyTimer;
boolean receding = false;

void setup() {
  size(1280, 720);
  frameRate(60);
  bgFramecount = 0;
  characterFramecount = 0;
  enemyTimer = 0;
  
  alienPositions = new ArrayList<float[]>();
  
  loadImages();
  setupSound();
}

void draw() {

  if (characterFramecount <= 938) {
    if (enemyTimer >= 15 && alienPositions.size() <= 25) {
      adjustRadius();
      spawnEnemy();
      enemyTimer = 0;
    }
    else {enemyTimer++;}
    moveCharacter();
    moveFist();
    moveEnemies();
    drawEnemies();
    drawStats();
  }
  else {
    exit();  
  }  
}

void drawStats() {
  
  textSize(32);
  text("Score: "+Integer.toString(score), 300, 500);
  text("Health: "+Integer.toString(health), 300, 600);

}

void moveCharacter() {
  
  ArrayList<float[]> leftHand = new ArrayList<float[]>();
  ArrayList<float[]> rightHand = new ArrayList<float[]>();
  ArrayList<float[]> leftFoot = new ArrayList<float[]>();
  ArrayList<float[]> rightFoot = new ArrayList<float[]>();

  ArrayList<float[]> markerPixels;
        
  bg = loadImage(sketchPath("") + "BG/"+nf(bgFramecount % 590, 4) + ".tif");
  monkeyFrame = loadImage(sketchPath("") + "MF/"+nf(characterFramecount % 938, 4) + ".tif");

  markerPixels = isolateMarkers(monkeyFrame);
  
  // calculate centre of marker pixels - this is the chest point
  centres[0] = calculateCentre(markerPixels);
  float cx = centres[0][0];
  float cy = centres[0][1];
  
  // categorise each marker pixel as part of a limb quadrant based on its location relative to the centre
  for (int i = 0; i < markerPixels.size(); i++) {
     float[] currentPixel = markerPixels.get(i);

     float x = currentPixel[0];
     float y = currentPixel[1];
     
     // otherwise place it in the correct limb list
     if (x < cx) {
       if (y > cy) {
         leftHand.add(currentPixel);
       }
       else if (y < cy) {
         leftFoot.add(currentPixel);
       }
     }
     else if (x > cx) {
       if (y > cy) {
         rightHand.add(currentPixel);
       }
       else if (y < cy) {
         rightFoot.add(currentPixel);
       }
     }
  }    
  
  centres[1] = calculateCentre(leftHand);
  centres[2] = calculateCentre(leftFoot);
  centres[3] = calculateCentre(rightHand);
  centres[4] = calculateCentre(rightFoot);
     
  // has crossed down into bottom left quadrant
  if (leftHand.size() == 0 ) {
    centres[1][0] = centres[2][0]; 
    centres[1][1] = centres[0][1]; 
  }
  // has crossed down into bottom right quadrant
  if (rightHand.size() == 0) {
    centres[3][0] = centres[4][0]; 
    centres[3][1] = centres[0][1]; 
  }
  // has crossed to bottom right quadrant
  if (leftFoot.size() == 0) {
      centres[2][0] = centres[0][0]; 
      centres[2][1] = centres[4][1]; 
  }
  // has crossed to bottom left quadrant
  if (rightFoot.size() == 0) {
      centres[4][0] = centres[0][0]; 
      centres[4][1] = centres[2][1]; 
  }
  
  // display the background video frame
  background(bg);

  drawBody(centres);
  prevCentres = centres;
  bgFramecount++;
  characterFramecount++;
  
  for (int i = 0; i < 5; i++) {
    if (boyHit(constrain(centres[i][0] + xDisplacement, 0, bg.width), constrain(centres[i][1] + yDisplacement, 0, bg.height), limbImages.get(i))) {
      imageMode(CENTER);
      image(hitEffect, constrain(centres[i][0] + xDisplacement, 0, bg.width), constrain(centres[i][1] + yDisplacement, 0, bg.height));
      hitSound.play();
      health -= 1;
    }
  }
}

void adjustRadius() {
 
  // increase/decrease the range of his fist
  if (attackRadius >= 400){        
    receding = true;
  }
  else if (attackRadius <= 50){ 
    receding = false;  
  }
  if (receding) {
    attackRadius -= 50;
  }
  else {
    attackRadius += 50;  
  } 
}

void spawnEnemy() {
  // pick a random location and spawn an enemy
  Random rand = new Random();
  // 1280 = video width, 50 = frame border buffer
  float newX = (float) rand.nextInt(1230) + 50; 
  float newY = (float) rand.nextInt(670) + 50; 
  
  // add this enemy to the ArrayList of enemies
  alienPositions.add(new float[] {newX, newY});
}

void moveEnemies() {
  for (float[] coords: alienPositions) {             
    coords[0] = constrain(coords[0] + 100 * cos(orbitCount), 0, bg.width);
    coords[1] = constrain(coords[1] + 100 * sin(3*orbitCount) / 2,  0, bg.height); 
  }
}

void drawEnemies() {
  
  imageMode(CENTER);
  
  for (float[] coords: alienPositions) {     
    image(alien, coords[0], coords[1]);
  }
  
}

void moveFist() {
      
    pushMatrix();
    
    translate(constrain(centres[0][0] + xDisplacement, 0, bg.width), constrain(centres[0][1] + yDisplacement - 35, 0, bg.height));
    
    fistX = attackRadius * cos(orbitCount);
    fistY = attackRadius * sin(orbitCount);
    
    drawFist(fistX, fistY);    
    
    popMatrix();

    if (fistHit(fistX, fistY)) {
      // play hit sound
      hitSound.play();    
      // increment score
      score += 50;
    }

    orbitCount += 0.5;
    
    // change the frequencies dependent on the position of the fist
    fgA.setValue(fistX);
    fgB.setValue(fistY);
}

boolean boyHit(float x, float y, PImage limbImg) {
  

  // check if the limb has collided with any existing aliens
  for (int i = 0; i < alienPositions.size(); i++) {     
      float aX1 = alienPositions.get(i)[0] - alien.width / 2;
      float aY1 = alienPositions.get(i)[1] - alien.height / 2;
      float aX2 = alienPositions.get(i)[0] + alien.width / 2;
      float aY2 = alienPositions.get(i)[1] + alien.height / 2;
      
      float fX1 = x - limbImg.width / 2;
      float fY1 = y - limbImg.height / 2;
      float fX2 = x + limbImg.width / 2;
      float fY2 = y + limbImg.height / 2;

      // if so, remove alien from list and return true;
      if ((aX1 < fX2) && (aX2 > fX1) && (aY1 < fY2) && (aY2 > fY1)){
        return true;
      }
      
  }
 
  // if no collision found
  return false;
  
}

boolean fistHit(float fX, float fY) {
  
  float globalFistX = constrain(centres[0][0] + xDisplacement, 0, bg.width) + fX;
  float globalFistY = constrain(centres[0][1] + yDisplacement - 35, 0, bg.height) + fY;

  // check if the fist has collided with any existing aliens
  for (int i = 0; i < alienPositions.size(); i++) {     
      float aX1 = alienPositions.get(i)[0] - alien.width / 2;
      float aY1 = alienPositions.get(i)[1] - alien.height / 2;
      float aX2 = alienPositions.get(i)[0] + alien.width / 2;
      float aY2 = alienPositions.get(i)[1] + alien.height / 2;
      
      float fX1 = globalFistX - fist.width / 2;
      float fY1 = globalFistY - fist.height / 2;
      float fX2 = globalFistX + fist.width / 2;
      float fY2 = globalFistY + fist.height / 2;

      // if so, remove alien from list and return true;
      if ((aX1 < fX2) && (aX2 > fX1) && (aY1 < fY2) && (aY2 > fY1)){
        alienPositions.remove(i);
        return true;
      }
      
  }
 
  // if no collision found
  return false;
}

void drawFist(float fistX, float fistY) {

  imageMode(CENTER);
  image(fist, fistX, fistY);
  
}

void drawBody(float[][] limbs) {
  
  drawHead(limbs[0]);
  drawTorso(limbs[0]);
  drawLeftArm(limbs[2]);
  drawLeftLeg(limbs[1]);
  drawRightArm(limbs[4]);
  drawRightLeg(limbs[3]);
  
}

void drawHead(float[] chest) {
  
  imageMode(CENTER);
  image(limbImages.get(0), constrain(chest[0] + xDisplacement, 0, bg.width), constrain(chest[1] - 100 + yDisplacement, 0, bg.height));
}

void drawTorso(float[] chest) {
       
  imageMode(CENTER);
  image(limbImages.get(1), constrain(chest[0] + xDisplacement, 0, bg.width), constrain(chest[1] + yDisplacement, 0, bg.height));
  
}

void drawLeftArm(float[] leftHand) {
  
  imageMode(CENTER);
  image(limbImages.get(2), constrain(leftHand[0] + xDisplacement - 15, 0, bg.width), constrain(leftHand[1] + yDisplacement + 35, 0, bg.height));
  strokeWeight(10);
  stroke(#FFFF00);
  line(constrain(leftHand[0] + xDisplacement, 0, bg.width), constrain(leftHand[1]+ yDisplacement + 15, 0, bg.height), constrain(centres[0][0] + xDisplacement - 20, 0, bg.width), constrain(centres[0][1] + yDisplacement - 45, 0, bg.height));

}


void drawLeftLeg(float[] leftFoot) {
  
  imageMode(CENTER);
  image(limbImages.get(3), constrain(leftFoot[0] + xDisplacement, 0, bg.width), constrain(leftFoot[1] + yDisplacement + 20, 0, bg.height));
  strokeWeight(10);
  stroke(#FFFF00);
  line(constrain(leftFoot[0] + xDisplacement, 0, bg.width), constrain(leftFoot[1]+ yDisplacement + 10, 0, bg.height), constrain(centres[0][0] + xDisplacement - 18, 0, bg.width), constrain(centres[0][1] + yDisplacement + 50, 0, bg.height));

  
}
void drawRightArm(float[] rightHand) {
  imageMode(CENTER);
  image(limbImages.get(4), constrain(rightHand[0] + xDisplacement + 15, 0, bg.width), constrain(rightHand[1] + yDisplacement + 35, 0, bg.height));
  strokeWeight(10);
  stroke(#FFFF00);
  line(constrain(rightHand[0] + xDisplacement, 0, bg.width), constrain(rightHand[1]+ yDisplacement + 15, 0, bg.height), constrain(centres[0][0] + xDisplacement + 20, 0, bg.width), constrain(centres[0][1] + yDisplacement - 45, 0, bg.height));

}

void drawRightLeg(float[] rightFoot) {
  
  imageMode(CENTER);
  image(limbImages.get(5), constrain(rightFoot[0] + xDisplacement, 0, bg.width), constrain(rightFoot[1] + yDisplacement + 20, 0, bg.height));
  strokeWeight(10);
  stroke(#FFFF00);
  line(constrain(rightFoot[0] + xDisplacement, 0, bg.width), constrain(rightFoot[1]+ yDisplacement + 10, 0, bg.height), constrain(centres[0][0] + xDisplacement + 18, 0, bg.width), constrain(centres[0][1] + yDisplacement + 50, 0, bg.height));

}

float[] calculateCentre(ArrayList<float[]> cluster) {
  
  float sumX = 0;
  float sumY = 0;
  int size = cluster.size();
  
  for (int i = 0; i < size; i++) {
    sumX += cluster.get(i)[0];
    sumY += cluster.get(i)[1];
  }  
  
  return new float[] {sumX/size, sumY/size};
}

PImage erodeDilate(PImage frame, int targetValue) {
  
  PImage processedImg = new PImage(frame.width, frame.height);
  boolean dilated = false;

  // for each pixel in the frame, compare with kernel values to determine whether to include in the new dilated/eroded image
  for (int y = 1; y < frame.height - 1; y++) {
    for (int x = 1; x < frame.width - 1; x++) {
      dilated = false;
      // Check the pixels in the kernel
      for (int i = x - 1, kx = 0; kx < 3; i++, kx++) {
        for (int j = y - 1, ky = 0; ky < 3; j++, ky++) {
          // if we find a white pixel and the corresponding kernel entry is true (1), then we include this pixel in the result image
          if (red(frame.pixels[i + j * frame.width]) == targetValue && pixKernel[kx][ky] == 1) {
            processedImg.pixels[x + y * frame.width] = color(targetValue);
            dilated = true;
            break; 
          }
          // otherwise copy the pixel to the new image untouched
          else {
            processedImg.pixels[x + y * frame.width] = frame.pixels[x + y * frame.width]; 
          }
        }

        if (dilated == true) { break; }
      }
    }
  }

  return processedImg; 
 
}

PImage reduceNoise(PImage frame) {
    
  for ( int i = 0; i < 2; i++) {
    frame = erodeDilate(frame, 0);  
  }  
  
  for ( int i = 0; i < 7; i++) {
    frame = erodeDilate(frame, 255);
  }
  
  return frame;
}

ArrayList<float[]> isolateMarkers(PImage frame) {
  
  ArrayList<float[]> markerPixels = new ArrayList<float[]>();
  
  // first, isolate the marker pixels by making them white and all others black
  for (int x = 0; x < frame.width; x++) { 
    for (int y = 0; y < frame.height; y++) {
      int loc = x + y * frame.width;
      color c = frame.pixels[loc]; 
      colorMode(HSB, 255);
      float hue = hue(c);
      float saturation = saturation(c);
      float brightness = brightness(c);
      colorMode(RGB, 255);

      if ((hue < 20 || hue > 230) && saturation > 20 && brightness > 150 && (red(c) > blue(c) + green(c) + 40)) {
        // set pixel to white
        frame.pixels[loc] = color(255);
      }
      else {
        frame.pixels[loc] = color(0);
      }
    }
  } 
  frame.updatePixels();
  
  // perform erosion and dilation on the image to reduce noise
  frame = reduceNoise(frame);
  
  // go through each pixel in the improved image and add it to the list if it is white
  for (int x = 0; x < frame.width; x++) { 
    for (int y = 0; y < frame.height; y++) {
      int loc = x + y * frame.width;
      color c = frame.pixels[loc]; 
      // white pixel
      if (c == color(255)) {
        // set pixel to white
        markerPixels.add(new float[] {x, y});
      }
    }
  } 
  
  return markerPixels;
  
}

void setupSound() {
  
   bgTrack = new SoundFile(this, sketchPath("") + "SOUNDS/OnePunch.mp3");
   bgTrack.loop();
   hitSound = new SoundFile(this, sketchPath("") + "SOUNDS/PunchSound.mp3");
    
   // create an audiocontext, and attach to it a two sets of frequency glides 
   audioCon = new AudioContext(); 
   fgA = new Glide(audioCon, 20, 50);
   fgB = new Glide(audioCon, 40, 50);

   // create two waveplayers, and attach to each frequency glide
   // both use a SINE wave buffer to mimic the sound of a fist swooping through the air
   wpA = new WavePlayer(audioCon, fgA, Buffer.SINE);
   wpB = new WavePlayer(audioCon, fgB, Buffer.SINE);
  
   // setup gain at low volume (so we can hear other sounds)
   audioGain = new Gain(audioCon, 1, 0.2);
   
   // link waveplayers to gain
   audioGain.addInput(wpA);
   audioGain.addInput(wpB);
  
   // link gain as output to out audiocontext
   audioCon.out.addInput(audioGain);
  
   // start audio processing
   audioCon.start();
 
}

void loadImages() {
  // load all limb images into an arraylist
  limbImages = new ArrayList<PImage>(6);
  limbImages.add(loadImage(sketchPath("") + "LIMBS/head.png"));
  limbImages.add(loadImage(sketchPath("") + "LIMBS/torso.png"));
  limbImages.add(loadImage(sketchPath("") + "LIMBS/leftHand.png"));
  limbImages.add(loadImage(sketchPath("") + "LIMBS/leftFoot.png"));
  limbImages.add(loadImage(sketchPath("") + "LIMBS/rightHand.png"));
  limbImages.add(loadImage(sketchPath("") + "LIMBS/rightFoot.png"));
  
  // load fist image
  fist = loadImage(sketchPath("") + "FIST/fist.png");
  
  // load hit effect image
  hitEffect = loadImage(sketchPath("") + "FIST/bazinga.png");

  // load enemy image
  alien = loadImage(sketchPath("") + "ENEMIES/alien.png");
  
  // resize images
  limbImages.get(0).resize(99, 105);
  limbImages.get(1).resize(63, 92);
  limbImages.get(2).resize(41, 41);
  limbImages.get(3).resize(24, 28);
  limbImages.get(4).resize(41, 41);
  limbImages.get(5).resize(24, 28);
  fist.resize(68, 68);
  hitEffect.resize(72, 38);
  alien.resize(110, 130);
}