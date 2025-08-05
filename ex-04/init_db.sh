#!/bin/bash

duckdb md: -c "\
install ducklake;
install s3;

CREATE DATABASE if not exists metaduck (
    TYPE DUCKLAKE,
    DATA_PATH 's3://austender/bronze'
);

-- Create the table within the new DuckLake database
CREATE TABLE if not exists metaduck.raw_tenders (
  uri varchar
  , publisher_name varchar
  , published_date datetime
  , license varchar
  , version varchar
  , releases $(cat releases_schema_duckdb.txt)
  , extensions varchar[]
  , links json
);"

# Initialize the local job tracking database
duckdb dat.db -c "\
create table if not exists jobs (
  job_id date primary key
  , attempts int
  , processed_at datetime
  , completed_at datetime
  , last_error_msg varchar
);

insert into jobs
select
  today() + generate_series::int as job_id
  , 0 as attempts
  , null::datetime as processed_at
  , null::datetime as completed_at
  , null::varchar as last_error_msg
from generate_series(date '2013-01-01' - today(), 0)
on conflict do nothing;

create table if not exists dlq (
  job_id date primary key
  , attempts int
  , processed_at datetime
  , last_error_msg varchar
);"
