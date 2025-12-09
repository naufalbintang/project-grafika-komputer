import processing.sound.*; 

// ==========================================
// --- BAGIAN 0: KONFIGURASI GAME (TWEAK) ---
// ==========================================

// 1. PENGATURAN VISUAL & UKURAN (BARU DI SINI)
// ------------------------------------------------
// Ukuran Roket
float SHIP_W = 60;            // Lebar roket (Pixel)
float SHIP_H = 60;            // Tinggi roket (Pixel)
// Ukuran UFO
float UFO_W = 75;             // Lebar UFO
float UFO_H = 60;             // Tinggi UFO

// 2. PENGATURAN KESULITAN & FISIKA
// ------------------------------------------------
int   TOTAL_UFO = 2;          // Jumlah UFO
float UFO_MIN_SPEED = 0.25;    // Kecepatan min UFO
float UFO_MAX_SPEED = 1.0;    // Kecepatan max UFO

float GRAVITY_FORCE = 0.04;   // Gravitasi
float THRUST_POWER = 0.15;    // Kekuatan mesin
float ROTATION_SPEED = 0.1;   // Kecepatan putar
float AIR_FRICTION = 0.5;     // Gesekan udara

// 3. PENGATURAN AREA
// ------------------------------------------------
int   LANDING_PAD_W = 80;     // Lebar landasan pacu

// --- HITBOX OTOMATIS (Jangan diubah jika bingung) ---
// Radius tabrakan dihitung otomatis setengah dari lebar roket agar pas
float SHIP_COLLISION_R = SHIP_W / 2.0; 

// ==========================================
// --- AKHIR KONFIGURASI --------------------
// ==========================================

// --- bagian 1: variabel global ---
SoundFile soundThrust, soundCrash, soundWin;
PImage ship, ufoImage; 

int[] moon;
int landingX = 0;
String crashMessage = ""; 

PVector pos = new PVector( 150, 20 );
PVector speed = new PVector( 0, 0 );
PVector g = new PVector( 0, GRAVITY_FORCE ); 
float a = 0; 
float acc = 0; 

// --- bagian 2: status game ---
int WAITING = 1;   
int RUNNING = 2;   
int FINISHED = 3;  
int CRASHED = 4;   
int state = WAITING; 

// --- bagian 3: variabel obstacle & partikel ---
ArrayList<Obstacle> obstacles; 
ArrayList<Particle> particles = new ArrayList<Particle>(); 

// --- bagian 4: class obstacle (ufo) ---
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

    if (pos.x < 0 || pos.x + size.x > width) {
      velocity.x *= -1;
      pos.x = constrain(pos.x, 0, width - size.x); 
    }
    if (pos.y < 0 || pos.y + size.y > height - 50) {
      velocity.y *= -1;
      pos.y = constrain(pos.y, 0, height - 50 - size.y);
    }
    
    if ( acc > 0 ) {
      if (!soundThrust.isPlaying()) soundThrust.loop();
    } else {
      if (soundThrust.isPlaying()) soundThrust.stop();
    }
  }
  
  void display() {
    if (ufoImage != null) {
      imageMode(CENTER);
      // Menggunakan ukuran dari parameter UFO_W dan UFO_H
      image(ufoImage, pos.x + size.x/2, pos.y + size.y/2, size.x, size.y);
      imageMode(CORNER);
    } else {
      fill(255, 0, 0, 150);
      stroke(200, 0, 0);
      ellipse(pos.x + size.x/2, pos.y + size.y/2, size.x, size.y);
      fill(0); textAlign(CENTER); text("UFO", pos.x + size.x/2, pos.y + size.y/2);
    }
  }
  
  boolean checkCollision(PVector shipPos) {
    float closestX = constrain(shipPos.x, pos.x, pos.x + size.x);
    float closestY = constrain(shipPos.y, pos.y, pos.y + size.y);
    
    float distanceX = shipPos.x - closestX;
    float distanceY = shipPos.y - closestY;
    float distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);
    
    // Radius tabrakan kini dinamis mengikuti ukuran roket
    return distanceSquared < (SHIP_COLLISION_R * SHIP_COLLISION_R);
  }
}

