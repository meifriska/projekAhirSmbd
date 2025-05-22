<?php
include 'config/db_connect.php'; // Pastikan path sesuai dengan struktur proyek Anda
?>
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Daftar Pengguna - Pencatatan Pinjaman Online</title>
  <link rel="stylesheet" href="style.css" />

</head>
<body>
  <header>
    <h1>Dashboard Admin</h1>
  </header>
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
    <section>
      <h2>Daftar Pengguna</h2>
      <table border="1" cellpadding="10" cellspacing="0">
        <thead>
          <tr>
            <th>ID Pengguna</th>
            <th>Nama</th>
            <th>Email</th>
            <th>ID Peminjam</th>
            <th>Jumlah Pinjaman</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <?php
          $sql = "SELECT * FROM view_pengguna_pinjaman";
          $result = $conn->query($sql);

          if ($result && $result->num_rows > 0) {
              while($row = $result->fetch_assoc()) {
                  echo "<tr>";
                  echo "<td>" . htmlspecialchars($row['id_pengguna']) . "</td>";
                  echo "<td>" . htmlspecialchars($row['nama_lengkap']) . "</td>";
                  echo "<td>" . htmlspecialchars($row['email']) . "</td>";
                  echo "<td>" . htmlspecialchars($row['id_pinjaman']) . "</td>";
                  echo "<td>" . htmlspecialchars($row['jumlah_pinjaman']) . "</td>";
                  echo "<td>" . htmlspecialchars($row['status']) . "</td>";
                  echo "</tr>";
              }
          } else {
              echo "<tr><td colspan='4'>Tidak ada data ditemukan.</td></tr>";
          }
          ?>
        </tbody>
      </table>
    </section>
  </main>
  <footer>
    <p>&copy; 2025 Pencatatan Pinjaman Online. Hak Cipta Dilindungi.</p>
  </footer>
</body>
</html>
