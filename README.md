# pg_jobs

### Scheduled jobs in Postgresql

example/job.agent.php is scheduled to run every minute

```php
<?php
define('HERE', __DIR__.DIRECTORY_SEPARATOR);
define('PENDING_JOBS_SQL',  'SELECT jobid FROM jobs.pending() t(jobid)');
define('WORKER_OS_COMMAND', 'php '.HERE.'job.worker.php ');

if (PHP_SAPI !== 'cli') exit(-1);
require(HERE.'job.helpers.php'); // PDO_connection() and background_run() defs

$conn = PDO_connection(); // or obtain a PDO connecion in your preferred way
$rs = $conn -> query(PENDING_JOBS_SQL);
while ($jobid = $rs -> fetchColumn()) background_run(WORKER_OS_COMMAND.$jobid);
```
