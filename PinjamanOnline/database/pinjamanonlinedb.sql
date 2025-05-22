-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 21 Bulan Mei 2025 pada 07.32
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pinjamanonlinedb`
--

DELIMITER $$
--
-- Prosedur
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CountTransaksi` (OUT `p_jumlah_transaksi` INT)   BEGIN
    -- Menghitung jumlah entri di tabel angsuran
    SELECT COUNT(*) INTO p_jumlah_transaksi 
    FROM angsuran;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteEntriesByIDMaster` (IN `p_id` INT)   BEGIN
    -- Hapus entri dari tabel produk_pinjaman berdasarkan ID
    DELETE FROM produk_pinjaman 
    WHERE id_produk = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditPengguna` (IN `p_id_pengguna` INT, IN `p_nama_lengkap` VARCHAR(100), IN `p_email` VARCHAR(100))   BEGIN
    -- Cek apakah pengguna memiliki pinjaman
    IF NOT EXISTS (SELECT 1 FROM pinjaman WHERE id_pengguna = p_id_pengguna) THEN
        UPDATE pengguna
        SET nama_lengkap = p_nama_lengkap,
            email = p_email
        WHERE id_pengguna = p_id_pengguna;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetDataMasterByID` (IN `p_id` INT, OUT `p_nama_produk` VARCHAR(50), OUT `p_jumlah_maksimal` DECIMAL(10,2), OUT `p_bunga` DECIMAL(5,2), OUT `p_tenor_bulan` INT)   BEGIN
    -- Mengambil data dari tabel produk_pinjaman berdasarkan ID
    SELECT nama_produk, jumlah_maksimal, bunga, tenor_bulan
    INTO p_nama_produk, p_jumlah_maksimal, p_bunga, p_tenor_bulan
    FROM produk_pinjaman 
    WHERE id_produk = p_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `HapusPinjamanLama` ()   BEGIN
    DELETE FROM pinjaman
    WHERE dibuat_pada < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 YEAR)
    AND STATUS = 'lunas';
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `TampilkanPinjamanSatuBulan` ()   BEGIN
    SELECT 
        p.id_pinjaman,
        u.nama_lengkap,
        p.jumlah_pinjaman,
        p.STATUS,
        p.dibuat_pada
    FROM pinjaman p
    JOIN pengguna u ON p.id_pengguna = u.id_pengguna
    WHERE p.dibuat_pada >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 MONTH)
    ORDER BY p.dibuat_pada DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `TampilkanTransaksiBerhasil` ()   BEGIN
    DECLARE v_id_pinjaman INT;
    DECLARE v_status ENUM('menunggu', 'disetujui', 'ditolak', 'dicairkan', 'lunas');
    DECLARE v_count INT DEFAULT 0;
    
    -- Cursor untuk mengambil pinjaman dalam 1 bulan terakhir
    DECLARE cur CURSOR FOR
        SELECT id_pinjaman, STATUS
        FROM pinjaman
        WHERE dibuat_pada >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 MONTH);
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET @done = 1;
    
    SET @done = 0;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_id_pinjaman, v_status;
        IF @done THEN
            LEAVE read_loop;
        END IF;
        IF v_status = 'lunas' THEN
            SET v_count = v_count + 1;
        END IF;
    END LOOP;
    CLOSE cur;
    
    SELECT v_count AS jumlah_transaksi_berhasil;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `TransaksiBerhasil` ()   BEGIN
	DECLARE v_index INT DEFAULT 0;
	DECLARE v_total INT;
	DECLARE v_jumlah INT DEFAULT 0;
-- Ambil jumlah total baris pinjaman dalam 1 bulan terakhir
SELECT COUNT(*) INTO v_total
FROM pinjaman
WHERE dibuat_pada >= DATE_SUB(NOW(), INTERVAL 1 MONTH);

-- Loop dengan indeks
WHILE v_index < v_total DO
    IF (
        SELECT STATUS FROM pinjaman
        WHERE dibuat_pada >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
        LIMIT v_index,1
    ) = 'lunas' THEN
        SET v_jumlah = v_jumlah + 1;
    END IF;

    SET v_index = v_index + 1;
END WHILE;

-- Output jumlah transaksi berhasil
SELECT v_jumlah AS jumlah_transaksi_berhasil;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UbahStatusPinjaman` ()   BEGIN
    UPDATE pinjaman
    SET STATUS = 'disetujui'
    WHERE STATUS = 'menunggu'
    LIMIT 7;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateDataMaster` (IN `p_id` INT, IN `p_nilai_baru` VARCHAR(50), OUT `p_status` VARCHAR(50))   BEGIN
    DECLARE v_count INT;
    
    -- Cek apakah ID produk ada di tabel produk_pinjaman
    SELECT COUNT(*) INTO v_count 
    FROM produk_pinjaman 
    WHERE id_produk = p_id;
    
    IF v_count > 0 THEN
        -- Update nama_produk berdasarkan ID
        UPDATE produk_pinjaman 
        SET nama_produk = p_nilai_baru 
        WHERE id_produk = p_id;
        SET p_status = 'Update berhasil';
    ELSE
        SET p_status = 'ID tidak ditemukan';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateFieldTransaksi` (IN `in_id` INT, INOUT `in_field1` DECIMAL(10,2), INOUT `in_field2` DECIMAL(10,2))   BEGIN
    DECLARE existing_field1 DECIMAL(10,2);
    DECLARE existing_field2 DECIMAL(10,2);

    -- Ambil nilai saat ini dari database
    SELECT jumlah_pinjaman, jumlah_bunga
    INTO existing_field1, existing_field2
    FROM pinjaman
    WHERE id_pinjaman = in_id;

    -- Jika nilai input kosong (NULL), gunakan nilai yang sudah ada
    SET in_field1 = IFNULL(in_field1, existing_field1);
    SET in_field2 = IFNULL(in_field2, existing_field2);

    -- Lakukan update
    UPDATE pinjaman
    SET jumlah_pinjaman = in_field1,
        jumlah_bunga = in_field2
    WHERE id_pinjaman = in_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateStatusPinjamanBulanTerakhir` ()   BEGIN
    DECLARE v_min_id INT;
    DECLARE v_max_id INT;
    DECLARE v_mid_id INT;
    
    -- Ambil id_pinjaman dari 1 bulan terakhir
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count 
    FROM pinjaman 
    WHERE dibuat_pada >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 MONTH);
    
    IF v_count >= 3 THEN
        -- Ambil id_pinjaman dengan jumlah_pinjaman terkecil
        SELECT id_pinjaman INTO v_min_id
        FROM pinjaman
        WHERE dibuat_pada >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 MONTH)
        ORDER BY jumlah_pinjaman ASC
        LIMIT 1;
        
        -- Ambil id_pinjaman dengan jumlah_pinjaman terbesar
        SELECT id_pinjaman INTO v_max_id
        FROM pinjaman
        WHERE dibuat_pada >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 MONTH)
        ORDER BY jumlah_pinjaman DESC
        LIMIT 1;
        
        -- Ambil id_pinjaman dengan jumlah_pinjaman sedang (bukan min/max)
        SELECT id_pinjaman INTO v_mid_id
        FROM pinjaman
        WHERE dibuat_pada >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 MONTH)
        AND id_pinjaman NOT IN (v_min_id, v_max_id)
        LIMIT 1;
        
        -- Update status
        UPDATE pinjaman SET STATUS = 'ditolak' WHERE id_pinjaman = v_min_id;
        UPDATE pinjaman SET STATUS = 'menunggu' WHERE id_pinjaman = v_mid_id;
        UPDATE pinjaman SET STATUS = 'disetujui' WHERE id_pinjaman = v_max_id;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `angsuran`
--

CREATE TABLE `angsuran` (
  `id_angsuran` int(11) NOT NULL,
  `id_pinjaman` int(11) DEFAULT NULL,
  `jumlah_bayar` decimal(10,2) NOT NULL,
  `tanggal_bayar` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `angsuran`
--

INSERT INTO `angsuran` (`id_angsuran`, `id_pinjaman`, `jumlah_bayar`, `tanggal_bayar`) VALUES
(1, 1, 512500.00, '2025-03-01 03:00:00'),
(2, 1, 512500.00, '2025-04-01 03:00:00'),
(3, 2, 678667.00, '2025-03-15 08:30:00'),
(4, 2, 678667.00, '2025-04-15 08:30:00');

-- --------------------------------------------------------

--
-- Struktur dari tabel `pengguna`
--

CREATE TABLE `pengguna` (
  `id_pengguna` int(11) NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `no_ktp` varchar(16) NOT NULL,
  `no_hp` varchar(15) NOT NULL,
  `alamat` text DEFAULT NULL,
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pengguna`
--

