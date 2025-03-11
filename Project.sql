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
	ROUND(all_distance/number_of_flights,2) AS avg_flight_distance
FROM 
	flight
ORDER BY 
	avg_flight_distance DESC; 

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


-- 3. Średnie opóźnienie przylotów dla każdej linii lotniczej.

SELECT 
	a."AIRLINE",
	ROUND(AVG(f."ARRIVAL_DELAY"),2) AS delay
FROM 
	flights f
LEFT JOIN 
	airlines a ON f."AIRLINE" = a."IATA_CODE"
WHERE 
	f."ARRIVAL_DELAY" > 0
GROUP BY 
	a."AIRLINE"
ORDER BY 
	delay DESC;


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


-- 5️. Liczba lotów przekierowanych w stosunku do wszystkich lotów.

SELECT 
	ROUND((COUNT(CASE WHEN flights."DIVERTED" = true THEN 1 END)::NUMERIC / COUNT(*))*100,2) as percent
FROM flights


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


-- 8. Podział lotów ze względu na odległość trasy

SELECT 
	trunc("DISTANCE",-3) AS group_distance, 
	COUNT(*) as number_flights
FROM 
	flights
GROUP BY 
	group_distance;


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



-- 11. Znajdź wszystkie loty, które miały opóźnienie przybycia większe niż średnie opóźnienie przybycia w całej bazie danych.

SELECT 
	f."TAIL_NUMBER" as number_flight, 
	f."ARRIVAL_DELAY" as delay
FROM 
	flights f
WHERE 
	f."ARRIVAL_DELAY" >
		(SELECT AVG(f."ARRIVAL_DELAY")
		FROM flights f
		WHERE f."ARRIVAL_DELAY" > 0)


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






