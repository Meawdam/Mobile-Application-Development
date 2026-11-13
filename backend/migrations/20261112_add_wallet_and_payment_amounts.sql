-- Wallet balance for users + payment amount snapshot on borrow records.
ALTER TABLE `users`
  ADD COLUMN `wallet_balance` int(11) NOT NULL DEFAULT 0 AFTER `role`;

ALTER TABLE `borrow`
  ADD COLUMN `rental_amount` int(11) NOT NULL DEFAULT 0 AFTER `rental_days`,
  ADD COLUMN `deposit_amount` int(11) NOT NULL DEFAULT 0 AFTER `rental_amount`,
  ADD COLUMN `total_amount` int(11) NOT NULL DEFAULT 0 AFTER `deposit_amount`;
