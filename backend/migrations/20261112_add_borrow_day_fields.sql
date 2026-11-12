-- Borrower-selected rental window inside the lender's return_before timeframe.
ALTER TABLE `borrow`
  ADD COLUMN `pickup_date` date DEFAULT NULL AFTER `borrower_id`,
  ADD COLUMN `planned_return_date` date DEFAULT NULL AFTER `pickup_date`,
  ADD COLUMN `rental_days` int(11) NOT NULL DEFAULT 0 AFTER `planned_return_date`;
