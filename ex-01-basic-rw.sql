copy (
  select replace(location, ' ', '') as partition, year(date) as year, *
  from 'weather_data.csv'
) to 'parts' (format parquet, PARTITION_BY (partition, year), overwrite_or_ignore);

select * from 'parts/**/*.parquet';
