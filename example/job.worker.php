<?php
define('HERE', __DIR__.DIRECTORY_SEPARATOR);
define('CURRENT_JOB_SQL', 'SELECT job_definition FROM jobs.job_schedule WHERE id = ?;');
define('WORKER_JOB_SQL',  'INSERT INTO jobs.log (message) VALUES (?);');
define('JOBID_RX', '/^\\d+$/');

$jobid = (PHP_SAPI === 'cli' && isset($argv[1])) ? $argv[1]: '';
if (empty($jobid) || !preg_match(JOBID_RX, $jobid)) exit(-1);
require(HERE.'job.helpers.php');
$now = date('Y-m-d H:i:s');
$conn = PDO_connection(); // or obtain a PDO connecion in your preferred way

$rs = $conn -> prepare(CURRENT_JOB_SQL);
$rs -> execute([$jobid]);
$job_definition = json_decode($rs -> fetchColumn());
$rs = $conn -> prepare(WORKER_JOB_SQL);
$rs -> execute(["Job '{$job_definition -> message}' invoked in {$now}"]);
