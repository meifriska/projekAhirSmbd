<?php
include 'config/db_connect.php';
include 'includes/header.php';


if ($conn->query("CALL CountTransaksi(@jumlah_transaksi)")) {
    // Ambil hasil dari variabel @jumlah_transaksi
    $result = $conn->query("SELECT @jumlah_transaksi AS total_transaksi");
    if ($result) {
        $row = $result->fetch_assoc();
        $totalTransaksi = $row['total_transaksi'];
        $result->free();
    } else {
        $totalTransaksi = 'Data tidak tersedia';
    }
    $conn->next_result(); // Membersihkan hasil sebelumnya
} else {
    $totalTransaksi = 'Gagal mengeksekusi stored procedure';
}


$conn->query("SET @total_pengguna = 0");

// Panggil stored procedure dengan parameter OUT
$conn->query("CALL JumlahPengguna(@total_pengguna)");

// Ambil nilai dari variabel sesi
$result = $conn->query("SELECT @total_pengguna AS total_pengguna");

if ($result) {
    $row = $result->fetch_assoc();
    $totalPengguna = $row['total_pengguna'];
    $result->free();
} else {
    $totalPengguna = 'Data tidak tersedia';
}

// Bersihkan hasil sebelumnya
$conn->next_result();
?>

?>
?>
<link rel="stylesheet" href="style.css" />
 <nav>
    <ul>
      <li><a href="dashboard.php">Beranda</a></li>
      <li><a href="pengguna.php">Pengguna</a></li>
      <li><a href="pinjaman.php">Pinjaman</a></li>
      <li><a href="analisis_pinjaman.php">Analisis Pinjaman</a></li>
      <li><a href="pinjaman_aktif.php">Pinjaman Aktif</a></li>
      <li><a href="statistik_pinjaman.php">Statistik Pinjaman</a></li>
    </ul>
  </nav>
<main>
    <h2>Dashboard</h2>
    <div class="cards">
        <!-- Contoh data statis; ganti dengan data dinamis dari database -->
        <div class="card">
            <h3>Total Transaksi</h3>
            <p><?= $totalTransaksi ?></p>
        </div>
        <div class="card">
            <h3>Jumlah Pengguna</h3>
            <p><?= $totalPengguna ?></p>
        </div>
        <div class="card">
            <h3>Pinjaman Aktif</h3>
            <p>80</p>
        </div>
        <div class="card">
            <h3>Pinjaman Lunas</h3>
            <p>40</p>
        </div>
    </div>
</main>

<?php include 'includes/footer.php'; ?>
