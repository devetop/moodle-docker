<?php
// Health check endpoint sederhana

// 1. Ambil kredensial dari environment variables
// Gunakan fungsi getenv() untuk membaca variabel lingkungan.
// Berikan nilai default (null) jika variabel tidak ditemukan, agar pengecekan lebih mudah.
 $host = getenv('DB_HOST') ?: 'db'; // 'db' adalah nama default service di docker-compose
 $user = getenv('DB_USER');
 $pass = getenv('DB_PASSWORD');
 $db   = getenv('DB_NAME');

// 2. Validasi bahwa semua kredensial yang diperlukan telah di-set
if (empty($host) || empty($user) || empty($pass) || empty($db)) {
    // Jika ada yang kosong, artinya konfigurasi tidak lengkap.
    // Kembalikan error 500 (Internal Server Error) karena ini adalah kesalahan konfigurasi server.
    http_response_code(500);
    echo "Configuration error: Database credentials are not set in the environment.";
    exit();
}

// 3. Cek koneksi ke database menggunakan kredensial dari environment
try {
    // Buat DSN (Data Source Name) untuk koneksi PDO
    $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
    
    $conn = new PDO($dsn, $user, $pass);
    
    // Set mode error PDO ke Exception untuk penanganan error yang lebih baik
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // (Opsional) Jalankan query sederhana untuk memastikan koneksi benar-benar hidup
    $stmt = $conn->query("SELECT 1");
    $stmt->fetch(); // Eksekusi query

} catch(PDOException $e) {
    // Jika gagal koneksi ke DB, kirim status 503 Service Unavailable
    // Dalam production, sebaiknya log error $e->getMessage() ke file log, bukan tampilkan ke user.
    // error_log($e->getMessage());
    
    http_response_code(503);
    echo "Database connection failed.";
    exit();
}

// Jika semua tes berhasil, kirim status 200 OK
http_response_code(200);
echo "OK";
?>
