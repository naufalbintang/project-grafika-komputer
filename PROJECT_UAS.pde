import processing.sound.*; // import library sound untuk menangani audio

// --- bagian 1: variabel global ---
// variabel untuk file suara
SoundFile soundThrust;
SoundFile soundCrash;
SoundFile soundWin;

// array untuk menyimpan bentuk permukaan bulan (terrain)
int[] moon;
// posisi x target pendaratan (landing pad)
int landingX = 0;

PImage ship; // variabel untuk gambar roket

// vektor posisi (pos) dan kecepatan (speed) roket
PVector pos = new PVector( 150, 20 );
PVector speed = new PVector( 0, 0 );

// variabel fisika roket
// g = gravitasi (menarik roket ke bawah)
PVector g = new PVector( 0, 0.04 ); 
// a = sudut rotasi roket (angle)
float a = 0; 
// acc = akselerasi (tenaga dorong roket saat spasi ditekan)
float acc = 0; 

// --- bagian 2: status game (game state) ---
// menggunakan angka untuk menandai status game saat ini
int WAITING = 1;   // menunggu mulai
int RUNNING = 2;   // sedang main
int FINISHED = 3;  // menang (mendarat)
int CRASHED = 4;   // kalah (tabrakan)
int state = WAITING; // status awal adalah waiting

// --- bagian 3: variabel obstacle & partikel ---
ArrayList<Obstacle> obstacles; // list untuk menyimpan banyak ufo
PImage ufoImage; // gambar ufo
ArrayList<Particle> particles = new ArrayList<Particle>(); // list untuk efek ledakan

// --- bagian 4: class obstacle (ufo) ---
class Obstacle {
  PVector pos;      // posisi ufo
  PVector size;     // ukuran ufo (lebar, tinggi)
  PVector velocity; // kecepatan gerak ufo

  // constructor: fungsi untuk membuat ufo baru
  Obstacle(float x, float y, float w, float h, float vx, float vy) {
    pos = new PVector(x, y);
    size = new PVector(w, h);
    velocity = new PVector(vx, vy);
  }
  
  // fungsi update: menggerakkan ufo
  void update() {
    pos.add(velocity); // ubah posisi berdasarkan kecepatan

    // logika mantul (bounce):
    // jika nabrak tembok kiri/kanan, balik arah x
    if (pos.x < 0 || pos.x + size.x > width) {
      velocity.x *= -1;
      pos.x = constrain(pos.x, 0, width - size.x); // jaga agar tidak tembus
    }
    // jika nabrak atap/bawah, balik arah y
    if (pos.y < 0 || pos.y + size.y > height - 50) {
      velocity.y *= -1;
      pos.y = constrain(pos.y, 0, height - 50 - size.y);
    }
    
    // logika suara thrust (mesin)
    // dipasang di sini agar dicek terus menerus setiap frame
    if ( acc > 0 ) {
      // jika gas ditekan & suara belum bunyi, mainkan (looping)
      if (!soundThrust.isPlaying()) {
        soundThrust.loop();
      }
    } else {
      // jika tidak digas, matikan suara
      if (soundThrust.isPlaying()) {
        soundThrust.stop();
      }
    }
  }
  
  // fungsi display: menggambar ufo ke layar
  void display() {
    if (ufoImage != null) {
      imageMode(CENTER);
      // gambar file ufo.png
      image(ufoImage, pos.x + size.x/2, pos.y + size.y/2, size.x, size.y);
      imageMode(CORNER);
    } else {
      // fallback: jika gambar tidak ada, gambar lingkaran merah (untuk debug)
      fill(255, 0, 0, 150);
      stroke(200, 0, 0);
      strokeWeight(2);
      ellipse(pos.x + size.x/2, pos.y + size.y/2, size.x, size.y);
      
      // hiasan teks "ufo"
      fill(255, 255, 0);
      ellipse(pos.x + size.x/2, pos.y + size.y/2 - 10, size.x * 0.6, size.y * 0.4);
      fill(0);
      textAlign(CENTER);
      textSize(16);
      text("UFO", pos.x + size.x/2, pos.y + size.y/2 + 5);
      strokeWeight(1);
    }
  }
  
  // fungsi cek tabrakan (collision detection)
  boolean checkCollision(PVector shipPos) {
    float shipRadius = 30; // anggap roket berbentuk lingkaran radius 30
    
    // cari titik terdekat pada kotak ufo terhadap pusat roket
    float closestX = constrain(shipPos.x, pos.x, pos.x + size.x);
    float closestY = constrain(shipPos.y, pos.y, pos.y + size.y);
    
    // hitung jarak
    float distanceX = shipPos.x - closestX;
    float distanceY = shipPos.y - closestY;
    float distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);
    
