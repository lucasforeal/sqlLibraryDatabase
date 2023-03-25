connect to project; 

create variable today date;
create variable fine_daily_rate_in_cents integer default 5;

create table Category(
	category_name char(10),
	checkout_period integer,
	max_books_out integer
);

create table Borrower(
	borrower_id char(10),
	last_name char(20),
	first_name char(20),
	category_name char(10)
);

create table Borrower_phone(
    borrower_id char(10),
    phone char(20)
);

create table Book_info(
	call_number char(20),
	title char(50),
	format char(2)
);

-- The code supplied below for bar_code will cause it to be generated
-- automatically when a new Book is added to the database

create table Book(
	call_number char(20),
	copy_number smallint,
	bar_code integer
		generated always as identity (start with 1)
);

create table Book_author(
	call_number char(20),
	author_name char(20)
);

create table Book_keyword(
    call_number char(20),
    keyword varchar(20)
);

create table Checked_out(
	call_number char(20),
	copy_number smallint,
	borrower_id char(10),
	date_due date
);

create table Fine(
	borrower_id char(10),
	title char(50),
	date_due date,
	date_returned date,
	amount numeric(10,2)
);

-- This trigger will delete all other information on book if last
-- copy is deleted

create trigger last_book_trigger
	after delete on Book
	referencing old as o
	for each row 
	when ((select count(*) 
			from book 
			where call_number = o.call_number) 
		= 0)
		delete from Book_info
			where call_number = o.call_number;
			
-- This trigger will prevent an attempt to renew a book that is overdue

create trigger cant_renew_overdue_trigger
	before update on Checked_out
	referencing old as o
	for each row
	when (o.date_due < today)
		 signal sqlstate '70000'
		 set message_text = 'CANT_RENEW_OVERDUE';

-- Code needed to create other triggers should be added here
