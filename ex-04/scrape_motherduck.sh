#!/bin/bash
set -e

export S3_DATA_PATH="s3://austender/bronze"

DUCKDB_PREAMBLE="\
install ducklake;
install s3;
attach 'ducklake:md:__ducklake_metadata_metaduck' as lake;"

ARCHIVE=archive/
export DUCKDB_RAW_TENDER_COLS="{
  uri: 'varchar'
  , publisher_name: 'varchar'
  , published_date: 'datetime'
  , license: 'varchar'
  , version: 'varchar'
  , releases: '$(cat releases_schema_duckdb.txt)'
  , extensions: 'varchar[]'
  , links: 'json'
}"
export TYPE=contractStart
export RAW=data
export LOG=$(date "+%Y%m%d%H%M%S%3N").log

# setup local dirs
[ -d "$ARCHIVE" ] || mkdir -p "$ARCHIVE"
[ -d "$RAW" ] || mkdir -p "$RAW"
[ -e "$LOG" ] || touch "$LOG"

function call() {
  start="$1"T00:00:00Z
  end="$1"T23:59:59Z

  payload=$(curl -s "https://api.tenders.gov.au/ocds/findByDates/$TYPE/$start/$end")
  err=$(echo "$payload" | jq -r '.errorCode // empty')

  if [ -n "$err" ]; then
    echo "{\"level\": \"ERROR\", \"job_id\": \"$1\", \"msg\": \"$err\"}" >>"$LOG"
  else
    out_dir="$RAW/$(date -j -f "%Y-%m-%d" "$1" "+%Y-%m-%d")"
    mkdir -p "$out_dir"
    out_file="$out_dir/data.parquet"
    if echo "$payload" | duckdb -c "COPY (SELECT * FROM read_json_auto('/dev/stdin', columns=$DUCKDB_RAW_TENDER_COLS)) TO '$out_file' (FORMAT 'parquet')"; then
      echo "{\"level\": \"SUCCESS\", \"job_id\": \"$1\"}" | tee "$LOG"
    else
      echo "{\"level\": \"ERROR\", \"job_id\": \"$1\", \"msg\": \"duckdb conversion failed\"}" | tee "$LOG"
    fi
  fi
}
export -f call

# Job Queue
# job_id is the date
jobs=$(duckdb dat.db -list -noheader -c "select job_id from jobs where completed_at is null and attempts < 3")
[ $(wc -w <<<$jobs) -eq 0 ] && rm $LOG && exit 0

# EXTRACT
TICK=$(date +%s%N)
parallel call ::: $jobs
TOCK=$(date +%s%N)
ELAPSED=$((TOCK - TICK))
REQUESTS=$(wc -l <$LOG)
MS=$((ELAPSED / 1000000))
echo "SCRAPE -- Elapsed time: $MS ms"
echo "SCRAPE -- RPS: $((REQUESTS * 1000 / $MS))"

# Update Job Queue
cat $LOG |
  jq -c -r 'select(.level == "SUCCESS")' |
  duckdb dat.db -c "\
  update jobs
  set attempts = attempts + 1, processed_at = now(), completed_at = now()
  from read_json('/dev/stdin', columns = {job_id: 'datetime'}) as i
  where jobs.job_id = i.job_id"

cat $LOG |
  jq -c -r 'select(.level == "ERROR")' |
  duckdb dat.db -c "\
  update jobs
  set attempts = attempts + 1, processed_at = now(), last_error_msg = msg
  from read_json('/dev/stdin', columns = {job_id: 'datetime', msg: 'varchar'}) as i
  where jobs.job_id = i.job_id"

duckdb dat.db -c "\
  insert into dlq (job_id, attempts, processed_at, last_error_msg)
  select job_id, attempts, processed_at, last_error_msg
  from jobs
  where attempts > 2;

  delete from jobs where attempts > 2;"

# LOAD
TICK=$(date +%s%N)
duckdb -c "$DUCKDB_PREAMBLE insert into lake.raw_tenders from '$RAW/**/*.parquet'"
TOCK=$(date +%s%N)
ELAPSED=$((TOCK - TICK))
echo "LOAD -- Elapsed time: $((ELAPSED / 1000000)) ms"

# Clean Up
mv $LOG archive/$LOG