INSERT INTO `pengguna` (`id_pengguna`, `nama_lengkap`, `email`, `no_ktp`, `no_hp`, `alamat`, `dibuat_pada`) VALUES
(1, 'Ole Romeny', 'ole@email.com', '12345678', '0812345678', 'Jl. Merdeka No. 10, Jakarta', '2025-04-17 10:05:40'),
(2, 'Jay Idzes', 'jay@email.com', '231381831', '081266666', 'Jl. Sudirman No. 25, Bandung', '2025-04-17 10:05:40'),
(3, 'Justin Hubner', 'justin@email.com', '2147483647', '0812343434', 'Jl. Diponegoro No. 15, Surabaya', '2025-04-17 10:05:40'),
(4, 'Mees Hilgers', 'mees@email.com', '378950382', '087851442422', 'Jl. Ngaglik No. 5, Surabaya', '2025-05-20 00:38:28'),
(5, 'Kevin Diks', 'kevin@email.com', '69878762', '08128899976', 'Jl. Pogot No. 60, Medan', '2025-05-20 00:39:25');

--
-- Trigger `pengguna`
--
DELIMITER $$
CREATE TRIGGER `before_delete_pengguna` BEFORE DELETE ON `pengguna` FOR EACH ROW BEGIN
    IF EXISTS (SELECT 1 FROM pinjaman WHERE id_pengguna = OLD.id_pengguna AND STATUS != 'lunas') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Pengguna masih memiliki pinjaman aktif.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_insert_pengguna` BEFORE INSERT ON `pengguna` FOR EACH ROW BEGIN
    IF NEW.email NOT LIKE '%@%.%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Format email tidak valid.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `pinjaman`
--

CREATE TABLE `pinjaman` (
  `id_pinjaman` int(11) NOT NULL,
  `id_pengguna` int(11) DEFAULT NULL,
  `id_produk` int(11) DEFAULT NULL,
  `jumlah_pinjaman` decimal(10,2) NOT NULL,
  `jumlah_bunga` decimal(10,2) NOT NULL,
  `total_tagihan` decimal(10,2) NOT NULL,
  `tenor_bulan` int(11) NOT NULL,
  `STATUS` enum('menunggu','disetujui','ditolak','dicairkan','lunas') DEFAULT 'menunggu',
  `keterangan` text DEFAULT NULL,
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pinjaman`
--

