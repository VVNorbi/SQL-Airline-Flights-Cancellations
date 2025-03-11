# SQL-Airline-Flights-Cancellations

```sql
-- 1. Średnia odległość lotu dla każdej linii lotniczej

WITH flight AS (
    SELECT 
        a."AIRLINE", 
        COUNT(*) AS number_of_flights, 
        SUM(f."DISTANCE") AS all_distance
    FROM 
        flights f
    LEFT JOIN 
        airlines a ON f."AIRLINE" = a."IATA_CODE"
    GROUP BY 
        a."AIRLINE"
    ORDER BY 
        number_of_flights DESC
)

SELECT 
    *, 
    ROUND(all_distance/number_of_flights, 2) AS avg_flight_distance
FROM 
    flight
ORDER BY 
    avg_flight_distance DESC;
```

![image](https://github.com/user-attachments/assets/9b59a40a-2ebc-42e8-a224-05ac653eace8)

```sql
-- 2. Procent lotów odwołanych dla każdej linii lotniczej.

WITH number_of_flight AS (
	SELECT 
		a."AIRLINE" as airplane, 
		COUNT(*) AS number_flight_airpline,
		COUNT(CASE WHEN f."CANCELLED" = True THEN 1 END) AS cancelled_flights
	FROM 
		flights f
	LEFT JOIN 
		airlines a ON f."AIRLINE" = a."IATA_CODE"
	GROUP BY 
		airplane
)

SELECT 
	*,
	ROUND((cancelled_flights::NUMERIC/number_flight_airpline)*100,2) AS percentage_of_cancelled_flights_per_airline
FROM 
	number_of_flight
ORDER BY 
	percentage_of_cancelled_flights_per_airline DESC;
```

![image](https://github.com/user-attachments/assets/08b9a9b6-102c-4396-ae17-2d12d74333e6)

```sql
-- 3. Średnie opóźnienie przylotów dla każdej linii lotniczej.

SELECT 
	a."AIRLINE",
	ROUND(AVG(f."ARRIVAL_DELAY"),2) AS delay_minutes
FROM 
	flights f
LEFT JOIN 
	airlines a ON f."AIRLINE" = a."IATA_CODE"
WHERE 
	f."ARRIVAL_DELAY" > 0
GROUP BY 
	a."AIRLINE"
ORDER BY 
	delay_minutes DESC;
````


![image](https://github.com/user-attachments/assets/6b247d71-73b2-4d1d-80d5-a2f288344a21)

```sql

-- 4. Najczęściej używane lotnisko jako miejsce odlotu.

SELECT 
	a."CITY" as city, 
	COUNT(*) as number_of_departures
FROM 
	airports a
LEFT JOIN 
	flights f ON f."ORIGIN_AIRPORT" = a."IATA_CODE"
GROUP BY 
	city
ORDER BY 
	number_of_departures DESC;

```


![image](https://github.com/user-attachments/assets/76ff952c-a188-48bd-be4b-ea6947a97a5f)

```sql
-- 6. Średnie opóźnienie lotów w zależności od dnia miesiąca.

SELECT 
	flights."YEAR" as year, 
	flights."MONTH" as month,
	ROUND(AVG(flights."ARRIVAL_DELAY"),2) as avg_delay
FROM 
	flights
WHERE 
	flights."ARRIVAL_DELAY" > 0
GROUP BY 
	year, 
	month
ORDER BY 
	month

```

![image](https://github.com/user-attachments/assets/4f2f907c-7bdb-48bd-abb5-72e3af49e1de)


```sql
-- 7. Liczba lotów odbytych ze względu na linię lotniczą oraz miesiąc w 2025 roku.

WITH cte AS (
    SELECT 
        a."AIRLINE", 
        f."YEAR", 
        f."MONTH", 
        COUNT(*) AS number_of_flight
    FROM 
		flights f
    LEFT JOIN 
		airlines a ON f."AIRLINE" = a."IATA_CODE"
    GROUP BY 
		a."AIRLINE", f."YEAR", f."MONTH"
)

SELECT 
    cte."AIRLINE", 
    COALESCE(cte."YEAR"::TEXT, 'All Year') as year,
	cte."MONTH",
    SUM(cte.number_of_flight) AS total_flights
FROM 
	cte
GROUP BY ROLLUP(cte."AIRLINE", cte."YEAR", cte."MONTH");

```

![image](https://github.com/user-attachments/assets/b215d1fd-e6d8-410e-bf58-d94d03cd1815)


```sql
-- 9. Przedziały KM dla tras lotniczych odbytych

WITH bins AS (
	SELECT 
		generate_series(0,4500,500) AS lower,
		generate_series(500,5000,500) AS upper
),

distance AS(
	SELECT "DISTANCE" AS dist
	FROM flights
)
	
SELECT 
	lower,
	upper, 
	COUNT(dist)
FROM 
	bins
LEFT JOIN 
	distance
	ON dist >= lower
	AND dist < upper
GROUP BY 
	lower,upper
ORDER BY 
	lower
```

![image](https://github.com/user-attachments/assets/a7fc4bff-1692-43ac-8494-741f17ca6147)


```sql
-- 10. Podział anulowanmych lotów ze względu na powód anulowania oraz linię lotniczą 

WITH count_cancellation AS(
	SELECT 
		a."AIRLINE",
		cc."CANCELLATION_DESCRIPTION", 
		COUNT(*) AS count_cancellations
	FROM 
		flights f
	INNER JOIN 
		airlines a ON f."AIRLINE" = a."IATA_CODE"
	INNER JOIN 
		cancellation_codes cc ON f."CANCELLATION_REASON" = cc."CANCELLATION_REASON"
	GROUP BY 
		a."AIRLINE", cc."CANCELLATION_REASON", cc."CANCELLATION_DESCRIPTION"
	ORDER BY 
		COUNT(*) DESC
),

rank_crash AS(
	SELECT 
		*, 
		RANK() OVER (PARTITION BY "AIRLINE" ORDER BY count_cancellations DESC) AS rank,
		SUM (count_cancellations) OVER(PARTITION BY "AIRLINE") AS total_cancelattion_per_airline,
		SUM(count_cancellations) OVER() AS total_cancellations,
		ROUND((count_cancellations * 100.0) / SUM(count_cancellations) OVER(), 2) AS percentage
	FROM 
		count_cancellation
	)

SELECT * FROM rank_crash;
```

![image](https://github.com/user-attachments/assets/b779de11-e34a-413c-a6a9-50376875bb35)

```sql
-- 11. Znajdź wszystkie loty, które miały opóźnienie przybycia większe niż średnie opóźnienie przybycia w całej bazie danych.

SELECT 
	f."TAIL_NUMBER" as number_flight, 
	f."ARRIVAL_DELAY" as delay_minutes
FROM 
	flights f
WHERE 
	f."ARRIVAL_DELAY" >
		(SELECT AVG(f."ARRIVAL_DELAY")
		FROM flights f
		WHERE f."ARRIVAL_DELAY" > 0)


```

![image](https://github.com/user-attachments/assets/87f94d42-075f-4ee1-adc9-8ae7ebbff0e9)

```sql
-- 12. Ranking linii lotniczych pod względem punktualności (na podstawie odsetka lotów bez opóźnień).

WITH punctual AS (
	SELECT
		a."AIRLINE" as airline,
		COUNT(*) as total_flights,
		COUNT(CASE WHEN f."DEPARTURE_DELAY" <=0 THEN 1 END) as punctual_flights
	FROM 
		flights f
	LEFT JOIN 
		airlines a
	ON f."AIRLINE" = a."IATA_CODE"
	GROUP BY 
		airline
)

SELECT 
	*,
	ROUND(punctual_flights*100/total_flights,2) as percentage
FROM 
	punctual
ORDER BY 
	percentage DESC

```

![image](https://github.com/user-attachments/assets/cf3768f5-ec64-4fd6-9dee-5a9e783a1c4a)
**