// --- bagian 5: setup ---
void setup(){
    size(800, 800); 
    
    moon = new int[width/10+1];
    for(int i = 0; i < moon.length; i++){
        moon[i] = int(random(10)); 
    }
    
    landingX = int( random(3, moon.length-4))*10;
    
    try {
      ship = loadImage( "ROKET.png" );
      ufoImage = loadImage( "ufo.png" );
      soundThrust = new SoundFile(this, "thrust.wav");
      soundCrash = new SoundFile(this, "crash.mp3");
      soundWin = new SoundFile(this, "win.mp3");
      soundThrust.amp(0.5);
    } catch (Exception e) {
      println("WARNING: File aset (gambar/suara) tidak ditemukan.");
    }
    
    reset();
}

// --- bagian 6: fungsi reset ---
void reset() {
   for ( int i=0; i < moon.length; i++) moon[i] = int(random(10));
   landingX = int( random(3, moon.length-4))*10;
  
   pos = new PVector( 150, 20 );
   a = 0;      
   acc = 0;    
   speed = new PVector(0, 0); 
   crashMessage = ""; 
   
   obstacles = new ArrayList<Obstacle>();
   
   for (int i = 0; i < TOTAL_UFO; i++) {
     float x = random(100, width - 150);
     float y = random(80, height - 150);
     float vx = random(UFO_MIN_SPEED, UFO_MAX_SPEED);
     float vy = random(UFO_MIN_SPEED, UFO_MAX_SPEED);
     if(random(1) > 0.5) vx *= -1;
     if(random(1) > 0.5) vy *= -1;
     
     // Menggunakan parameter global UFO_W dan UFO_H
     obstacles.add(new Obstacle(x, y, UFO_W, UFO_H, vx, vy));
   }
}

// --- bagian 7: partikel ledakan ---
void createExplosion(float x, float y) {
  for (int i = 0; i < 50; i++) particles.add(new Particle(x, y));
}

void runExplosion() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update(); p.display();
    if (p.isDead()) particles.remove(i);
  }
}

class Particle {
  PVector position; PVector velocity; float lifespan;
  Particle(float x, float y) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(random(2, 5));   
    lifespan = 255.0; 
  }
  void update() { position.add(velocity); lifespan -= 5.0; }
  void display() { noStroke(); fill(255, 100, 0, lifespan); ellipse(position.x, position.y, 8, 8); }
  boolean isDead() { return (lifespan < 0); }
}

// --- bagian 8: draw loop ---
void draw(){
  background(255); 
  
  stroke(200, 200, 255);
  for(int i = 0; i<height/10; i++) line( 0, i*10, width, i*10);
  for ( int i=0; i<width/10; i++) line( i*10, 0, i*10, height );
  
  drawMoon();        
  drawLandingZone(); 
  
  for (Obstacle obs : obstacles) obs.display();
  
  drawShip(); 
  
  if ( state == WAITING ) drawWaiting();
  else if ( state == RUNNING ) update();      
  else if ( state == FINISHED ) drawFinished();
  else if ( state == CRASHED ) drawCrashed();
  
  runExplosion();
}

// --- bagian 9: input mouse ---
void mousePressed() {
 if ( state == WAITING ) state = RUNNING;
 else if ( state == FINISHED || state == CRASHED ) {
   reset(); state = RUNNING;
 }
}

// --- bagian 10: UI Teks ---
void drawWaiting() {
 textAlign( CENTER ); fill(0);
 textSize(20); text( "Click mouse to start", width/2, height/2);
 textSize(16); text( "Hindari " + TOTAL_UFO + " UFO dan mendaratlah!", width/2, height/2 + 30);
}

void drawFinished() {
 textAlign( CENTER ); fill( 0 ); textSize(20);
 if ( pos.x > landingX - LANDING_PAD_W/2 && pos.x < landingX + LANDING_PAD_W/2 ) {
   fill(0, 200, 0); text( "YOU LANDED THE SHIP!", width/2, height/2);
   fill(0); text( "SUCCESS!", width/2, height/2 - 30);
 } else {
   fill(255, 100, 0); text( "YOU MISSED THE PLATFORM!", width/2, height/2);
 }
 fill(0); text( "click to restart", width/2, height/2 + 30);
}

void drawCrashed() {
 textAlign( CENTER );
 fill(255, 0, 0); textSize(30);
 text( "CRASHED!", width/2, height/2 - 30);
 fill(0); textSize(20);
 text(crashMessage, width/2, height/2 + 10);
 text( "click to restart", width/2, height/2 + 50);
}

