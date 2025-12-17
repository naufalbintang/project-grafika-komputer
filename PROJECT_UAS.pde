import processing.sound.*; 

// =======================================================
// === A. KONFIGURASI GAME: TWEAK & TUNING ===============
// =======================================================

// 1. PENGATURAN VISUAL & UKURAN
float SHIP_W = 100;            // Lebar roket (Pixel)
float SHIP_H = 100;            // Tinggi roket (Pixel)
float UFO_W = 75;             // Lebar UFO
float UFO_H = 60;             // Tinggi UFO
float SHIP_COLLISION_R = SHIP_W * 0.20; // Radius tabrakan (Hitbox)

// 2. PENGATURAN KESULITAN & FISIKA
int   TOTAL_UFO = 3;          // Jumlah UFO
float UFO_MIN_SPEED = 0.25;    // Kecepatan min UFO
float UFO_MAX_SPEED = 1.0;    // Kecepatan max UFO

float GRAVITY_FORCE = 0.04;   // Gravitasi
float THRUST_POWER = 0.15;    // Kekuatan mesin
float ROTATION_SPEED = 0.1;   // Kecepatan putar
float AIR_FRICTION = 0.5;     // Gesekan udara

// 3. PENGATURAN AREA
int   LANDING_PAD_W = 80;     // Lebar landasan pacu
int   STAR_COUNT = 200;      // Jumlah bintang statis

// =======================================================
// === B. VARIABEL GLOBAL (STATE) & ASET =================
// =======================================================

// 1. VARIABEL ASET (Gambar & Suara)
SoundFile soundThrust, soundCrash, soundWin;
PImage ship, ufoImage; 

// 2. VARIABEL FISIKA & ROKET
PVector pos = new PVector( 150, 20 ); // Posisi X, Y
PVector speed = new PVector( 0, 0 ); // Kecepatan X, Y
PVector g = new PVector( 0, GRAVITY_FORCE ); // Vektor Gravitasi
float a = 0; // Sudut (angle) rotasi
float acc = 0; // Akselerasi dorongan

// 3. VARIABEL GAME STATE
int WAITING = 1;   
int RUNNING = 2;   
int FINISHED = 3;  
int CRASHED = 4;   
int state = WAITING; 
String crashMessage = ""; 

// 4. VARIABEL AREA & OBSTACLE
int[] moon; // Array untuk kontur bulan
int landingX = 0; // Posisi X area pendaratan
ArrayList<Obstacle> obstacles;  // Daftar UFO
ArrayList<Particle> particles = new ArrayList<Particle>(); // Partikel ledakan
ArrayList<PVector> stars = new ArrayList<PVector>(); // Posisi bintang statis


// =======================================================
// === C. CLASSES (STRUKTUR OBJEK GAME) ==================
// =======================================================

// --- C.1: CLASS OBSTACLE (UFO) ---
class Obstacle {
  PVector pos; PVector size; PVector velocity; 

  Obstacle(float x, float y, float w, float h, float vx, float vy) {
    pos = new PVector(x, y); size = new PVector(w, h); velocity = new PVector(vx, vy);
  }
  
  void update() {
    pos.add(velocity); 
    // Logika pantulan di dinding
    if (pos.x < 0 || pos.x + size.x > width) {
      velocity.x *= -1; pos.x = constrain(pos.x, 0, width - size.x); 
    }
    if (pos.y < 0 || pos.y + size.y > height - 50) {
      velocity.y *= -1; pos.y = constrain(pos.y, 0, height - 50 - size.y);
    }
    // CATATAN: Logika suara mesin roket dipindahkan ke drawShip()
  }
  
