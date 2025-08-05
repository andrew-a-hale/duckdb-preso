-- Ex 3
duckdb -json -c "\
select *
from 'https://github.com/andrew-a-hale/open-motogp/raw/refs/heads/master/data-lake/gold/mgp.parquet'
limit 10"
