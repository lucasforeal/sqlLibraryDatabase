connect to project; 

create variable today date;
create variable fine_daily_rate_in_cents integer default 5;

create table Category(
	category_name char(10) not null,
	checkout_period integer not null,
	max_books_out integer not null,
	primary key (category_name),
	constraint CHK_checkout_period check (checkout_period >= 0),
	constraint CHK_max_books_out check (max_books_out >= 0) 
);

create table Borrower(
	borrower_id char(10) not null,
	last_name char(20) not null,
	first_name char(20) not null,
	category_name char(10) not null,
	primary key (borrower_id),
	constraint FK_category_name foreign key (category_name) references Category(category_name)
);

create table Borrower_phone(
    borrower_id char(10) not null,
    phone char(20) not null,
	primary key (borrower_id, phone),
	foreign key (borrower_id) references Borrower(borrower_id) on delete cascade
);

create table Book_info(
	call_number char(20) not null,
	title char(50) not null,
	format char(2) not null,
	primary key (call_number),
	constraint CHK_format check (format in ('HC', 'SC', 'CD', 'MF', 'PE'))
);

-- The code supplied below for bar_code will cause it to be generated
-- automatically when a new Book is added to the database

create table Book(
	call_number char(20) references Book_info(call_number)
	  on delete cascade not null,
	copy_number smallint not null,
	bar_code integer unique
		generated always as identity (start with 1) not null,
	primary key (call_number, copy_number)
);

create table Book_author(
	call_number char(20) not null,
	author_name char(20) not null,
	primary key (call_number, author_name),
	foreign key (call_number) references Book_info(call_number) on delete cascade
);

create table Book_keyword(
    call_number char(20) not null,
    keyword varchar(20) not null,
	primary key (call_number, keyword),
	foreign key (call_number) references Book_info(call_number) on delete cascade,
	constraint CHK_keyword check (keyword not like '% %')
);

create table Checked_out(
	call_number char(20) not null,
	copy_number smallint not null,
	borrower_id char(10) not null,
	date_due date not null,
	primary key (call_number, copy_number),
	foreign key (call_number, copy_number) references Book(call_number, copy_number) on delete cascade,
	foreign key (borrower_id) references Borrower(borrower_id)
);

create table Fine(
	borrower_id char(10) not null,
	title char(50) not null,
	date_due date not null,
	date_returned date not null,
	amount numeric(10,2) not null,
	primary key (borrower_id, title, date_due),
	foreign key (borrower_id) references Borrower(borrower_id) on delete cascade
);

-- This trigger will delete all other information on book if last copy is deleted

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

-- This trigger will assess a fine for an overdue book

create trigger assess_fine_trigger
	after delete on Checked_out
	referencing old as o
	for each row
	when (o.date_due < today)
		insert into Fine
		values(o.borrower_id,
			(select title
				from Book_info
				where call_number = o.call_number),
			o.date_due,
			today,
			((days(today) - days(o.date_due)) * fine_daily_rate_in_cents) / 100.0);

-- This trigger will prevent an attempt to checkout books exceeding the required limit

create trigger checkout_limit_trigger  
	before insert on Checked_out
		referencing new as n
		for each row
		when ((select count(*)
				from Checked_out
				where borrower_id = n.borrower_id)
			= (select max_books_out
				from Borrower
				join Category
				on Borrower.category_name = Category.category_name
				where borrower_id = n.borrower_id))
			signal sqlstate '70001'
			set message_text = 'TOO_MANY_BOOKS_OF_THAT_CATEGORY';

-- This trigger will prevent an attempt to delete a borrower who has books checked out

create trigger cant_delete_borrower_trigger
	before delete on Borrower
	referencing old as o
	for each row
	when ((select count(*)
			from Checked_out
			where borrower_id = o.borrower_id)
		> 0)
		signal sqlstate '70002'
		set message_text = 'CANT_DELETE_BORROWER_WITH_BOOK_CHECKED_OUT';