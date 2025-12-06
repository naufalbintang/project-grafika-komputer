import processing.sound.*; // 1. Import library

// Variabel Sound
SoundFile soundThrust;
SoundFile soundCrash;
SoundFile soundWin;


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
// List untuk menyimpan partikel ledakan
ArrayList<Particle> particles = new ArrayList<Particle>();

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
    
    // Di dalam void update()
    // suara mesin thrust kata ai
    if ( acc > 0 ) {
      // Jika gas ditekan & suara belum bunyi, mainkan (looping)
      if (!soundThrust.isPlaying()) {
        soundThrust.loop();}
    } else {
      // Jika tidak digas, matikan suara
      if (soundThrust.isPlaying()) {
        soundThrust.stop();}
    }
    
    // suara jatuh dan menang kata ai
    
    
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
    float shipRadius = 30;
    
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
    size(800, 800);
    moon = new int[width/10+1];
    for(int i = 0; i < moon.length; i++){
        moon[i] = int(random(10));
    }
    landingX = int( random(3, moon.length-4))*10;
    ship = loadImage( "ROKET.png" );
    ufoImage = loadImage( "ufo.png" );  // Load gambar UFO
    reset();
    
     // 2. Load file suara
    soundThrust = new SoundFile(this, "thrust.wav");
    soundCrash = new SoundFile(this, "crash.mp3");
    soundWin = new SoundFile(this, "win.mp3");
    
     // Atur volume jika perlu (0.0 sampai 1.0)
    soundThrust.amp(0.5); 
      
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
     float w = 75;  // Ukuran sama untuk semua UFO
     float h = 60;  // Ukuran sama untuk semua UFO
     float vx = random(-1, 1);
     float vy = random(-1, 1);
     obstacles.add(new Obstacle(x, y, w, h, vx, vy));
   }
}

////// kerjaan mecca //////
// gw cobain dulu yeah meledakk
void createExplosion(float x, float y) {
  // Buat 50 kepingan partikel sekaligus
  for (int i = 0; i < 50; i++) {
    particles.add(new Particle(x, y));
  }
}

// Panggil fungsi ini di dalam void draw() agar ledakan terlihat
void runExplosion() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isDead()) {
      particles.remove(i);
    }
  }
}

// Class Partikel Ledakan
class Particle {
  PVector position;
  PVector velocity;
  float lifespan;
  
  Particle(float x, float y) {
    position = new PVector(x, y);
    // Kecepatan acak ke segala arah
    velocity = PVector.random2D();
    velocity.mult(random(2, 5)); 
    lifespan = 255.0;
  }
  
  void update() {
    position.add(velocity);
    lifespan -= 5.0; // Partikel perlahan menghilang
  }
  
  void display() {
    noStroke();
    fill(255, 100, 0, lifespan); // Warna oranye api
    ellipse(position.x, position.y, 8, 8);
  }
  
  boolean isDead() {
    return (lifespan < 0);
  }
}
////// kerjaan mecca //////


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
  
  // Tambahkan ini agar ledakan tetap terlihat meskipun status CRASHED
  runExplosion();
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
      //nambahin sound qhaqha
      soundThrust.stop(); // Matikan suara mesin
      soundCrash.play();  // Mainkan suara ledakan sekali
      createExplosion(pos.x, pos.y); // Panggil fungsi ledakan visual
        
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
     soundThrust.stop();
     soundWin.play(); // Mainkan suara menang
     acc = 0;
  } else if (pos.y > height - 20 - 75 ) {
     pos.y = height - 20 - 75;
     speed = new PVector(0, 0); 
     state = CRASHED; // Ubah ke CRASHED karena mendarat di bulan
     soundThrust.stop();
     soundCrash.play(); // Mainkan suara hancur
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
 image( ship, -50, -50, 100, 100 ); 
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
