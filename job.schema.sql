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

-- The example
insert into jobs.job_schedule (schedule, job_name, job_definition) values 
(
 '{"day": [], "dow": [], "mon": [], "repeat": {"from": "00:00", "till": "23:59", "every": "PT3M"}}',
 'Repeat this every three minutes', 
 '{"query": "select 1 as one", "message": "The one that repeats every three minutes"}'
), 
(
 '{"day": [28], "dow": [], "mon": [6, 7, 8], "time": ["00:30"]}',
 'Run only once in June, July and August',
 '{"message": "The one that runs once per month", "process": "run-me.exe"}'
);

create table if not exists jobs.log 
(
 message text,
 time_created timestamp default now()
);

