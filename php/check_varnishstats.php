#!/usr/bin/php
<?php

/**
 * Monitor and process Varnish Data
 * @author Gianni Carafa
 * @Created:  14-Nov-2012 Gianni
 * @modified: 14-Nov-2012 Gianni
 */
//set path to your varnishstat output files. They need to be genereated with a cronjob
$PATHTOFILES = "/tmp";

error_reporting(0);

if (count($argv) != 5) {
    echo "Missing Argument!\n";
    echo "Usage: " . $argv[0] . " <HOSTNAME> <WARNINGS> <CRITICALS>\n";
    echo "  HOSTNAME: Hostname of the Checked Varnishhost\n";
    echo "  WARNINGS: Kommaseparated values of Warnlevel (per Second)\n";
    echo "  CRITICALS: Kommaseparated values of Criticallevel (per Second)\n";

    echo "Usefull Fields:  client_conn,client_drop,client_req,cache_hit,cache_miss,backend_conn,backend_fail,fetch_bad,n_object \n\n";
    exit(3);
}

$fields = $argv[2];
$warning_arr = explode(",", $argv[3]);
$critical_arr = explode(",", $argv[4]);

//client_conn,client_drop,client_req,cache_hit,cache_miss,backend_conn,backend_fail,fetch_bad,n_object
/*
$varnishstatCMD = "ssh ".$argv[1]." 'varnishstat -f $fields -j -1'";
$contentNow = shell_exec($varnishstatCMD);
$dataNow = json_decode($contentNow , true);
*/

$contentNow = file_get_contents("{$PATHTOFILES}/{$argv[1]}.now.json");
$dataNow = json_decode($contentNow , true);


$contentOld = file_get_contents("{$PATHTOFILES}/{$argv[1]}.old.json");
$dataOld = json_decode($contentOld , true);

$dataNow['time'] = strtotime($dataNow['timestamp']);
$dataOld['time'] = strtotime($dataOld['timestamp']);
$dataDiv['seconds_since_lastcheck'] = $dataNow['time'] - $dataOld['time'];

$status = "last run ".$dataDiv['seconds_since_lastcheck']."s ago";
$error = "OK: ";
$warn = "";
$crit = "";
$i=0;
foreach ($dataNow as $key => $val) {
    if ($dataNow[$key]['flag'] == "a"){
        $dataDiv[$key]['val'] = $dataNow[$key]['value'] - $dataOld[$key]['value'];
        $dataDiv[$key]['persecond'] = number_format(round( $dataDiv[$key]['val'] / $dataDiv['seconds_since_lastcheck'], 2), 2);
        $return .= "$key:{$dataNow[$key]['value']},{$dataDiv[$key]['val']},{$dataDiv[$key]['persecond']} ";
        if (isset($warning_arr[$i]) && $dataDiv[$key]['persecond']>$warning_arr[$i]){
            $warn .= " $key:{$dataDiv[$key]['persecond']} > $warning_arr[$i] ";
        }
        if(isset($critical_arr[$i]) && $dataDiv[$key]['persecond']>$critical_arr[$i]){
            $crit .= " $key:{$dataDiv[$key]['persecond']} > $critical_arr[$i] ";
        }
        $i++;
    }
    if ($dataNow[$key]['flag'] == "i"){
        $dataDiv[$key]['val'] = $dataNow[$key]['value'];
        $dataDiv[$key]['div'] = $dataNow[$key]['value'] - $dataOld[$key]['value'];
        $return .= "$key:{$dataDiv[$key]['val']} {$dataDiv[$key]['div']} | ";
        $i++;
    }
}

if (strlen($warn)>1){
    $error = "WARNING: ";
}
if(strlen($crit)>1){
    $error = "CRITICAL: ";
}


echo $error.$status.$warn.$crit." | ".$return;


if ($dataNow['time'] > $dataOld['time']) {
    file_put_contents("{$PATHTOFILES}/{$argv[1]}.old.json", $contentNow);
}
