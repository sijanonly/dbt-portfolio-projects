with demand as (
    select * from {{ ref('stg_bike_demand') }}
)

select
    rental_date,
    season_name,
    rental_hour,
    weather_condition,
    is_holiday,
    total_rides,
    registered_rides,
    casual_rides,
    -- Analysis: Temperature 'Feels Like' Difference
    (feels_like_temp - temp) as temp_diff,
    -- Analysis: Peak Demand Logic
    case 
        when rental_hour between 7 and 9 then 'Morning Rush'
        when rental_hour between 16 and 19 then 'Evening Rush'
        else 'Off-Peak'
    end as demand_window
from demand
