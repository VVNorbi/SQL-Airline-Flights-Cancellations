# SQL-Airline-Flights-Cancellations

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

![image](https://github.com/user-attachments/assets/9b59a40a-2ebc-42e8-a224-05ac653eace8)
