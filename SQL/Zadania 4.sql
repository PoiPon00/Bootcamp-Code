---PRZYKLAD 1------------------------------
--Dla zapytania tabeli orders dodamy następujące pola:
--● Całkowitą sumę frachtu danego klienta
--● Sumę frachtu w danym miesiącu
--● Narastającą sumę frachtu w danym miesiącu

select * ,
freight, 
sum(freight)over(partition by customer_id ) customer_freight,
sum(freight)over(partition by date_trunc('month',order_date) ) freight_mth,
sum(freight)over(partition by date_trunc('month',order_date) order by order_date, order_id )freight_mth_cum
from orders o 
order by order_date, order_id 

---ZAD 1------------------------------
--(Zadanie 7 z poprzednich zajęć)
--Wykonaj zadanie nie korzystając z podzapytań tylko z funkcji okna.
--Wyświetlimy wszystkie zamównieania. Dla każdego wiersza dodaj kolumny:
--● min_mth_freight - minimalna wielkość frachtu w danym miesiącu
--● max_mth_freight - maksumalna wielkość frachtu w danym miesiącu
--● min_diff - różnica frachtu zamówienia w stosunku do wartości minimalnej w
--danym miesiącu (nieujemna)
--● max_diff - różnica frachtu zamówienia w stosunku do wartości maksymalnej
--w danym miesiącu (niedodatnia)
--Wyniki posortuj według daty zamówienia

select * ,
freight, 
min(freight)over(partition by date_trunc('month',order_date) ) as min_mth_freight,
max(freight)over(partition by date_trunc('month',order_date) ) as max_mth_freight,
freight - min(freight)over(partition by date_trunc('month',order_date) ) as min_diff,
freight - max(freight)over(partition by date_trunc('month',order_date) ) as max_diff
from orders o 
order by order_date, order_id 


---PRZYKLAD 2---------------------------
--Weźmy dane z tabeli orders
--● Wyznaczmy kolejne numery zaówień z danego miesiąca
--● Porównajmy działanie funkcji rank z row_number
--● Wyznaczymy też numerowanie ze względu dzień zamówienia oraz
--wielkość zamówienia malejąco

---- bez numerowania po freight 
select *, 
	order_date,
	freight, 
	rank()over(partition by date_trunc('month',order_date) order by order_date )  mth_order_rank,
	row_number()over(partition by date_trunc('month',order_date) order by order_date )  mth_order_number
from orders; 
---- z numerowanem po freight 
select *, 
	order_date,
	freight, 
	rank()over(partition by date_trunc('month',order_date) order by order_date )  mth_order_rank,
	row_number()over(partition by date_trunc('month',order_date) order by order_date )  mth_order_number,
	row_number()over(partition by date_trunc('month',order_date) order by order_date, freight desc  )  mth_order_number_freight
from orders;

---PRZYKLAD 3----------------------------
--Pozyskanie klienta
--Uznajemy, że pracownik obsługujący pierwsze zamówienie danego klienta
--odpowiada z jego pozyskanie.
--Zrobimy zestawienie pokazujące ile każdy z pracowników pozyskał nowych
--klientów

select 
	employee_id, 
	count(*) new_clients
from 
	(select customer_id, employee_id 
	from 
		(select customer_id,
			employee_id,
			order_date,
			row_number()over(partition by customer_id order by order_date ) rn
			from orders ) c
	where rn = 1 ) e 
group by employee_id
order by new_clients desc;

---ZAD 2----------------------------
select distinct order_id,
		p.product_name,
		v.main_product_value main_product_value,
		v.order_value
from
(	select *, 
		quantity * (1 - discount) * unit_price as main_product_value,
		sum(quantity * (1 - discount) * unit_price)over(partition by order_id) as order_value,
		row_number() over (partition by order_id) as rn
	from order_details od) v
left join products p 
	on p.product_id = v.product_id
where v.rn = 1
order by 1;

---PRZYKLAD 4--------------------------

select 
order_id, 
customer_id, 
order_date,
lag(order_id)over(partition by customer_id order by order_date ) previous_order, 
lag(order_date)over(partition by customer_id order by order_date ) previous_order_date
from orders 
order by order_date  










