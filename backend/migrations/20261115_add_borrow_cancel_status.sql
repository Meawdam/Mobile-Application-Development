ALTER TABLE borrow
  MODIFY COLUMN status ENUM(
    'requested',
    'approved',
    'borrowed',
    'returned_pending',
    'returned_confirmed',
    'rejected',
    'cancel'
  ) DEFAULT 'requested';
