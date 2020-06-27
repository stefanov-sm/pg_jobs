<?php
// Async run an OS command in the background
function bgnd_run($os_cmd)
{
  if (in_array(PHP_OS, ['WINNT', 'WIN32', 'WIN64', 'Windows']))
  {
    pclose(popen('start "Background" /min '. $os_cmd, 'r'));
  }
  else
  {
    exec($os_cmd . ' > /dev/null &');
  }
}

function PDO_connection()
{
	$conn = new PDO('pgsql: host=<host-name>; dbname=<database-name>; user=<user-name>; password=<secret>');
	$conn -> setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
	$conn -> setAttribute(PDO::ATTR_EMULATE_PREPARES, FALSE);
	return $conn;
}
