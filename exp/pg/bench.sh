#!/bin/bash

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

if [ "$parameterMetric" = "l2" ]; then METRIC="L2"
elif [ "$parameterMetric" = "cos" ]; then METRIC="Cos"
else echo "Unavailable metric"; helpFunction
fi

python3 -m venv $HOME/venv
source $HOME/venv/bin/activate

BASEDIR=$(dirname $0)
python3 $BASEDIR/bench_load.py -n $parameterDataName -m $parameterMetric