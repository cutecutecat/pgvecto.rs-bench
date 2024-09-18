#!/bin/bash

helpFunction()
{
   echo ""
   echo -e "\t-m Metric to pick, in l2 or cos"
   echo -e "\t-n Dataset name, like: sift"
   exit 1 # Exit script after printing help
}

while getopts "m:n:" opt
do
   case "$opt" in
      m ) parameterMetric="$OPTARG" ;;
      n ) parameterDataName="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

if [ -z "$parameterMetric" ] || [ -z "$parameterDataName" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi


INDEX_PATH="$HOME/indexes/cli/$parameterDataName/$parameterMetric"
QUERY_PATh="$HOME"/"$parameterDataName"/"$parameterDataName"_query.fvecs
TRUTH_PATH="$HOME"/"$parameterDataName"/"$parameterDataName"_groundtruth.ivecs

$HOME/release/cli -p $INDEX_PATH query \
--query $QUERY_PATh \
--truth $TRUTH_PATH --top-k 10 --probe 300

$HOME/release/cli -p $INDEX_PATH query \
--query $QUERY_PATh \
--truth $TRUTH_PATH --top-k 100 --probe 300