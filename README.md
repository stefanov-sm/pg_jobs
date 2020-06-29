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
