--- I Baza Danych: Northwind ---

--a. Ile zamówień złożono w 1997 roku? (2p.)

select count(*) as orders_1997 from orders o
where extract(year from order_date)::text = '1997';

--b. Jakie są unikatowe nazwy kategorii produktów (CategoryProduct)? (3p.)

select distinct category_name from categories c;

--c. Czy ID zamówień (OrderId) jest unikalne? (3p.)

select 
	count(order_id) as all_orders, 
	count(distinct order_id) as distinct_orders 
from orders o;

--d. Ilu klientów złożyło więcej niż 5 zamówień? (3p.)

select count(*) as customer_over_5
from (select customer_id, count(customer_id) as num_of_orders from orders o
		group by customer_id
		having count(*) > 5) foo;

--e. Ile zamówień (OrderId) zawiera produkty (ProductName) o nazwie "Chai". (3p.)

select count(o.order_id) as num_orders_chai from orders o
left join order_details od 
	on o.order_id = od.order_id 
left join products p 
	on od.product_id = p.product_id 
where p.product_name = 'Chai';

--f. Jaki kraj (Country) ma najmniejszą średnią wartość
-- zamówienia (Quantity x UnitPrice), a jaki największą? (3p.)

select * from 
	(select 
		o.ship_country, 
		avg(od.quantity*od.unit_price) as avg_order_price, 
		'lowest average' as addnote 
	from orders o 
	left join order_details od 
		on o.order_id = od.order_id
	group by o.ship_country 
	order by 2 asc limit 1) mini
union all
select * from 
	(select 
		o.ship_country, 
		avg(od.quantity*od.unit_price) as avg_order_price, 
		'higest average' as addnote 
	from orders o 
	left join order_details od 
		on o.order_id = od.order_id
	group by o.ship_country 
	order by 2 desc limit 1) maxi;

--g. Jakie produkty należą do kategorii „Napoje” 
--(Beverages) i kosztują (UnitPrice) więcej niż 10$? (3p.)

select * from products p 
where unit_price > 10 and 
		category_id in (select category_id from categories c where category_name = 'Beverages')

--h. Jakie są miasta, w których mieszka więcej niż 3 pracowników? (3p.)

select city, count(*) as num_of_employees from employees e
group by city
having count(*) > 3;

--i. Jakie produkty (Products) zostały zamówione mniej niż 10 razy? (3p.)

select p.product_name, count(od.product_id) as num_orders from products p 
left join order_details od 
	on od.product_id = p.product_id 
left join orders o
	on o.order_id = od.order_id 
group by p.product_name
having count(od.product_id) < 10;

--j. Zakładając, że produkty, które kosztują (UnitPrice) 
--mniej niż 10$ możemy uznać za tanie, te między 10$ a 50$ za średnie,
-- a te powyżej 50$ za drogie, ile produktów należy do poszczególnych przedziałów? (4p.)

select 
	count(case when unit_price < 10 then 1 end)::text as cheap_products,
	count(case when unit_price >= 10 and unit_price <= 50 then 1 end)::text as medium_products,
	count(case when unit_price > 50 then 1 end)::text as expensive_products
from products p; 

--k. Czy najdroższy produkt z kategorii z 
--największą średnią ceną to najdroższy produkt ogólnie? (4p.)

select * from (
	select product_name, 
		max(unit_price), 
		'most expensive in category' as addnote 
	from products
	where category_id in (
		select category_id 
		from(select c.category_id,
					avg(p.unit_price) as avg_category_price
			from categories c 
			left join products p 
				on p.category_id  = c.category_id 
			group by c.category_id
			order by 2 desc limit 1) foo)
	group by product_name
	order by 2 desc limit 1) max_category
union all
select * from (
	select p.product_name, 
		max(p.unit_price), 
		'most expensive overall' as addnote 
	from products p
	group by p.product_name 
	order by 2 desc limit 1) max_overall

--l. Ile kosztuje najtańszy, najdroższy i ile średnio kosztuje produkt
-- od każdego z dostawców? UWAGA – te dane powinny być przedstawione z nazwami dostawców, nie ich identyfikatorami (4p.)

select 
	s.company_name, 
	max(p.unit_price) as most_expensive, 
	min(p.unit_price) as cheapest, 
	avg(p.unit_price) as avg_price
from suppliers s
left join products p 
	on p.supplier_id = s.supplier_id 
group by s.company_name 
order by 1 asc;

--m. Jak się nazywają i jakie mają numery kontaktowe wszyscy dostawcy i klienci (ContactName) z Londynu? 
--Jeśli nie ma numeru telefonu, wyświetl faks. (4p.)

select contact_name, coalesce(phone, fax) phone_or_fax, city, 'supplier' as addnote from suppliers s 
where city = 'London'
union all
select contact_name, coalesce(phone, fax) phone_or_fax, city, 'customer' as addnote from customers c  
where city = 'London';

--n. Jakie produkty były na najdroższym zamówieniu (OrderID)? Uwzględnij zniżki (Discount) (4p.)

select p.product_name, od2.order_id from products p 
left join order_details od2 
	on od2.product_id = p.product_id 
where od2.order_id = 
	(select order_id from (
		select 
			o.order_id, 
			sum(od.unit_price*(1-od.discount)*od.quantity) as order_sum
		from orders o
		left join order_details od
			on o.order_id = od.order_id
		group by o.order_id
		order by 2 desc limit 1) foo);

