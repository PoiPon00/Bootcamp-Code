---ZAD 1------------------------------
--Wyznacz liczb� zam�wie� dla ka�dego klienta (id wystarczy)
--Sprawd�, czy count(1) i count(*) zwraca ten sam wynik?
select customer_id, count(1) from orders
group by customer_id;

--Sprawd�my dzia�anie rollup oraz cube:
--Wyznacz liczb� zam�wie� dla ka�dego klienta w totalu oraz per rok
--Dodaj do tego zestawienie per rok � bez grupowania klient�w
select customer_id, extract(year from order_date)::text as year, count(*) as order_num 
from orders
group by cube(customer_id, extract(year from order_date))
order by year desc;


---ZAD 2---------------------------------
--Zapytanie nr 1
--Zlicz liczb� produkt�w w ka�dej kategorii oraz �redni� cen� produktu w danej kategorii.
--Posortuj wyniki malej�co (po �redniej cenie)
--Zachowaj te kategorie, kt�rych �rednia cena wynosi ponad 20.
select category_id, count(*) as unit_num, round(avg(unit_price)::numeric, 2) as average_price
from products
group by category_id 
having round(avg(unit_price)::numeric, 2) > 20
order by average_price desc;

--Zapytanie nr 2
--Zlicz klient�w w danym mie�cie i kraju, skonstruuj tak�e sum� cz�ciow� dla ca�ego kraju.
--Pozostaw tylko te wiersze, kt�re maj� przynajmniej dw�ch klient�w z tytu�em kontaktowym �Owner�.
select* 
from (
	select country, city, count(*) as customer_num 
	from customers
	where contact_title = 'Owner'
	group by rollup (country, city)
	having count(*) > 1
) foo
where country is not null;

---ZAD 3-----------------
--We�my dane tabeli order_details.
--Dodajmy do wynik�w zmienn� �czy_znizka�, kt�ra przyjmie warto�� �TAK�  w sytuacji, gdy dla produktu by�a zni�ka oraz �NIE� je�eli zni�ka nie  zosta�a przyznana.
--Zmodyfikujmy powy�sze i dodajmy w sytuacji, gdy mamy zni�k� dwie  warto�ci: je�eli zni�ka jest <0.1 to wypiszemy �ma�a zni�ka� je�eli jest>=
--0.1 to wypiszemy �du�a zni�ka�.
--Zliczmy rekordy ze zni�kami i bez zni�ek. Wyznaczmy jaki to procent  ca�o�ci.
select *,
	case
		when discount > 0 and discount < 0.1 then 'mała znizka'
		when discount >= 0.1 then 'duża zniżka'
		else 'Nie'
	end as czy_znizka
from 
	order_details; 

select
	count(case when discount > 0 then 1 end)::text as ze_znizka,
	count(case when discount = 0 then 1 end)::text as bez_znizka,
	count(*) as wszystko,
	concat(round(round(count(case when discount > 0 then 1 end ) / count(*)::numeric, 2) * 100, 0), '%') as udzial_znizek
from
	order_details;

---ZAD 4---------------------------
--Dodaj to tabeli products now� kolumn� product_name_new , kt�ra przyjmuje warto�� �UNKNOWN� dla produkt�w, kt�rych nazwa ma mniej ni� 6 znak�w.
--Zlicz te rekordy.

select *,
	case
		when length(product_name) < 6 then 'UNKNOWN'
		else product_name 
	end as product_name_new
from products p 

select 
	count(case when length(product_name) < 6 then 1 end) as new_name
from products p;
	
---ZAD 5----------------------------------
--W bazie NORTHWIND znajduj� si� tabele z przewo�nikami i dostawcami  (shippers oraz suppliers).
--Wypiszmy wszystkie firmy, z kt�rymi wsp�pracujemy w jednej tabeli  (bez dubli).
--Wypiszmy wszystkie firmy, z kt�rymi wsp�pracujemy w jednej tabeli(z  dublami).
--Wypiszmy cz�� wsp�ln� obu tabel.
--Wypiszmy te przypadki, kt�rych nie ma w tabeli shippers.

select company_name from shippers s 
union
select company_name from suppliers s2
order by 1 asc;

select company_name from shippers s 
union all
select company_name from suppliers s2
order by 1 asc;

select company_name from shippers s 
intersect
select company_name from suppliers s2
order by 1 asc;

select company_name from suppliers s2
except
select company_name from shippers s 
order by 1 asc;

---ZAD 6---------------------------
--W bazie NORTHWIND znajduj� si� tabele z klientami i dostawcami  (customers oraz suppliers).
--Wypiszmy wszystkie firmy, z kt�rymi wsp�pracujemy w jednej tabeli  (bez dubli).
--Wypiszmy wszystkie firmy, z kt�rymi wsp�pracujemy w jednej tabeli(z  dublami).
--Wypiszmy cz�� wsp�ln� obu tabel.
--Wypiszmy te przypadki, kt�rych nie ma w tabeli customers.