    // jika jarak lebih kecil dari radius roket, berarti nabrak!
    return distanceSquared < (shipRadius * shipRadius);
  }
}

// --- bagian 5: setup (dijalankan sekali di awal) ---
void setup(){
    size(800, 800); // ukuran layar
    
    // generate permukaan bulan secara acak
    moon = new int[width/10+1];
    for(int i = 0; i < moon.length; i++){
        moon[i] = int(random(10)); // ketinggian acak
    }
    
    // tentukan lokasi landing pad secara acak
    landingX = int( random(3, moon.length-4))*10;
    
    // load aset gambar
    ship = loadImage( "ROKET.png" );
    ufoImage = loadImage( "ufo.png" );
    
    // panggil fungsi reset untuk memulai variabel game
    reset();
    
    // load file suara
    soundThrust = new SoundFile(this, "thrust.wav");
    soundCrash = new SoundFile(this, "crash.mp3");
    soundWin = new SoundFile(this, "win.mp3");
    
    soundThrust.amp(0.5); // atur volume suara mesin (50%)
}

// --- bagian 6: fungsi reset (mengulang game) ---
void reset() {
   // acak ulang permukaan bulan
   moon = new int[width/10+1];
   for ( int i=0; i < moon.length; i++) {
       moon[i] = int(random(10));
   }
   landingX = int( random(3, moon.length-4))*10;
  
   // reset posisi roket ke atas
   pos = new PVector( 150, 20 );
   a = 0;      // reset sudut
   acc = 0;    // reset gas
   speed = new PVector(0, 0); // reset kecepatan
   
   // reset dan buat obstacles (ufo) baru
   obstacles = new ArrayList<Obstacle>();
   int numObstacles = int(random(3, 6)); // jumlah ufo acak 3-6 biji
   
   for (int i = 0; i < numObstacles; i++) {
     // posisi acak ufo
     float x = random(100, width - 150);
     float y = random(80, height - 150);
     float w = 75; // lebar ufo
     float h = 60; // tinggi ufo
     // kecepatan acak ufo
     float vx = random(-1, 1);
     float vy = random(-1, 1);
     
     obstacles.add(new Obstacle(x, y, w, h, vx, vy));
   }
}

// --- bagian 7: sistem partikel (ledakan) ---
// fungsi untuk memicu ledakan di koordinat (x, y)
void createExplosion(float x, float y) {
  // buat 50 partikel sekaligus
  for (int i = 0; i < 50; i++) {
    particles.add(new Particle(x, y));
  }
}

// fungsi untuk menjalankan animasi ledakan setiap frame
void runExplosion() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    // jika partikel sudah mati (transparan), hapus dari memori
    if (p.isDead()) {
      particles.remove(i);
    }
  }
}

// class particle (satu butir api ledakan)
class Particle {
  PVector position;
  PVector velocity;
  float lifespan; // umur partikel (untuk transparansi)

  Particle(float x, float y) {
    position = new PVector(x, y);
    velocity = PVector.random2D(); // arah acak
    velocity.mult(random(2, 5));   // kecepatan sebar
    lifespan = 255.0; // mulai dari solid (tidak transparan)
  }
  
  void update() {
    position.add(velocity);
    lifespan -= 5.0; // kurangi umur perlahan (fading out)
  }
  
  void display() {
    noStroke();
    fill(255, 100, 0, lifespan); // warna oranye api dengan alpha (transparansi)
    ellipse(position.x, position.y, 8, 8);
  }
  
  boolean isDead() {
    return (lifespan < 0); // mati jika lifespan habis
  }
}

// --- bagian 8: draw (looping utama) ---
void draw(){
  background(255); // hapus layar jadi putih
  
  // gambar grid (garis bantu latar belakang)
  stroke(200, 200, 255);
  for(int i = 0; i<height/10; i++){
    line( 0, i*10, width, i*10);
  }
  for ( int i=0; i<width/10; i++) {
   line( i*10, 0, i*10, height );
  }
  
  drawMoon();        // gambar tanah
  drawLandingZone(); // gambar tempat mendarat
  
  // gambar semua obstacles (ufo)
  for (Obstacle obs : obstacles) {
    obs.display();
  }
  
  drawShip(); // gambar roket
  
  // cek status game untuk menentukan apa yang dilakukan
  if ( state == WAITING ) {
     drawWaiting(); // tampilkan layar tunggu
  }
  else if ( state == RUNNING ) {
     update();      // jalankan fisika game
  }
  else if ( state == FINISHED ) {
     drawFinished(); // tampilkan layar menang
  }
  else if ( state == CRASHED ) {
     drawCrashed();  // tampilkan layar kalah
  }
  
  // jalankan animasi ledakan (tetap jalan meski game over)
  runExplosion();
}

