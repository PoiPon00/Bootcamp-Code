-- ZAD 1------------------------------------------------
create table klient (
id int not null primary key, 
imie text not null,
nazwisko text not null,
data_urodzenia date not null,
ocena_zadowolenia numeric);

-- ZAD 2----------------------------------------------
create table umowy (
id int not null primary key,
nr_umowy varchar(255) not null,
rodzaj_produktu int not null);

-- ZAD 3----------------------------------------------
insert into umowy (id, nr_umowy, rodzaj_produktu) 
values (1, 'XXX12343', 1),
		(2, 'XXX43243', 1,
		(3, 'YYY54354', 2),
		(4, 'ZZZ98321', 3);
	
-------------------------------------------------
		
insert into umowy values (1, 'XXX12343', 1);
insert into umowy values (2, 'XXX43243', 1);
insert into umowy values (3, 'YYY54354', 2);
insert into umowy values (4, 'ZZZ98321', 3);

--drop table klient;
--drop table umowy;

--ZAD 4--------------------------------------------------------------
select * into customers_new from customers;
create view customers_view as select * from customers_new;
delete from customers_new;
--drop view customers_view;
--drop table customers_new;

--ZAD 5-----------------------------------------------------------------
select first_name, last_name from employees where city = 'London' ;
select * from employees where city = 'Seattle' and title_of_courtesy = 'Ms.';
select address from customers where region = 'SP' or city = 'London';
select address from employees where first_name like 'K%';
select * from orders where freight > 100;
select * from orders where freight between 100 and 500;

--ZAD 6-----------------------------------------------------------------
select count(*) from orders;
select count(*) from orders where ship_country = 'Germany';

select left(ship_country, 3) as country_prefix, 
shipped_date - order_date + 1 as days 
from orders where ship_country = 'Germany';

select round(avg(shipped_date - order_date + 1)) as mean from orders;

---------------------------------------------------
select ship_country, round(avg(dispatch_time))
from (
select *,
	shipped_date - order_date as dispatch_time,
	left(ship_country, 3) as prefix
from orders) tmp1 --tmp1 to alias tabeli, wymagany do porawnego wykonania query przy zagniezdzonych 
group by ship_country order by 2 desc;
	

--ZAD 7-------------------------------------------------
select *, coalesce(reports_to, 2) from employees;

select round(cast(discount as numeric), 2) as round
from order_details;
---------------------------------------------------------------
select *,
	nullif (coalesce (reports_to, 2), 5) as reports_to_fixed
	from employees;

select *,
	round(discount::numeric, 2) as rounded_discount1,
	round(cast(discount as numeric), 2) as rounded_discount2
from order_details;

--ZAD 8-----------------------------------------------------------
select *, left(category_name, 3) as category_pref from categories;

select *, upper(concat(address, ' ', city, ' ', postal_code)) as full_adress
from customers where company_name like 'Fr%';

select *, coalesce(region, 'brak danych') as DANE from customers;


