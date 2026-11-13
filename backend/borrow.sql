-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 04, 2026 at 02:19 PM
-- Server version: 10.11.16-MariaDB
-- PHP Version: 8.5.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `borrow`
--

-- --------------------------------------------------------

--
-- Table structure for table `asset`
--

CREATE TABLE `asset` (
  `id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `status` enum('ready','pending','borrowed','unavailable') DEFAULT 'ready',
  `approval` enum('pending','approved','not approve') DEFAULT 'pending',
  `approval_message` text DEFAULT NULL,
  `down_payment` decimal(10,2) NOT NULL DEFAULT 0.00,
  `return_before` date NOT NULL,
  `price` int(11) NOT NULL,
  `pickup_point` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `borrow`
--

CREATE TABLE `borrow` (
  `id` int(11) NOT NULL,
  `asset_id` int(11) NOT NULL,
  `borrower_id` int(11) NOT NULL,
  `pickup_date` date DEFAULT NULL,
  `planned_return_date` date DEFAULT NULL,
  `rental_days` int(11) NOT NULL DEFAULT 0,
  `rental_amount` int(11) NOT NULL DEFAULT 0,
  `deposit_amount` int(11) NOT NULL DEFAULT 0,
  `total_amount` int(11) NOT NULL DEFAULT 0,
  `borrow_date` datetime DEFAULT NULL,
  `return_date` datetime DEFAULT NULL,
  `status` enum('requested','approved','borrowed','returned_pending','returned_confirmed','rejected') DEFAULT 'requested',
  `payment_status` enum('unpaid','paid','refunded') DEFAULT 'unpaid',
  `fine_amount` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone_num` varchar(10) NOT NULL,
  `role` enum('admin','user') DEFAULT 'user',
  `wallet_balance` int(11) NOT NULL DEFAULT 0,
  `is_suspended` tinyint(1) NOT NULL DEFAULT 0,
  `suspension_reason` varchar(500) DEFAULT NULL,
  `suspended_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `password`, `phone_num`, `role`, `created_at`) VALUES
(13, 'pm_owner_17936854040104259', 'pm_owner_17936854040104259@example.test', '$argon2id$v=19$m=19456,t=2,p=1$rEhXZH6/C+VM/e+9Qplmgw$jkd90uMtJpsIpwA61qTANYCBYIEA4gRtApUWSVpcZ2w', '3685404011', 'user', '2026-11-03 05:56:44'),
(15, 'pm_owner_17936855937797470', 'pm_owner_17936855937797470@example.test', '$argon2id$v=19$m=19456,t=2,p=1$3GISJZdj4ovzQknOES8Jng$5cX5LP/wE7YBAcqFjmNOOSPb2OeI0b17fomyjMgs1ME', '3685593779', 'user', '2026-11-03 05:59:53'),
(16, 'pm_borrower_17936855937797470', 'pm_borrower_17936855937797470@example.test', '$argon2id$v=19$m=19456,t=2,p=1$/RdquPf1NE4eZh9EerostQ$i2FP9znspho6Jb8xhpI/jaxUAHe5uiC19HpNJajUCmU', '3685593780', 'user', '2026-11-03 05:59:54'),
(17, 'sample_user', 'sample@example.com', '$argon2id$v=19$m=19456,t=2,p=1$bHqBzEwDPw+hD/n1Hkv/Yw$lRxyaKNCz3aDuIHTw5PQlr2zBP6p18i1kGP+Sy8O/Ys', '0812345678', 'user', '2026-11-03 06:09:42');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `asset`
--
ALTER TABLE `asset`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_asset_owner` (`owner_id`);

--
-- Indexes for table `borrow`
--
ALTER TABLE `borrow`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_borrow_asset` (`asset_id`),
  ADD KEY `fk_borrow_borrower` (`borrower_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `asset`
--
ALTER TABLE `asset`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `borrow`
--
ALTER TABLE `borrow`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `asset`
--
ALTER TABLE `asset`
  ADD CONSTRAINT `fk_asset_owner` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `borrow`
--
ALTER TABLE `borrow`
  ADD CONSTRAINT `fk_borrow_asset` FOREIGN KEY (`asset_id`) REFERENCES `asset` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_borrow_borrower` FOREIGN KEY (`borrower_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- --------------------------------------------------------
-- Table structure for table `financial_transactions`
--

CREATE TABLE `financial_transactions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `actor_id` int(11) DEFAULT NULL,
  `borrow_id` int(11) DEFAULT NULL,
  `transaction_type` enum(
    'wallet_top_up',
    'rental_payment',
    'deposit_hold',
    'fine_collected',
    'deposit_refund'
  ) NOT NULL,
  `amount` int(11) NOT NULL,
  `status` enum('pending','completed','released') NOT NULL DEFAULT 'completed',
  `description` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `processed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_financial_borrow_type` (`borrow_id`,`transaction_type`),
  KEY `idx_financial_user_created` (`user_id`,`created_at`),
  KEY `idx_financial_status_type` (`status`,`transaction_type`),
  CONSTRAINT `fk_financial_user` FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_financial_actor` FOREIGN KEY (`actor_id`)
    REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_financial_borrow` FOREIGN KEY (`borrow_id`)
    REFERENCES `borrow` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for table `user_activity_logs`
--

CREATE TABLE `user_activity_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `actor_id` int(11) DEFAULT NULL,
  `category` enum('rental','finance','admin') NOT NULL,
  `action` varchar(80) NOT NULL,
  `entity_type` varchar(40) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `message` varchar(255) NOT NULL,
  `details` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_activity_user_created` (`user_id`,`created_at`),
  KEY `idx_activity_category` (`user_id`,`category`,`created_at`),
  CONSTRAINT `fk_activity_user` FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_activity_actor` FOREIGN KEY (`actor_id`)
    REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Backfill available financial history for existing borrow records.
INSERT INTO `financial_transactions`
  (`user_id`, `actor_id`, `borrow_id`, `transaction_type`, `amount`, `status`,
   `description`, `created_at`, `processed_at`)
SELECT b.borrower_id, b.borrower_id, b.id, 'rental_payment',
  b.rental_amount, 'completed', 'Rental payment (schema import)',
  b.created_at, b.created_at
FROM `borrow` b
WHERE b.payment_status IN ('paid', 'refunded');

INSERT INTO `financial_transactions`
  (`user_id`, `actor_id`, `borrow_id`, `transaction_type`, `amount`, `status`,
   `description`, `created_at`, `processed_at`)
SELECT b.borrower_id, b.borrower_id, b.id, 'deposit_hold',
  b.deposit_amount,
  IF(b.status = 'returned_confirmed' AND b.payment_status = 'refunded',
    'released', 'pending'),
  'Deposit held (schema import)', b.created_at,
  IF(b.status = 'returned_confirmed' AND b.payment_status = 'refunded',
    b.return_date, NULL)
FROM `borrow` b
WHERE b.payment_status IN ('paid', 'refunded');

INSERT INTO `financial_transactions`
  (`user_id`, `borrow_id`, `transaction_type`, `amount`, `status`,
   `description`, `created_at`, `processed_at`)
SELECT b.borrower_id, b.id, 'fine_collected', b.fine_amount, 'completed',
  'Late return fine (schema import)', b.return_date, b.return_date
FROM `borrow` b
WHERE b.payment_status = 'refunded' AND b.fine_amount > 0;

INSERT INTO `financial_transactions`
  (`user_id`, `borrow_id`, `transaction_type`, `amount`, `status`,
   `description`, `created_at`, `processed_at`)
SELECT b.borrower_id, b.id, 'deposit_refund',
  GREATEST(b.deposit_amount - b.fine_amount, 0), 'completed',
  'Deposit refund (schema import)', b.return_date, b.return_date
FROM `borrow` b
WHERE b.status = 'returned_confirmed'
  AND b.payment_status = 'refunded'
  AND b.deposit_amount > b.fine_amount;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
