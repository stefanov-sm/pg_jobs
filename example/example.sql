insert into jobs.job_schedule (schedule, job_name, job_definition) values 
(
 '{"day": [], "dow": [], "mon": [], "repeat": {"from": "00:00", "till": "23:59", "every": "PT3M"}}',
 'Repeat this every three minutes', 
 '{"query": "select 1 as one", "message": "Repeats every three minutes"}'
), 
(
 '{"day": [28], "dow": [], "mon": [6, 7, 8], "time": ["00:30"]}',
 'Run only once in June, July and August',
 '{"message": "Runs once per month", "process": "run-me.exe"}'
);

create table if not exists jobs.log 
(
 message text,
 time_created timestamp default now()
);
