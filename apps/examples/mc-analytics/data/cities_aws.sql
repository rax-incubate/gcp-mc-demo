CREATE EXTERNAL TABLE mcdemoaws.cities
  WITH CONNECTION `aws-us-east-1.bq-omni-aws-connection`
  OPTIONS (
    format = "PARQUET",
    uris = ["s3://bq-test-gfytoj/cities.parquet"],
    max_staleness = INTERVAL 4 HOUR,
    metadata_cache_mode = 'AUTOMATIC');