// --- bagian 11: Logic Update ---
void update(){
  PVector f = new PVector( cos( a+PI/2 ) * -acc, sin( a+PI/2 ) * -acc );
  
  if ( acc > 0 ) {
    acc *= AIR_FRICTION;
    if(acc < 0.001) acc = 0;
  }
  
  speed.add( g ); 
  speed.add( f ); 
  pos.add( speed ); 
  
  // 1. Cek Tabrakan UFO
  for (Obstacle obs : obstacles) {
    obs.update(); 
    if (obs.checkCollision(pos)) {
      state = CRASHED;
      crashMessage = "Tertabrak Pesawat Alien (UFO)!"; 
      triggerCrashEffect();
      return; 
    }
  }
  
  // 2. Cek Pendaratan vs Tabrakan Tanah
  // Logika ketinggian disesuaikan dengan tinggi roket (SHIP_H)
  if (pos.y > height - 50 - SHIP_H/2) { // Jarak aman kaki roket
      
      // Cek apakah horizontal (x) berada di dalam area landing pad?
      if ( pos.x > landingX - LANDING_PAD_W/2 && pos.x < landingX + LANDING_PAD_W/2 ) { 
         pos.y = height - 50 - SHIP_H/2; 
         speed = new PVector(0, 0); 
         state = FINISHED;
         if (soundThrust != null) soundThrust.stop();
         if (soundWin != null) soundWin.play(); 
         acc = 0;
      } 
      // GAGAL
      else if (pos.y > height - 20 - SHIP_H/2 ) {
         pos.y = height - 20 - SHIP_H/2;
         speed = new PVector(0, 0); 
         state = CRASHED; 
         crashMessage = "Menabrak Permukaan Bulan!"; 
         triggerCrashEffect();
         acc = 0;
      }
  }
}

void triggerCrashEffect() {
   if (soundThrust != null) soundThrust.stop();
   if (soundCrash != null) soundCrash.play();  
   createExplosion(pos.x, pos.y); 
   speed = new PVector(0, 0); 
   acc = 0;
}

// --- bagian 12: Visual ---
void drawMoon() {
   stroke(0); fill(255, 200, 0, 60); 
   beginShape(); vertex(0, height);
   for ( int i=0; i < moon.length; i++) vertex( i * 10, height - 20 - moon[i] );
   vertex(width, height); endShape(CLOSE);
}

void drawLandingZone() {
   fill(128, 200);
   // Menggunakan parameter LANDING_PAD_W
   rect( landingX - LANDING_PAD_W/2, height - 50, LANDING_PAD_W, 10); 
   line( landingX - 30, height - 20 - moon[landingX/10-3], landingX - 20, height - 40 );
   line( landingX + 30, height - 20 - moon[landingX/10 +3], landingX + 20, height - 40 );
}

void drawShip() {
 pushMatrix(); translate(pos.x, pos.y); rotate(a); noFill();
 
 // Efek api mengikuti ukuran roket
 for ( int i=4; i >= 0; i--) {
   stroke(255, i*50, 0); fill(255, i*50, 20);
   // Api digambar sedikit di bawah roket (+SHIP_H/2)
   ellipse( 0, SHIP_H/2 + 25, min(1, acc*10) * i*4, min(1, acc*10) * i*10);
 }
 
 if (ship != null) {
   // MENGGUNAKAN PARAMETER SHIP_W dan SHIP_H
   // -SHIP_W/2 agar gambar tepat di tengah (centered)
   image( ship, -SHIP_W/2, -SHIP_H/2, SHIP_W, SHIP_H );
 }
 popMatrix(); 
}

// --- bagian 13: Input Keyboard ---
void keyPressed() {
 if ( keyCode == LEFT ) a -= ROTATION_SPEED;
 if ( keyCode == RIGHT ) a += ROTATION_SPEED;
 if ( keyCode == UP ) {
   acc += THRUST_POWER;
   acc = min( acc, 1.0); 
 }
 if (keyCode == ' '){
     if ( state == WAITING ) state = RUNNING;
     else if ( state == FINISHED || state == CRASHED ) {
       reset(); state = RUNNING;
   }
 }
}