INSERT INTO `pinjaman` (`id_pinjaman`, `id_pengguna`, `id_produk`, `jumlah_pinjaman`, `jumlah_bunga`, `total_tagihan`, `tenor_bulan`, `STATUS`, `keterangan`, `dibuat_pada`) VALUES
(1, 1, 1, 3000000.00, 90000.00, 3075000.00, 6, 'disetujui', NULL, '2025-04-17 10:06:01'),
(2, 2, 2, 8000000.00, 144000.00, 8144000.00, 12, 'dicairkan', NULL, '2025-04-17 10:06:01');

--
-- Trigger `pinjaman`
--
DELIMITER $$
CREATE TRIGGER `after_delete_pinjaman` AFTER DELETE ON `pinjaman` FOR EACH ROW BEGIN
INSERT INTO riwayat_status_pinjaman (id_pinjaman, STATUS, diperbarui_pada)
VALUES (OLD.id_pinjaman, 'dihapus', NOW());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_insert_pinjaman` AFTER INSERT ON `pinjaman` FOR EACH ROW BEGIN
    INSERT INTO riwayat_status_pinjaman (id_pinjaman, STATUS)
    VALUES (NEW.id_pinjaman, NEW.STATUS);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_update_pinjaman_status` AFTER UPDATE ON `pinjaman` FOR EACH ROW BEGIN
    IF NEW.STATUS != OLD.STATUS THEN
        INSERT INTO riwayat_status_pinjaman (id_pinjaman, STATUS)
        VALUES (NEW.id_pinjaman, NEW.STATUS);
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_update_pinjaman` BEFORE UPDATE ON `pinjaman` FOR EACH ROW BEGIN
    DECLARE max_jumlah DECIMAL(10,2);
    SELECT jumlah_maksimal INTO max_jumlah FROM produk_pinjaman WHERE id_produk = NEW.id_produk;

    IF NEW.jumlah_pinjaman > max_jumlah THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Jumlah pinjaman melebihi batas maksimal produk.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `produk_pinjaman`
--

CREATE TABLE `produk_pinjaman` (
  `id_produk` int(11) NOT NULL,
  `nama_produk` varchar(50) NOT NULL,
  `jumlah_maksimal` decimal(10,2) NOT NULL,
  `bunga` decimal(5,2) NOT NULL,
  `tenor_bulan` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `produk_pinjaman`
--

INSERT INTO `produk_pinjaman` (`id_produk`, `nama_produk`, `jumlah_maksimal`, `bunga`, `tenor_bulan`) VALUES
(1, 'Pinjaman Usaha Kecil', 5000000.00, 2.50, 6),
(2, 'Pinjaman Mikro', 10000000.00, 1.80, 12);

-- --------------------------------------------------------

--
-- Struktur dari tabel `riwayat_status_pinjaman`
--

CREATE TABLE `riwayat_status_pinjaman` (
  `id_riwayat` int(11) NOT NULL,
  `id_pinjaman` int(11) DEFAULT NULL,
  `STATUS` enum('menunggu','disetujui','ditolak','dicairkan','lunas','dihapus') DEFAULT NULL,
  `diperbarui_pada` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `riwayat_status_pinjaman`
--

INSERT INTO `riwayat_status_pinjaman` (`id_riwayat`, `id_pinjaman`, `STATUS`, `diperbarui_pada`) VALUES
(1, 1, 'menunggu', '2025-02-25 01:00:00'),
(2, 1, 'disetujui', '2025-02-26 05:00:00'),
(3, 1, 'dicairkan', '2025-02-27 07:00:00'),
(4, 2, 'menunggu', '2025-02-20 02:00:00'),
(5, 2, 'disetujui', '2025-02-21 06:00:00'),
(6, 2, 'dicairkan', '2025-02-22 09:00:00');

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `view_analisis_pinjaman`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `view_analisis_pinjaman` (
`nama_lengkap` varchar(100)
,`nama_produk` varchar(50)
,`id_pinjaman` int(11)
,`jumlah_pinjaman` decimal(10,2)
,`total_tagihan` decimal(10,2)
,`status` enum('menunggu','disetujui','ditolak','dicairkan','lunas')
,`jumlah_angsuran` bigint(21)
,`total_dibayar` decimal(32,2)
,`sisa_tagihan` decimal(33,2)
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `view_detail_pinjaman`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `view_detail_pinjaman` (
`nama_lengkap` varchar(100)
,`email` varchar(100)
,`nama_produk` varchar(50)
,`id_pinjaman` int(11)
,`jumlah_pinjaman` decimal(10,2)
,`total_tagihan` decimal(10,2)
,`status` enum('menunggu','disetujui','ditolak','dicairkan','lunas')
,`dibuat_pada` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `view_pengguna_pinjaman`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `view_pengguna_pinjaman` (
`id_pengguna` int(11)
,`nama_lengkap` varchar(100)
,`email` varchar(100)
,`id_pinjaman` int(11)
,`jumlah_pinjaman` decimal(10,2)
,`status` enum('menunggu','disetujui','ditolak','dicairkan','lunas')
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `view_pinjaman_aktif`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `view_pinjaman_aktif` (
`nama_lengkap` varchar(100)
,`no_ktp` varchar(16)
,`id_pinjaman` int(11)
,`jumlah_pinjaman` decimal(10,2)
,`total_tagihan` decimal(10,2)
,`status` enum('menunggu','disetujui','ditolak','dicairkan','lunas')
);

-- --------------------------------------------------------

--
-- Stand-in struktur untuk tampilan `view_statistik_pinjaman`
-- (Lihat di bawah untuk tampilan aktual)
--
CREATE TABLE `view_statistik_pinjaman` (
`id_pengguna` int(11)
,`nama_lengkap` varchar(100)
,`total_pinjaman` bigint(21)
,`total_jumlah_pinjaman` decimal(32,2)
,`rata_rata_pinjaman` decimal(14,6)
);

-- --------------------------------------------------------

--
-- Struktur untuk view `view_analisis_pinjaman`
--
DROP TABLE IF EXISTS `view_analisis_pinjaman`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_analisis_pinjaman`  AS SELECT `p`.`nama_lengkap` AS `nama_lengkap`, `pp`.`nama_produk` AS `nama_produk`, `pin`.`id_pinjaman` AS `id_pinjaman`, `pin`.`jumlah_pinjaman` AS `jumlah_pinjaman`, `pin`.`total_tagihan` AS `total_tagihan`, `pin`.`STATUS` AS `status`, count(`a`.`id_angsuran`) AS `jumlah_angsuran`, sum(`a`.`jumlah_bayar`) AS `total_dibayar`, `pin`.`total_tagihan`- coalesce(sum(`a`.`jumlah_bayar`),0) AS `sisa_tagihan` FROM (((`pengguna` `p` join `pinjaman` `pin` on(`p`.`id_pengguna` = `pin`.`id_pengguna`)) join `produk_pinjaman` `pp` on(`pin`.`id_produk` = `pp`.`id_produk`)) left join `angsuran` `a` on(`pin`.`id_pinjaman` = `a`.`id_pinjaman`)) GROUP BY `pin`.`id_pinjaman`, `p`.`nama_lengkap`, `pp`.`nama_produk`, `pin`.`jumlah_pinjaman`, `pin`.`total_tagihan`, `pin`.`STATUS` ;