select company_name from suppliers s 
union
select company_name from customers
order by 1 asc;

select company_name from suppliers s 
union all
select company_name from customers
order by 1 asc;

select company_name from suppliers s 
intersect
select company_name from suppliers
order by 1 asc;

select company_name from customers
except
select company_name from suppliers s 
order by 1 asc;

---ZAD 7---------------------------
--W tabeli Orders dodaj kolumn� finalnej sprzeda�y:
--UnitPrice*(1-Discount)*Quantity
--Dodaj jedn� kolumn� z  imieniem i nazwiskiem pracownika.
--Policzmy ca�kowit� sprzeda� dla ka�dego pracownika
--Odfiltrujmy wszystkich pracownik�w, dla kt�rych ca�kowita sprzeda� by�a ni�sza od 100 000 i posortujmy wyniki po tej cenie malej�co i zaokr�glijmy t� cen� do liczb ca�kowitych.
--Stw�rzmy kolumn� (salesman_level) z informacj� o wynikach pracownika w zale�no�ci od jego ca�kowitej sprzeda�y:
--�top salesman� � je�eli jego wynik jest powy�ej 200 000
--�aspiring� � je�eli total_sales jest pomi�dzy 150 000 a 200 000
--�still good� dla pozosta�ych

select 
	employee_name,
	round(sum(sales),0) as total_sales,
	case
		when sum(sales) > 200000 then 'top salesman'
		when sum(sales) > 150000 and sum(sales) < 200000 then 'aspiring'
		else 'still good'
	end as salesman_level
from 
(
	select o.*,
		round((od.unit_price*(1-od.discount)*od.quantity)::numeric, 2) as sales,
		concat(e.first_name,' ', e.last_name) as employee_name
	from orders o
	left join order_details od
		on o.order_id = od.order_id
	left join employees e 
		on o.employee_id = e.employee_id 
) foo
group by employee_name
having sum(sales) > 100000
order by 2 desc;

---ZAD 8-------------------------------
--Napisz zapytanie z informacj� o nazwie produktu (tabela products), regionie jego dostawcy i kraju jego dostawcy. 
--Puste warto�ci w kolumnie region zast�p informacj� �N/A� (�Not available�).
--Zlicz nazwy produkt�w dla danego kraju i regionu oraz dla samego kraju (zaawansowane grupowanie), 
--a nast�pnie posortuj po kraju i regionie dla wi�kszej przejrzysto�ci wynik�w.
--Na koniec zast�p wiersze z ca�kowitym wynikiem dla kraju (pusta warto�� kolumny region) sformu�owaniem �_SUMA_�.

select 
	coalesce (supplier_country, 'ALL COUNTIRES'),
	coalesce(supplier_region, '_SUMA_'),
	products_num
from 
(
	select 
		supplier_country, 
		supplier_region, 
		count(*) as products_num
	from
	(
		select 
			p.product_name, 
			coalesce(s.region, 'N/A') as supplier_region, 
			s.country as supplier_country
		from products p
		left join suppliers s 
			on p.supplier_id = s.supplier_id 
	) foo
	group by rollup(supplier_country, supplier_region)
	order by 1, 2
) foo2;

---ZAD 9----------------------------
--Wy�wietl imi� i nazwisko pracownika w jednej kolumnie i nazwij j� employee_name.
--Policz przeci�tny �adunek na pracownika i posortuj po tej kolumnie malej�co, by zobaczy�, kto ma najwi�kszy �redni �adunek zam�wienia.
--Stw�rz kolumn�, kt�ra w przypadku gdy employee_name ma wi�cej ni� 10 znak�w zwraca jedynie pierwsze 10 znak�w,
--w przeciwnym przypadku zwraca po prostu warto�� employee_name � zast�p employee_name now� kolumn�.

select left(employee_name, 10) as employee_name, avg_freight
from 
(
	select 
		concat(e.first_name, ' ', e.last_name) as employee_name,
		round((avg(o.freight))::numeric, 2) as avg_freight
	from orders o
	left join employees e 
		on o.employee_id = e.employee_id 
	group by concat(e.first_name, ' ', e.last_name)
	order by 2 desc
) foo;

---ZAD 10----------------------------------------------
--Połącz poziomo tabelę customers i employees tak, aby finalnie otrzymać cztery kolumny:
--- id
--- adres
--- miasto
--- region
--Stw�rz kolumn�, kt�ra klasyfikuje, czy dany rekord pochodzi z tabeli customers czy employees (zasugeruj si� id).

select 
	id, address, city, region,
	case
		when length(id) > 1 then 'customers'
		else 'employees'
	end as where_from
from
(
	select customer_id as id, address, city, region from customers c 
	union all 
	select employee_id::text as id, address, city, region from employees e
) foo;

