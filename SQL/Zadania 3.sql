---PRZYKLAD 1--------
--Wyświetlimy te zamówienia, w których co najmniej jeden z zamawianych
--produktów był w ilości co najmniej 20 sztuk.
select * from orders o 
where order_id in (select order_id from order_details od where quantity >= 20);


---ZAD 1------------------
--Wyznacz wszystkie zamówienia z tabeli Orders, gdzie freight>= 0.7 *
--maksymalna wartość freight w 1998 roku.
select * from orders where freight >= 0.7 *
(
	select max(freight) as max_freight
	from orders
	where extract(year from order_date)::text = '1998'
);

--Wyznacz wszystkie zamówienia do miast, w których mamy więcej niż
--jednego klienta
select * from orders o where ship_city in 
(	select city from customers
	group by city
	having count(*) > 1
);

---PRZYKLAD 2--------------------------------
--Wyświetlimy zamówienia z miesięcy, w których wartość zamówień (Ilość
--(1- rabat) * cena ) przekroczyła 70 tys
select * from orders o 
join 
(	select 
		date_trunc('month', o.order_date) mth,
		sum(d.quantity * (1 - d.discount) * d.unit_price) mth_sum
	from order_details d
	join orders o 
		on o.order_id = d.order_id
	group by date_trunc('month', o.order_date) 
)foo
on foo.mth = date_trunc('month', o.order_date) and mth_sum > 70000;

--Wyświetlimy wszystkie zamówienia, dodamy kolumnę z najwyższą
--wartością Freight w historii
select o.*, foo.max_freight from orders o
join 
(	select 
		max(freight) max_freight 
	from orders
) foo 
	on 1 = 1;

---ZAD 2----------------------------
--Wyświetlmy dane wszystkich zamówień, dla każdego zamówienia dodajmy
--kolumnę, która przedstawia ilość produktów w tym zamówieniu, których cena
--jednostkowa była wyższa niż 30 (a podstawie tabeli order_details)

select o.*, coalesce (foo.product_num, 0) from orders o
left join 
(
	select order_id, count(*) as product_num from order_details
	where unit_price > 30
	group by order_id
) foo
	on o.order_id = foo.order_id;
	
---PRZYKLAD 3-----------------------------
--Wyświetlimy wszystkie zamówienia z roku 1996 z tabeli orders .
--Dodatkowo dla każdej pozycji policzymy jej udział procentowy frachtu z
--tego roku.
select *, 
	freight / 
	(	select sum(freight) from orders 
		where extract(year from order_date)::text = '1996') * 100 as freight_precentage
from orders o 
where extract(year from order_date)::text = '1996';

---ZAD 3----------------------------
--Wypisz wszystkie dane z tabeli orders dla zamówienia o id = 10309, dołącz
--kolumnę z sumą wartości tego zamówienia (Ilość (1- rabat) * cena )
--○ używając podzapytania w select
--○ używając podzapytania w join

select *,
(	select sum(quantity*(1 - discount)*unit_price) as sum 
	from order_details
	where order_id = 10309
)
from orders 
where order_id = 10309;

select o.*, sum(od.quantity*(1 - od.discount)*od.unit_price) from orders o
left join order_details od 
	on o.order_id = od.order_id 
where o.order_id = 10309
group by o.order_id

---PRZYKLAD 4---------------------
--Dla zamówień nr: 10248,10281, 10308 będziemy chcieli zobaczyć cenę
--najdroższych ich produktów. Następnie chcemy wyświetlić te produkty z
--tabeli products, które są droższe od któregokolwiek z nich.

select * from products p 
where unit_price > any 
(	
	select max(unit_price) 
	from order_details od 
	where order_id in (10248, 10281, 10308)
	group by order_id
);

--Chcemy wyświetlić te produkty, które są droższe od każdego z nich.
select * from products p 
where unit_price > all 
(	
	select max(unit_price) 
	from order_details od 
	where order_id in (10248, 10281, 10308)
);

---ZAD 4------------------------------
--Wyświetl wszystkie szczegóły zamówień, których cena jednostkowa była
--większa od przynajmniej jednego z produktów o ProductID = 43,28,16

select * from order_details od 
where unit_price > any 
(
	select unit_price from products p 
	where product_id in (43, 28, 16)
);

--Wyświetl wszystkie szczegóły zamówień, których cena jednostkowa była
--większa od każdego z produktów o ProductID = 43,28,16

select * from order_details od 
where unit_price > all 
(
	select unit_price from products p 
	where product_id in (43, 28, 16)
);

---PRZYKLAD 5------------------------
--Wyświetlimy dane wszystkich pracowników, którzy kiedykolwiek
--obsługiwali zamówienia klienta ‘BERGS’

select e.* from employees e 
where exists 
(	select * from orders o 
	where customer_id = 'BERGS' and  e.employee_id = employee_id );

---ZAD 5-------------------
--Wyświetl dane wszystkich zamówień klientów, którzy swoją siedzibę mają w
--Londynie (na podstawie tabeli customers)
--Napisz zapytania korzystając z:
--○ EXISTS
--○ Podzapytania w WHERE
--○ Podzapytania w JOIN

select o.* from orders o 
where exists 
( select * from customers c
	where city = 'London' and o.customer_id = customer_id );
	
select * from orders o 
where customer_id  in 
(	select customer_id  from customers c
	where city = 'London' );

select o.* from orders o 
inner join customers c 
	on o.customer_id = c.customer_id 
