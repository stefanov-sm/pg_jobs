# pg_jobs

### Scheduled jobs in Postgresql
SQL function **jobs.pending()** scans table **jobs.schedule** and returns the id-s of the jobs that are to be run  
  
**example/job.agent.php** is scheduled to run every minute and invokes the OS worker in the background for every pending job passing the job id as a command line argument. 

**job.agent.php**:
```php
<?php
define('PENDING_JOBS_SQL', 'SELECT jobid FROM jobs.pending() as t(jobid)');

define('HERE', __DIR__.DIRECTORY_SEPARATOR);
define('WORKER_OS_COMMAND', 'php '.HERE.'job.worker.php ');

if (PHP_SAPI !== 'cli') exit(-1);
require(HERE.'job.helpers.php'); // PDO_connection() and background_run() defs

$conn = PDO_connection(); // or obtain a PDO connecion in your preferred way
$rs = $conn -> query(PENDING_JOBS_SQL);
while ($jobid = $rs -> fetchColumn())
{
  background_run(WORKER_OS_COMMAND.$jobid);
}
```
**jobs** database schema:
```sql
create schema if not exists jobs;

create table if not exists jobs.job_schedule
(
 id serial primary key not null,
 schedule jsonb not null,
 job_name text,
 job_definition jsonb not null
);

create or replace function jobs.pending() returns setof integer language sql as
$$
 SELECT id
 from jobs.job_schedule
 where
 (
   exists
   (
     select 1
     from jsonb_array_elements_text(schedule->'time') t
     where date_trunc('minute', now())::time = t::time
   )
   or exists
   (
     select 1
     from generate_series
     (
       now()::date + (schedule->'repeat'->>'from')::time,
       now()::date + (schedule->'repeat'->>'till')::time,
       (schedule->'repeat'->>'every')::interval
     ) t
     where date_trunc('minute', now()) = date_trunc('minute', t)
   )
 )
 and (coalesce(jsonb_array_length(schedule->'dow'), 0) = 0 or extract("ISODOW" from now()) in (select i::integer from jsonb_array_elements_text(schedule->'dow') i))
 and (coalesce(jsonb_array_length(schedule->'day'), 0) = 0 or extract("DAY"    from now()) in (select i::integer from jsonb_array_elements_text(schedule->'day') i))
 and (coalesce(jsonb_array_length(schedule->'mon'), 0) = 0 or extract("MONTH"  from now()) in (select i::integer from jsonb_array_elements_text(schedule->'mon') i));
$$;
```
Field **jobs.job_schedule.schedule** JSON schema:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ScheduleItem",
  "description": "Schedule list item",
  "type": "object",
  "properties":
  {
    "mon":
    {
      "description": "Months restriction",
      "type": "array",
      "items": {"type": "integer", "enum": [1,2,3,4,5,6,7,8,9,10,11,12]},
      "minItems": 0,
      "uniqueItems": true
    },
    "day":
    {
      "description": "Days restriction",
      "type": "array",
      "items": {"type": "integer", "minimum": 1, "maximum": 31},
      "minItems": 0,
      "uniqueItems": true
    },
    "dow":
    {
      "description": "Days of week restriction",
      "type": "array",
      "items": {"type": "integer", "enum": [1,2,3,4,5,6,7]},
      "minItems": 0,
      "uniqueItems": true
    },
    "time":
    {
      "description": "Time to run",
      "type": "array",
      "items": {"type": "string", "pattern": "^\\d{2}:\\d{2}$"},
      "minItems": 0,
      "uniqueItems": true
    },
    "repeat":
    {
      "description": "Run every period of time",
      "type": "object",
      "properties":
      {
        "from":  {"type": "string", "pattern": "^\\d{2}:\\d{2}$"},
        "till":  {"type": "string", "pattern": "^\\d{2}:\\d{2}$"},
        "every": {"type": "string", "pattern": "^PT(\\d{2}H)?\\d{2}M$"}
      }
    }
  },
  "oneOf": [{"required": ["time"]}, {"required": ["repeat"]}],
  "additionalProperties": false
}
```
See the example in file **job.schema.sql**.