-- --------------------------------------------------------

--
-- Struktur untuk view `view_detail_pinjaman`
--
DROP TABLE IF EXISTS `view_detail_pinjaman`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_detail_pinjaman`  AS SELECT `p`.`nama_lengkap` AS `nama_lengkap`, `p`.`email` AS `email`, `pp`.`nama_produk` AS `nama_produk`, `pin`.`id_pinjaman` AS `id_pinjaman`, `pin`.`jumlah_pinjaman` AS `jumlah_pinjaman`, `pin`.`total_tagihan` AS `total_tagihan`, `pin`.`STATUS` AS `status`, `pin`.`dibuat_pada` AS `dibuat_pada` FROM ((`pengguna` `p` join `pinjaman` `pin` on(`p`.`id_pengguna` = `pin`.`id_pengguna`)) join `produk_pinjaman` `pp` on(`pin`.`id_produk` = `pp`.`id_produk`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `view_pengguna_pinjaman`
--
DROP TABLE IF EXISTS `view_pengguna_pinjaman`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_pengguna_pinjaman`  AS SELECT `p`.`id_pengguna` AS `id_pengguna`, `p`.`nama_lengkap` AS `nama_lengkap`, `p`.`email` AS `email`, `pin`.`id_pinjaman` AS `id_pinjaman`, `pin`.`jumlah_pinjaman` AS `jumlah_pinjaman`, `pin`.`STATUS` AS `status` FROM (`pengguna` `p` join `pinjaman` `pin` on(`p`.`id_pengguna` = `pin`.`id_pengguna`)) ;