  void display() {
    if (ufoImage != null) {
      imageMode(CENTER);
      image(ufoImage, pos.x + size.x/2, pos.y + size.y/2, size.x, size.y);
      imageMode(CORNER);
    } else { // Fallback jika gambar UFO tidak ada
      fill(255, 0, 0, 150); stroke(200, 0, 0);
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
    return distanceSquared < (SHIP_COLLISION_R * SHIP_COLLISION_R);
  }
}

// --- C.2: CLASS PARTICLE (LEDALKAN) ---
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


// =======================================================
// === D. FUNGSI UTAMA (SETUP & DRAW) ====================
// =======================================================

// --- D.1: SETUP ---
void setup(){
    size(800, 600); 
    moon = new int[width/10+1];
   
    // Inisialisasi Bintang Statis
    for (int i = 0; i < STAR_COUNT; i++) {
        // Bintang hanya di atas area bulan (height - 100)
        stars.add(new PVector(random(width), random(height - 100)));
    }
    
    // Muat Aset
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
    
    reset(); // Inisialisasi awal game
}

// --- D.2: DRAW LOOP ---
void draw(){
  background(0); // Latar belakang hitam
  
  drawStarfield(); // Gambar bintang statis
  
  drawMoon();        
  drawLandingZone(); 
  
  // Gambar UFO & Roket
  for (Obstacle obs : obstacles) obs.display();
  drawShip(); 
  
  // Kontrol Alur Game (State Machine)
  if ( state == WAITING ) drawWaiting();
  else if ( state == RUNNING ) update();      
  else if ( state == FINISHED ) drawFinished();
  else if ( state == CRASHED ) drawCrashed();
  
  runExplosion(); // Gambar partikel (jika ada)
}

// =======================================================
// === E. FUNGSI INIILISASI & LOGIKA GAME ================
// =======================================================

// --- E.1: FUNGSI RESET GAME ---
void reset() {
   // Regenerasi kontur bulan & posisi landing
   for ( int i=0; i < moon.length; i++) moon[i] = int(random(10));
   landingX = int( random(3, moon.length-4))*10;
  
   // Reset posisi, kecepatan, dan rotasi roket
   pos = new PVector( 150, 20 );
   a = 0;    acc = 0;    
   speed = new PVector(0, 0); 
   crashMessage = ""; 
   
   // Regenerasi UFO
   obstacles = new ArrayList<Obstacle>();
   for (int i = 0; i < TOTAL_UFO; i++) {
     float x = random(100, width - 150);
     float y = random(80, height - 150);
     float vx = random(UFO_MIN_SPEED, UFO_MAX_SPEED) * (random(1) > 0.5 ? 1 : -1);
     float vy = random(UFO_MIN_SPEED, UFO_MAX_SPEED) * (random(1) > 0.5 ? 1 : -1);
     obstacles.add(new Obstacle(x, y, UFO_W, UFO_H, vx, vy));
   }
}

// --- E.2: LOGIC UPDATE (Berjalan di State RUNNING) ---
void update(){
  // Perhitungan Gaya Dorong (Thrust Force)
  PVector f = new PVector( cos( a+PI/2 ) * -acc, sin( a+PI/2 ) * -acc );
  
  // Mengurangi akselerasi (gesekan udara/mesin mati)
  if ( acc > 0 ) {
    acc *= AIR_FRICTION;
    if(acc < 0.001) acc = 0;
  }
  
  // Hitung Kecepatan & Posisi Baru
  speed.add( g ); // Tambah Gravitasi
  speed.add( f ); // Tambah Dorongan
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
  // Pemeriksaan dilakukan ketika roket mendekati tanah (height - 50)
  if (pos.y > height - 50 - SHIP_H/2) {
      // SUKSES: Mendarat di Landing Pad
      if ( pos.x > landingX - LANDING_PAD_W/2 && pos.x < landingX + LANDING_PAD_W/2 ) { 
         pos.y = height - 50 - SHIP_H/2; 
         speed = new PVector(0, 0); 
         state = FINISHED;
         if (soundThrust != null) soundThrust.stop();
         if (soundWin != null) soundWin.play(); 
         acc = 0;
      } 
      // GAGAL: Tabrak Permukaan Lain / Miss Platform
      else if (pos.y > height - 20 - SHIP_H/2 ) {
         pos.y = height - 20 - SHIP_H/2;
         speed = new PVector(0, 0); 
         state = CRASHED; 
         crashMessage = "Menabrak Permukaan Bulan!"; 
         triggerCrashEffect();
         acc = 0;
      }
  }
  
  // 3. Batasan Layar (Screen Boundary Constraint)
  float halfW = SHIP_W / 2;
  float halfH = SHIP_H / 2;

  // Cek Batas Kiri
  //if (pos.x < halfW) {
  //  pos.x = halfW;
  //  speed.x = 0; // Hentikan pergerakan horizontal
  //}
  // Cek Batas Kanan
  //if (pos.x > width - halfW) {
  //  pos.x = width - halfW;
  //  speed.x = 0; // Hentikan pergerakan horizontal
  //}
  // Cek Batas Atas (Jika roket menyentuh batas atas, anggap crash ringan)
  //if (pos.y < halfH) {
  //  pos.y = halfH;
  //  speed.y = 0; // Hentikan pergerakan vertikal
  //}
  // Catatan: Batas bawah sudah dicakup oleh Cek Pendaratan
}

// --- E.3: FUNGSI EFEK CRASH ---
void triggerCrashEffect() {
   if (soundThrust != null) soundThrust.stop();
   if (soundCrash != null) soundCrash.play();  
   createExplosion(pos.x, pos.y); 
   speed = new PVector(0, 0); 
   acc = 0;
}

// --- E.4: PARTIKEL LEDAKAN (Kontrol) ---
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

// =======================================================
// === F. INPUT HANDLING =================================
// =======================================================

// --- F.1: MOUSE INPUT ---
void mousePressed() {
  if ( state == WAITING ) state = RUNNING;
  else if ( state == FINISHED || state == CRASHED ) {
    reset(); state = RUNNING;
  }
}

// --- F.2: KEYBOARD INPUT ---
void keyPressed() {
 if ( keyCode == LEFT ) a -= ROTATION_SPEED;
 if ( keyCode == RIGHT ) a += ROTATION_SPEED;
 if ( keyCode == UP ) {
   acc += THRUST_POWER;
   acc = min( acc, 1.0); 
 }
 if (keyCode == ' '){ // Spasi untuk memulai/restart
     if ( state == WAITING ) state = RUNNING;
     else if ( state == FINISHED || state == CRASHED ) {
       reset(); state = RUNNING;
   }
 }
}

// =======================================================
// === G. FUNGSI VISUAL / RENDERING ======================
// =======================================================

// --- G.0: FUNGSI STARFIELD (Statik) ---
void drawStarfield() {
  stroke(255); // Warna putih
  for (PVector star : stars) {
    point(star.x, star.y);
  }
}


// --- G.1: ROCKET / SHIP RENDERING ---
void drawShip() {
 pushMatrix(); translate(pos.x, pos.y); rotate(a); noFill();
 
 // Logika Suara Mesin Roket (Dipindahkan ke sini agar terpisah dari UFO)
  if ( acc > 0 ) {
    if (!soundThrust.isPlaying()) soundThrust.loop();
  } else {
    if (soundThrust.isPlaying()) soundThrust.stop();
  }
 
 // Efek Api/Thrust
 for ( int i=4; i >= 0; i--) {
   stroke(255, i*50, 0); fill(255, i*50, 20);
   // Posisi api di bawah roket (+SHIP_H/2)
   ellipse( 0, SHIP_H/2 + 25, min(1, acc*10) * i*4, min(1, acc*10) * i*10);
 }
 
 if (ship != null) {
   // Gambar roket (centered: -SHIP_W/2, -SHIP_H/2)
   image( ship, -SHIP_W/2, -SHIP_H/2, SHIP_W, SHIP_H );
 }
 popMatrix(); 
}

// --- G.2: MOON & LANDING ZONE RENDERING ---
void drawMoon() {
   // Warna bulan abu-abu agar kontras dengan latar hitam
   stroke(150); fill(150, 150, 150, 200); 
   beginShape(); vertex(0, height);
   // Gambar kontur bulan
   for ( int i=0; i < moon.length; i++) vertex( i * 10, height - 20 - moon[i] );
   vertex(width, height); endShape(CLOSE);
}

void drawLandingZone() {
   // Warna Landasan (misal: Hijau/Kuning neon)
   fill(150, 200, 0);
   rect( landingX - LANDING_PAD_W/2, height - 50, LANDING_PAD_W, 10); 
   
   // Warna penanda
   stroke(150, 200, 0);
   line( landingX - 30, height - 20 - moon[landingX/10-3], landingX - 20, height - 40 );
   line( landingX + 30, height - 20 - moon[landingX/10 +3], landingX + 20, height - 40 );
}

// --- G.3: UI TEKS (WAITED, FINISHED, CRASHED) ---
void drawWaiting() {
 textAlign( CENTER ); fill(255); // Warna teks putih agar terlihat di BG hitam
 textSize(20); text( "Click mouse or press SPACE to start", width/2, height/2);
 textSize(16); text( "Hindari " + TOTAL_UFO + " UFO dan mendaratlah!", width/2, height/2 + 30);
}

void drawFinished() {
 textAlign( CENTER ); textSize(20);
 if ( pos.x > landingX - LANDING_PAD_W/2 && pos.x < landingX + LANDING_PAD_W/2 ) {
   fill(0, 255, 0); text( "YOU LANDED THE SHIP!", width/2, height/2);
   fill(255); text( "SUCCESS!", width/2, height/2 - 30);
 } else {
   fill(255, 100, 0); text( "YOU MISSED THE PLATFORM!", width/2, height/2);
 }
 fill(255); text( "click or press SPACE to restart", width/2, height/2 + 30);
}

void drawCrashed() {
 textAlign( CENTER );
 fill(255, 0, 0); textSize(30);
 text( "CRASHED!", width/2, height/2 - 30);
 fill(255); textSize(20);
 text(crashMessage, width/2, height/2 + 10);
 text( "click or press SPACE to restart", width/2, height/2 + 50);
}