where c.city = 'London';

---ZAD 6-----------------------------
--Będziemy chcieli przeanalizować jak dużo jest zamówień, które mają dostawców
--z USA lub Włoch.
--Zrobimy zestawienie gdzie będzimy mieli zagregowane do miesięcy wielkości:
--orders, orders_usa, orders_it.
--Gdzie ordrs_usa to liczba zmównień z przynajmnej jednym produktem, którego
--dostawca pochodzi z USA (na podstawie tabeli supplier). Analogicznie dla
--orers_it.
--Zestawienie przedstaw od najbardziej aktualnych miesięcy

select date_trunc('month', o.order_date) as mth, 
	count(distinct o.order_id) as orders,
	count(distinct case when s.country = 'USA' then o.order_id end) as orders_us,
	count(distinct case when s.country = 'Italy' then o.order_id end) as orders_it
from orders o 
left join order_details od 
	on o.order_id = od.order_id 
left join products p 
	on od.product_id = p.product_id 
left join suppliers s 
	on p.supplier_id = s.supplier_id 
group by mth
order by 1 desc;

---ZAD 7----------------------
--Wyświetlimy wszystkie zamównieania. Dla każdego wiersza dodaj kolumny:
--● min_mth_freight - minimalna wielkość frachtu w danym miesiącu
--● max_mth_freight - maksumalna wielkość frachtu w danym miesiącu
--● min_diff - różnica frachtu zamówienia w stosunku do wartości minimalnej w
--danym miesiącu (nieujemna)
--● max_diff - różnica frachtu zamówienia w stosunku do wartości maksymalnej
--w danym miesiącu (niedodatnia)
--Wyniki posortuj według daty zamówienia

select *, 
(o.freight - foo.min_mth_freight) as min_diff,
(o.freight - foo.max_mth_freight) as max_diff
from orders o
join 
	(select
	date_trunc('month', o.order_date) as mth,
	min(freight) as min_mth_freight,
	max(freight) as max_mth_freight
	from orders o
	group by mth) foo
on foo.mth = date_trunc('month', o.order_date)
	
---PRZYKLAD 6---------------------------------------
--Zrobimy zestawienie dla najlepszych 5 pracowników pod względem
--Freight do 10 miast, do których wysyłali oni zamówienia.
--Dla każdego z tych miast policzymy ile Freight wysłał każdy z tych
--najlepszych pracowników i ile % wartości to stanowi względem sumy
--wysłanej przez tych pracowników

with 
	top5e as 
	(	select employee_id, 
				sum(freight) freight
		from orders
		group by employee_id
		order by freight desc limit 5),
	top10c as 
	(	select ship_country, 
		sum(o.freight) freight
		from orders o
		join top5e e 
			on e.employee_id = o.employee_id
		group by ship_country
		order by freight desc limit 10)
select 
	o.employee_id, 
	o.ship_country, 
	sum(o.freight) employee_freight, 
	sum(o.freight)/avg(c.freight) percent_top5
from orders o 
join top10c c 
	on c.ship_country = o.ship_country
join top5e e 
	on o.employee_id = e.employee_id
group by o.employee_id, o.ship_country
order by ship_country, percent_top5 desc ;

---ZAD 8----------------------------------
--Chcemy zrobić zestawienie dotyczące ilości zamawianych produktów
--dostarczanych przez poszczególnych spedytorów (tabela shippers) .
--Interesować nas będą tylko często zamawiane produkty - takie, których
--zamówiona ilość historycznie przekroczyła 1000 sztuk.
--Dla każdego spedytora, chcemy zobaczyć ile sztuk poszczególnych
--produktów było za jego pośrednictwem transportowane.
--W zestawieniu ma być nazwa spedytora, nazwa produktu i ilość. Wyniki
--posortuj po nazwie spedytora i ilości malejąco

--Schemat postępowania:
--● utwórz podzapytanie z listą produktów o liczbie (quanitiy) przekraczającej
--1000 sztuk - dołącz tutaj też nazwę produktu
--● utwórz podzapytanie w którym będziemy mieli Id zamówienia oraz nazwę
--spedytora
--● Połącz odpowiednie dwa powyższe podzapytania z tabelą order_details ,
--dokonaj odpowiedniej agregacji oraz sortowania.




---ZAD 9-------------------------------
--Chcemy dowiedzieć w jakich krajach działamy i na jakich zasadach.
--Stwórzmy raport, gdzie dla każdego państwa będziemy mieli
--podsumowanie z liczbą zamówień, liczbą klientów pochodzących z tego
--kraju oraz liczbą dostawców z tego kraju.
--Raport posortujemy alfabetycznie po nazwie kraju.

--Schemat postępowania:
--● utwórz podzapytanie ze słownikiem zawierającym unikatową listę państw
--występujących w tabelach z zamówieniami, klientami i dostawcami
--● Do uzyskanego słownika dołącz poszczególne tabelę i użyj
--odpowiednich funkcji agregujących by uzyskać finalny wynik.

with 
	ct as 
	(select ship_country from orders o
		union 
	select country from customers cu
		union
	select country from suppliers s)
select 
	ct.ship_country, 
	count(distinct o.*) as orders,
	count(distinct c.*) as customers,
	count(distinct s.*) as suppliers
from ct
left join orders o
	on o.ship_country = ct.ship_country
left join customers c 
	on c.country = ct.ship_country
left join suppliers s  
	on s.country = ct.ship_country	
group by ct.ship_country
order by 1;

