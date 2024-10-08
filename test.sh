#!/bin/bash

server_bin_name="gowebbenchmark"

. ./libs.sh

length=${#web_frameworks[@]}

test_result=()

cpu_cores=$(< "/proc/cpuinfo" grep -c processor)
if [ $cpu_cores -eq 0 ]
then
  cpu_cores=1
fi

test_web_framework()
{
  echo "testing web framework: $2"
  ./$server_bin_name $2 $3 & sleep 2

  throughput=$(wrk -t$cpu_cores -c$4 -d30s http://127.0.0.1:8080/hello)
  echo "$throughput"
  test_result[$1]=$(echo "$throughput" | grep Requests/sec | awk '{print $2}')

  pkill -9 $server_bin_name
  sleep 1
  echo "finished testing $2"
  echo
}

test_all()
{
  echo "###################################"
  echo "                                   "
  echo "      ProcessingTime  $1ms         "
  echo "      Concurrency     $2           "
  echo "                                   "
  echo "###################################"
  for ((i=0; i<length; i++))
  do
  	test_web_framework $i ${web_frameworks[$i]} $1 $2
  done
}


pkill -9 $server_bin_name

echo ","$(IFS=$','; echo "${web_frameworks[*]}" ) > processtime.csv
test_all 0 100
echo "100 concurrency,"$(IFS=$','; echo "${test_result[*]}" ) >> processtime.csv
test_all 0 500
echo "500 concurrency,"$(IFS=$','; echo "${test_result[*]}" ) >> processtime.csv
test_all 0 1000
echo "1000 concurrency,"$(IFS=$','; echo "${test_result[*]}" ) >> processtime.csv
test_all 0 2500
echo "2500 concurrency,"$(IFS=$','; echo "${test_result[*]}" ) >> processtime.csv
test_all 0 5000
echo "5000 concurrency,"$(IFS=$','; echo "${test_result[*]}" ) >> processtime.csv


mv -f processtime.csv ./testresults
