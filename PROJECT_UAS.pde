int[] moon;
int landingX = 0;
PImage ship;
PVector pos = new PVector( 150, 20 );
PVector speed = new PVector( 0, 0 );
PVector g = new PVector( 0, 0.04 );
float a = 0;
float acc = 0;
int WAITING = 1;
int RUNNING = 2;
int FINISHED = 3;
int CRASHED = 4; // Status baru untuk tabrakan
int state = WAITING;

// Obstacle variables
ArrayList<Obstacle> obstacles;
PImage ufoImage;

class Obstacle {
  PVector pos;
  PVector size;
  PVector velocity;
  
  Obstacle(float x, float y, float w, float h, float vx, float vy) {
    pos = new PVector(x, y);
    size = new PVector(w, h);
    velocity = new PVector(vx, vy);
  }
  
  void update() {
    pos.add(velocity);
    
    // Bounce off walls
    if (pos.x < 0 || pos.x + size.x > width) {
      velocity.x *= -1;
      pos.x = constrain(pos.x, 0, width - size.x);
    }
    if (pos.y < 0 || pos.y + size.y > height - 50) {
      velocity.y *= -1;
      pos.y = constrain(pos.y, 0, height - 50 - size.y);
    }
  }
  
  void display() {
    // Gambar UFO image
    if (ufoImage != null) {
      imageMode(CENTER);
      image(ufoImage, pos.x + size.x/2, pos.y + size.y/2, size.x, size.y);
      imageMode(CORNER);
    } else {
      // Fallback jika gambar tidak ada
      fill(255, 0, 0, 150);
      stroke(200, 0, 0);
      strokeWeight(2);
      ellipse(pos.x + size.x/2, pos.y + size.y/2, size.x, size.y);
      
      // Gambar tanda UFO sederhana
      fill(255, 255, 0);
      ellipse(pos.x + size.x/2, pos.y + size.y/2 - 10, size.x * 0.6, size.y * 0.4);
      fill(0);
      textAlign(CENTER);
      textSize(16);
      text("UFO", pos.x + size.x/2, pos.y + size.y/2 + 5);
      strokeWeight(1);
    }
  }
  
  boolean checkCollision(PVector shipPos) {
    // Cek collision dengan radius roket (sekitar 40 pixel)
    float shipRadius = 50;
    
    // Cari titik terdekat pada rectangle
    float closestX = constrain(shipPos.x, pos.x, pos.x + size.x);
    float closestY = constrain(shipPos.y, pos.y, pos.y + size.y);
    
    // Hitung jarak dari pusat roket ke titik terdekat
    float distanceX = shipPos.x - closestX;
    float distanceY = shipPos.y - closestY;
    float distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);
    
    return distanceSquared < (shipRadius * shipRadius);
  }
}

void setup(){
    size(1700, 800);
    moon = new int[width/10+1];
    for(int i = 0; i < moon.length; i++){
        moon[i] = int(random(10));
    }
    landingX = int( random(3, moon.length-4))*10;
    ship = loadImage( "ROKET.png" );
    ufoImage = loadImage( "ufo.png" );  // Load gambar UFO
    reset();
}

void reset() {
   moon = new int[width/10+1];
   for ( int i=0; i < moon.length; i++) {
       moon[i] = int(random(10));
   }
   landingX = int( random(3, moon.length-4))*10;
  
   pos = new PVector( 150, 20 );
   a = 0;
   acc = 0;
   speed = new PVector(0, 0);
   
   // Buat obstacles baru
   obstacles = new ArrayList<Obstacle>();
   
   // Tambahkan 3-5 obstacle dengan posisi dan kecepatan random
   int numObstacles = int(random(3, 6));
   for (int i = 0; i < numObstacles; i++) {
     float x = random(100, width - 150);
     float y = random(80, height - 150);
     float w = 120;  // Ukuran sama untuk semua UFO
     float h = 80;  // Ukuran sama untuk semua UFO
     float vx = random(-1, 1);
     float vy = random(-1, 1);
     obstacles.add(new Obstacle(x, y, w, h, vx, vy));
   }
}

void draw(){
  background(255);
  stroke(200, 200, 255);
  for(int i = 0; i<height/10; i++){
    line( 0, i*10, width, i*10);
  }
  for ( int i=0; i<width/10; i++) {
   line( i*10, 0, i*10, height );
  }
  drawMoon();  
  drawLandingZone();
  
  // Gambar obstacles
  for (Obstacle obs : obstacles) {
    obs.display();
  }
  
  drawShip();
  
  if ( state == WAITING ) {
   drawWaiting();
  }
  else if ( state == RUNNING ) {
   update();
  }
  else if ( state == FINISHED ) {
   drawFinished();
  }
  else if ( state == CRASHED ) {
   drawCrashed();
  }
}

