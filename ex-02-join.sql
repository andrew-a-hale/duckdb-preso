-- Ex 1 
copy (
  select replace(location, ' ', '') as partition, year(date) as year, *
  from 'weather_data.csv'
) to 'parts' (format parquet, partition_by (partition, year), overwrite_or_ignore);

-- Ex 2
load excel;

copy (
  select location, (random() * 1000000)::int
  from 'weather_data.csv'
  group by location
) to 'pop.xlsx';

with pop as (
  select A1 as "location", B1 as pop
  from 'pop.xlsx'
)
select *
from 'parts/**/*.parquet'
left join pop using (location);