-- --------------------------------------------------------

--
-- Struktur untuk view `view_pinjaman_aktif`
--
DROP TABLE IF EXISTS `view_pinjaman_aktif`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_pinjaman_aktif`  AS SELECT `p`.`nama_lengkap` AS `nama_lengkap`, `p`.`no_ktp` AS `no_ktp`, `pin`.`id_pinjaman` AS `id_pinjaman`, `pin`.`jumlah_pinjaman` AS `jumlah_pinjaman`, `pin`.`total_tagihan` AS `total_tagihan`, `pin`.`STATUS` AS `status` FROM (`pengguna` `p` join `pinjaman` `pin` on(`p`.`id_pengguna` = `pin`.`id_pengguna`)) WHERE `pin`.`STATUS` in ('disetujui','dicairkan') ;

-- --------------------------------------------------------

--
-- Struktur untuk view `view_statistik_pinjaman`
--
DROP TABLE IF EXISTS `view_statistik_pinjaman`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_statistik_pinjaman`  AS SELECT `p`.`id_pengguna` AS `id_pengguna`, `p`.`nama_lengkap` AS `nama_lengkap`, count(`pin`.`id_pinjaman`) AS `total_pinjaman`, sum(`pin`.`jumlah_pinjaman`) AS `total_jumlah_pinjaman`, avg(`pin`.`jumlah_pinjaman`) AS `rata_rata_pinjaman` FROM (`pengguna` `p` left join `pinjaman` `pin` on(`p`.`id_pengguna` = `pin`.`id_pengguna`)) GROUP BY `p`.`id_pengguna`, `p`.`nama_lengkap` ;

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `angsuran`
--
ALTER TABLE `angsuran`
  ADD PRIMARY KEY (`id_angsuran`),
  ADD KEY `id_pinjaman` (`id_pinjaman`);