// --- bagian 9: input mouse ---
void mousePressed() {
 if ( state == WAITING ) {
   state = RUNNING; // klik untuk mulai
 } else if ( state == FINISHED || state == CRASHED ) {
   reset();         // klik untuk restart jika sudah selesai
   state = RUNNING;
 }
}

// --- bagian 10: fungsi gambar ui (teks) ---
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
 // cek apakah mendarat tepat di landing zone?
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

// --- bagian 11: update (logika utama game) ---
void update(){
  // hitung vektor gaya dorong (f) berdasarkan sudut (a) dan gas (acc)
  // -acc karena y ke atas di processing itu negatif
  PVector f = new PVector( cos( a+PI/2 ) * -acc, sin( a+PI/2 ) * -acc );
  
  // kurangi gas perlahan (friksi udara imajiner)
  if ( acc > 0 ) {
    acc *= 0.5;
    if(acc < 0.001){
      acc = 0;
    }
  }
  
  speed.add( g ); // tambah gravitasi
  speed.add( f ); // tambah dorongan mesin
  pos.add( speed ); // pindahkan posisi roket
  
  // cek tabrakan dengan ufo
  for (Obstacle obs : obstacles) {
    obs.update(); // gerakkan ufo sekalian
    
    if (obs.checkCollision(pos)) {
      state = CRASHED;
      
      soundThrust.stop(); // matikan suara mesin
      soundCrash.play();  // mainkan suara ledakan
      createExplosion(pos.x, pos.y); // visual ledakan
        
      speed = new PVector(0, 0); // hentikan roket
      acc = 0;
      return; // langsung keluar dari fungsi update
    }
  }
  
  // cek pendaratan (landing)
  // syarat: posisi x pas di zona landing dan posisi y menyentuh tanah
  if ( pos.x > landingX - 40 && pos.x < landingX + 40 && pos.y > height - 50 - 75 ) { 
     pos.y = height - 50 - 75; // "snap" posisi ke tanah agar tidak tembus
     speed = new PVector(0, 0); 
     state = FINISHED;
     
     soundThrust.stop();
     soundWin.play(); // suara menang
     acc = 0;
  } 
  // jika menyentuh tanah tapi bukan di zona landing (crash di bulan)
  else if (pos.y > height - 20 - 75 ) {
     pos.y = height - 20 - 75;
     speed = new PVector(0, 0); 
     state = CRASHED; 
     
     soundThrust.stop();
     soundCrash.play(); 
     acc = 0;
  } 
}

// --- bagian 12: menggambar elemen visual ---
void drawMoon() {
   stroke(0);
   fill(255, 200, 0, 60); // warna kuning transparan
   beginShape();
   vertex(0, height);
   // gambar vertex (titik) sesuai array moon
   for ( int i=0; i < moon.length; i++) {
       vertex( i * 10, height - 20 - moon[i] );
   }
   vertex(width, height);
   endShape(CLOSE);
}

void drawLandingZone() {
   fill(128, 200);
   rect( landingX - 30, height - 50, 60, 10); // gambar kotak landing pad
   // kaki-kaki landing pad
   line( landingX - 30, height - 20 - moon[landingX/10-3], landingX - 20, height - 40 );
   line( landingX + 30, height - 20 - moon[landingX/10 +3], landingX + 20, height - 40 );
}

void drawShip() {
 pushMatrix(); // simpan koordinat asal
 translate(pos.x, pos.y); // pindahkan titik nol ke posisi roket
 rotate(a); // putar sesuai sudut roket
 noFill();
 
 // animasi api roket (hanya digambar jika ada akselerasi)
 for ( int i=4; i >= 0; i--) {
   stroke(255, i*50, 0);
   fill(255, i*50, 20);
   // ukuran api tergantung besarnya 'acc'
   ellipse( 0, 75, min(1, acc*10) * i*4, min(1, acc*10) * i*10);
 }
 
 image( ship, -50, -50, 100, 100 ); // gambar roket di tengah (0,0 relatif)
 popMatrix(); // kembalikan koordinat normal
}

// --- bagian 13: input keyboard ---
void keyPressed() {
 if ( keyCode == LEFT ) {
   a -= 0.1; // putar kiri
 }
 if ( keyCode == RIGHT ) {
   a += 0.1; // putar kanan
 }
 if ( keyCode == UP ) {
   acc += 0.15; // tambah gas
   acc = min( acc, 1.0); // batasi gas maksimal 1.0
 }
 
 // tombol spasi untuk mulai/restart
 if (keyCode == ' '){
     if ( state == WAITING ) {
       state = RUNNING;
     } else if ( state == FINISHED || state == CRASHED ) {
       reset();
       state = RUNNING;
   }
 }
}