--o. które miejsce cenowo (od najtańszego) zajmują w swojej kategorii (CategoryID) wszystkie produkty? (4p.)
	
select 
	product_name,
	rank()over(partition by category_id order by unit_price) as rank_in_category_by_price
from products p;

--- II Baza Danych: Summary of Weather, Weather Station Location ---

--a. Dla jakiej stacji pogodowej średnia roczna temperatura była mniejsza niż 0? (4p.)

select 
	sow.sta as station, 
	avg(sow.meantemp) as year_avg, 
	1900 + sow.yr as year_, 
	wsl."NAME" 
from summary_of_weather sow  
inner join weather_station_locations wsl 
	on sow.sta = wsl.wban
group by sta, yr, "NAME"
having avg(meantemp) < 0;

--b. Jaka była i w jakim kraju miała miejsce najwyższa dzienna amplituda temperatury? (5p.)

select 
	sow.sta, 
	abs(max(sow.maxtemp - sow.mintemp)) as amplitude, 
	wsl."STATE/COUNTRY ID" as country
from summary_of_weather sow 
left join weather_station_locations wsl 
	on sow.sta = wsl.wban
group by sta, country
order by 2 desc limit 1;

--c. Które stacje pogodowe zarejestrowały największą liczbę dni z opadami śniegu w danym roku? (5p.)

select * from (
	select 
		sta as station, 
		count(snowfall) as num_of_snow_days, 
		1900 + yr as year_,
		rank()over(partition by yr order by count(snowfall) desc) as ranking
	from summary_of_weather sow 
	group by sta, yr
	order by 3, 2 desc ) foo
where ranking = 1;

--d. Ile stacji pogodowych znajduje się na półkuli północnej, a ile na południowej? (6p.)

select 'Northern' as hemisphere, count(*) as num_of_station from weather_station_locations wsl 
where lat like '%N%'
union all 
select 'Southern' as hemisphere, count(*) as num_of_station from weather_station_locations wsl 
where lat like '%S%';
---alternatywna wersja-------
select 
	count(case when latitude < 0 then 1 end) as southern_hemi,
	count(case when latitude > 0 then 1 end) as northen_hemi
from weather_station_locations wsl ;

--e. Na której stacji opady atmosferyczne były najwyższe, 
--przy czym nie uwzględniaj dni, w których wystąpiły opady śniegu. 
--Wyświetl wynik wraz z nazwą stacji i datą. (6p.)

select sow.sta, max(sow.precip) as max_precip, sow."Date", wsl."NAME" from summary_of_weather sow 
left join weather_station_locations wsl 
	on sow.sta = wsl.wban
where snowfall = 0 and precip != 'T'
group by sta, "Date" , "NAME" 
order by 2 desc limit 1;

--f. Z czym silniej skorelowana jest średnia dzienna temperatura 
--dla stacji – szerokością (latitude) czy długością (longitude) geograficzną? (6p.)

select 
	corr(sow.meantemp, wsl.latitude) as corr_lat,
	corr(sow.meantemp, wsl.longitude) as corr_long
from summary_of_weather sow 
left join weather_station_locations wsl 
	on sow.sta = wsl.wban
--Jest bardziej skorelowana z szerokością, ale negatywnie

--g. Pokaż obserwacje, w których suma opadów atmosferycznych (precipitation) 
--przekroczyła sumę opadów z ostatnich 5 obserwacji na danej stacji. (6p.)

select sta, sum(precip_numeric::numeric) as sum_sta_5 from (
	select *,
		rank()over(partition by sta order by "Date" desc) as rn,
		case when precip = 'T' then '0' else precip end as precip_numeric
	from summary_of_weather sow ) foo
where rn < 6 
group by sta

--h. Znajdź wszystkie stacje pogodowe, które zarejestrowały opady w dniach,
-- gdy temperatura była wyższa niż 30 stopni Celsjusza używając do tego operacji EXIST. (6p.)

select "NAME" from weather_station_locations wsl 
where exists
(select precip != '0' from summary_of_weather sow
	where wsl.wban = sow.sta and maxtemp > 30)
order by 1 asc;

--i. Uszereguj stany/państwa według od najniższej temperatury zanotowanej tam w okresie obserwacji używając do tego funkcji okna. (6p.)

select
	distinct wsl."STATE/COUNTRY ID" as country_id,
	min(sow.mintemp)over(partition by wsl."STATE/COUNTRY ID") as min_temp
from summary_of_weather sow 
left join weather_station_locations wsl 
	on sow.sta = wsl.wban
order by 2;

--j. Jakie są średnie temperatury dla każdego miesiąca w UK? (BONUS)

select distinct mth, round(avg_temp_mth::numeric, 2) as avg_temp_mth 
from (
	select 
		sow.meantemp, 
		sow.mo as mth,  
		avg(sow.meantemp)over(partition by sow.mo) as avg_temp_mth,
		wsl."STATE/COUNTRY ID" 
	from summary_of_weather sow 
	left join weather_station_locations wsl 
		on sow.sta = wsl.wban
	group by sow.meantemp, sow.mo, wsl."STATE/COUNTRY ID"
	having wsl."STATE/COUNTRY ID" = 'UK') foo



