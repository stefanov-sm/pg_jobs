# pg_jobs

### Scheduled jobs in Postgresql
SQL function **jobs.pending()** scans table **jobs.schedule** and returns the id-s of the jobs that are to be run  
  
**example/job.agent.php** is scheduled to run every minute

job.agent.php:
```php
<?php
define('PENDING_JOBS_SQL', 'SELECT jobid FROM jobs.pending() t(jobid)');

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
jobs database schema:
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
