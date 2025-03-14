-- 1. Who is the senior most employee based on job title?
select *
from employee
order by levels desc
limit 1;


-- 2. Which countries have the most Invoices?
select count(*), billing_country
from invoice
group by billing_country
order by count(*) desc;


-- 3. What are top 3 values of total invoice?
select total
from invoice
order by total desc
limit 3;


-- 4. Which city has the best customers? We would like to throw a promotional Music
-- Festival in the city we made the most money. Write a query that returns one city that
-- has the highest sum of invoice totals. Return both the city name & sum of all invoice totals
select sum(total) as total, billing_city, customer_id
from invoice
group by billing_city
order by total desc;


-- 5. Who is the best customer? The customer who has spent the most money will be
-- declared the best customer. Write a query that returns the person who has spent the most money
select c.customer_id, c.first_name, c.last_name, sum(i.total) as spend
from customer as c
         inner join invoice as i on c.customer_id = i.customer_id
group by c.customer_id, c.first_name, c.last_name
order by spend desc
limit 1;


-- 6. Write query to return the email, first name, last name, & Genre of all Rock Music
--      listeners. Return your list ordered alphabetically by email starting with A
select distinct email, first_name, last_name
from customer as c
         inner join invoice as i on c.customer_id = i.customer_id
         inner join invoice_line as i_2 on i.invoice_id = i_2.invoice_id
where track_id in
      (select track_id
       from track
                inner join genre on track.genre_id = genre.genre_id
       where genre.name like 'Rock')
order by email;


-- 7. Let's invite the artists who have written the most rock music in our dataset. Write a
--      query that returns the Artist name and total track count of the top 10 rock bands
select at.artist_id, at.name, count(track_id) as total_track
from track as trk
         inner join album as al on trk.album_id = al.album_id
         inner join artist as at on al.artist_id = at.artist_id
         inner join genre as g on trk.genre_id = g.genre_id
where g.name like 'Rock'
group by at.artist_id, at.name
order by total_track desc
limit 10;


-- 8. Return all the track names that have a song length longer than the average song length.
--      Return the Name and Milliseconds for each track. Order by the song length with the
--      longest songs listed first
select name, milliseconds
from track
where milliseconds > (select avg(milliseconds)
                      from track)
order by milliseconds desc;



-- 9. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent
with best_selling_artist as
         (select at.artist_id,
                 at.name,
                 sum(il.unit_price * il.quantity) as total_sales
          from invoice_line as il
                   inner join track as t on il.track_id = t.track_id
                   inner join album as a on t.album_id = a.album_id
                   inner join artist as at on a.artist_id = at.artist_id
          group by at.artist_id, at.name
          order by total_sales desc
          )
select c.customer_id,
       c.first_name,
       c.last_name,
       bsa.name                         as artist_name,
       sum(il.unit_price * il.quantity) as total_spend
from invoice as i
         inner join customer as c on i.customer_id = c.customer_id
         inner join invoice_line as il on i.invoice_id = il.invoice_id
         inner join track as t on il.track_id = t.track_id
         inner join album as a on t.album_id = a.album_id
         inner join best_selling_artist as bsa on a.artist_id = bsa.artist_id
group by c.customer_id, c.first_name, c.last_name, artist_name
order by total_spend desc;

-- in a single query format
select c.customer_id,c.first_name,c.last_name,best_selling_artist.name as artist_name,
       SUM(il.unit_price * il.quantity) AS total_spend
FROM invoice as i
         inner join customer as c on i.customer_id = c.customer_id
         inner join invoice_line as il on i.invoice_id = il.invoice_id
         inner join track as t on il.track_id = t.track_id
         inner join album as a on t.album_id = a.album_id
         inner join (SELECT at.artist_id,
                            at.name,
                            SUM(il.unit_price * il.quantity) as total_sales
                     from invoice_line as il
               inner join track as t on il.track_id = t.track_id
               inner join album as a on t.album_id = a.album_id
               inner join artist as at on a.artist_id = at.artist_id
                     group by at.artist_id, at.name
                     order by total_sales desc
                     ) as best_selling_artist
             ON a.artist_id = best_selling_artist.artist_id
group by c.customer_id, c.first_name, c.last_name, artist_name
order by total_spend desc ;


-- 10. We want to find out the most popular music Genre for each country. We determine the
-- most popular genre as the genre with the highest amount of purchases. Write a query
-- that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres
select country, genre, genre_id, perchases
from (select count(quantity) as perchases,
             c.country,
             g.name as genre,
             g.genre_id,
             row_number() over (partition by c.country order by count(quantity) desc) rw
      from invoice_line as il
               inner join invoice as i on il.invoice_id = i.invoice_id
               inner join customer as c on c.customer_id = i.customer_id
               inner join track as t on il.track_id = t.track_id
               inner join genre as g on t.genre_id = g.genre_id
      group by c.country, g.genre_id, g.name) as t
where rw = 1;


-- 11. Write a query that determines the customer that has spent the most on music for each
-- country. Write a query that returns the country along with the top customer and how
-- much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount
-- with best_selling_artist as
select customer_id, first_name, last_name, billing_country, total_spend
from (select c.customer_id,
             c.first_name,
             c.last_name,
             billing_country,
             sum(total) as total_spend,
             row_number() over (partition by billing_country order by sum(total) desc ) as rw
      from customer as c
               inner join invoice as i on c.customer_id = i.customer_id
      group by c.customer_id, c.first_name, c.last_name, billing_country) as t
where rw = 1
order by billing_country asc