void mousePressed() {
 if ( state == WAITING ) {
   state = RUNNING;
 } else if ( state == FINISHED || state == CRASHED ) {
   reset();
   state = RUNNING;
 }
}

void drawWaiting() {
 textAlign( CENTER );
 fill(0);
 textSize(20); 
 text( "Click mouse to start", width/2, height/2);
 textSize(16);
 text( "Avoid the UFOs!", width/2, height/2 + 30);
}

void drawFinished() {
 textAlign( CENTER );
 fill( 0 );
 textSize(20); 
 if ( pos.x > landingX - 40 && pos.x < landingX + 40 ) {
   fill(0, 200, 0);
   text( "YOU LANDED THE SHIP!", width/2, height/2);
   fill(0);
   text( "SUCCESS!", width/2, height/2 - 30);
 } else {
   fill(255, 100, 0);
   text( "YOU MISSED THE PLATFORM!", width/2, height/2);
 }
 fill(0);
 text( "click to restart", width/2, height/2 + 30);
}

void drawCrashed() {
 textAlign( CENTER );
 fill(255, 0, 0);
 textSize(30); 
 text( "CRASHED!", width/2, height/2 - 20);
 fill(0);
 textSize(20);
 text( "You hit a UFO!", width/2, height/2 + 20);
 text( "click to restart", width/2, height/2 + 50);
}

void update(){
  PVector f = new PVector( cos( a+PI/2 ) * -acc, sin( a+PI/2 ) * -acc );
  if ( acc > 0 ) {
    acc *= 0.5;
    if(acc < 0.001){
      acc = 0;
    }
  }
  
  speed.add( g ); // menambah gravitasi langsung
  speed.add( f ); // menambah thrust dari roket
  pos.add( speed ); // update posisi
  
  // Update obstacles
  for (Obstacle obs : obstacles) {
    obs.update();
    
    // Cek collision dengan roket
    if (obs.checkCollision(pos)) {
      state = CRASHED;
      speed = new PVector(0, 0);
      acc = 0;
      return; // Keluar dari update jika crash
    }
  }
  
  // Cek landing
  if ( pos.x > landingX - 40 && pos.x < landingX + 40 && pos.y > height - 50 - 75 ) { 
     pos.y = height - 50 - 75;
     speed = new PVector(0, 0); 
     state = FINISHED;
     acc = 0;
  } else if (pos.y > height - 20 - 75 ) {
     pos.y = height - 20 - 75;
     speed = new PVector(0, 0); 
     state = CRASHED; // Ubah ke CRASHED karena mendarat di bulan
     acc = 0;
  } 
}

void drawMoon() {
   stroke(0);
   fill(255, 200, 0, 60);
   beginShape();
   vertex(0, height);
   for ( int i=0; i < moon.length; i++) {
       vertex( i * 10, height - 20 - moon[i] );
   }
   vertex(width, height);
   endShape(CLOSE);
}

void drawLandingZone() {
   fill(128, 200);
   rect( landingX - 30, height - 50, 60, 10);
   line( landingX - 30, height - 20 - moon[landingX/10-3], landingX - 20, height - 40 );
   line( landingX + 30, height - 20 - moon[landingX/10 +3], landingX + 20, height - 40 );
}

void drawShip() {
 pushMatrix();
 translate(pos.x, pos.y); 
 rotate(a);
 noFill();
 // Gambar api roket
 for ( int i=4; i >= 0; i--) {
   stroke(255, i*50, 0);
   fill(255, i*50, 20);
   ellipse( 0, 75, min(1, acc*10) * i*4, min(1, acc*10) * i*10); 
 }
 image( ship, -75, -75, 150, 150 ); 
 popMatrix();
}

void keyPressed() {
 if ( keyCode == LEFT ) {
   a -= 0.1;
 }
 if ( keyCode == RIGHT ) {
   a += 0.1;
 }
 if ( keyCode == UP ) {
   acc += 0.15;
   acc = min( acc, 1.0); 
 }
 
 if (keyCode == ' '){
     if ( state == WAITING ) {
     state = RUNNING;
   } else if ( state == FINISHED || state == CRASHED ) {
     reset();
     state = RUNNING;
   }
 }
}
