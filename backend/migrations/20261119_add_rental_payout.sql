ALTER TABLE financial_transactions
  MODIFY COLUMN transaction_type ENUM(
    'wallet_top_up',
    'rental_payment',
    'rental_payout',
    'deposit_hold',
    'deposit_forfeiture',
    'deposit_refund',
    'borrow_refund'
  ) NOT NULL;