--
-- Indeks untuk tabel `pengguna`
--
ALTER TABLE `pengguna`
  ADD PRIMARY KEY (`id_pengguna`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `no_ktp` (`no_ktp`),
  ADD UNIQUE KEY `no_hp` (`no_hp`),
  ADD UNIQUE KEY `no_ktp_2` (`no_ktp`);

--
-- Indeks untuk tabel `pinjaman`
--
ALTER TABLE `pinjaman`
  ADD PRIMARY KEY (`id_pinjaman`),
  ADD KEY `id_pengguna` (`id_pengguna`),
  ADD KEY `id_produk` (`id_produk`);

--
-- Indeks untuk tabel `produk_pinjaman`
--
ALTER TABLE `produk_pinjaman`
  ADD PRIMARY KEY (`id_produk`);

--
-- Indeks untuk tabel `riwayat_status_pinjaman`
--
ALTER TABLE `riwayat_status_pinjaman`
  ADD PRIMARY KEY (`id_riwayat`),
  ADD KEY `id_pinjaman` (`id_pinjaman`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `angsuran`
--
ALTER TABLE `angsuran`
  MODIFY `id_angsuran` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT untuk tabel `pengguna`
--
ALTER TABLE `pengguna`
  MODIFY `id_pengguna` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT untuk tabel `pinjaman`
--
ALTER TABLE `pinjaman`
  MODIFY `id_pinjaman` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT untuk tabel `produk_pinjaman`
--
ALTER TABLE `produk_pinjaman`
  MODIFY `id_produk` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `riwayat_status_pinjaman`
--
ALTER TABLE `riwayat_status_pinjaman`
  MODIFY `id_riwayat` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `angsuran`
--
ALTER TABLE `angsuran`
  ADD CONSTRAINT `angsuran_ibfk_1` FOREIGN KEY (`id_pinjaman`) REFERENCES `pinjaman` (`id_pinjaman`);

--
-- Ketidakleluasaan untuk tabel `pinjaman`
--
ALTER TABLE `pinjaman`
  ADD CONSTRAINT `pinjaman_ibfk_1` FOREIGN KEY (`id_pengguna`) REFERENCES `pengguna` (`id_pengguna`),
  ADD CONSTRAINT `pinjaman_ibfk_2` FOREIGN KEY (`id_produk`) REFERENCES `produk_pinjaman` (`id_produk`);

--
-- Ketidakleluasaan untuk tabel `riwayat_status_pinjaman`
--
ALTER TABLE `riwayat_status_pinjaman`
  ADD CONSTRAINT `riwayat_status_pinjaman_ibfk_1` FOREIGN KEY (`id_pinjaman`) REFERENCES `pinjaman` (`id_pinjaman`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
