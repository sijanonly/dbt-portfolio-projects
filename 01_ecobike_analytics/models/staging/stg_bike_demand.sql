with source as (
    select * from {{ ref('raw_bike_demand') }}
),

renamed as (
    select
        -- Parsing the datetime string into a proper timestamp
        cast(datetime as timestamp) as rental_at,
        
        -- Extracting time parts for analysis
        extract(hour from cast(datetime as timestamp)) as rental_hour,
        date_trunc('day', cast(datetime as timestamp)) as rental_date,
        
        case season
            when 1 then 'Spring'
            when 2 then 'Summer'
            when 3 then 'Fall'
            when 4 then 'Winter'
        end as season_name,
        
        holiday = 1 as is_holiday,
        workingday = 1 as is_working_day,
        
        case weather
            when 1 then 'Clear'
            when 2 then 'Mist/Cloudy'
            when 3 then 'Light Snow/Rain'
            when 4 then 'Heavy Rain/Ice'
        end as weather_condition,
        
        temp,
        atemp as feels_like_temp,
        humidity,
        windspeed,
        casual as casual_rides,
        registered as registered_rides,
        "count" as total_rides -- 'count' is a reserved word, so we use quotes
    from source
)

select * from renamed
