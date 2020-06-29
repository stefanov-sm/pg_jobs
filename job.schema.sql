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
