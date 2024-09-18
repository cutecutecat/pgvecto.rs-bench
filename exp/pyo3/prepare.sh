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

source $HOME/venv/bin/activate

# Install PYO3 bindings
pip3 install maturin numpy h5py scikit-learn

cd $HOME/pgvecto.rs/crates/pyvectors
# Enable Cargo
. $HOME/.cargo/env
maturin build --profile opt -o .

pip3 install vectors-0.0.0-cp312-cp312-manylinux_2_34_x86_64.whl

BASEDIR=$(dirname $0)
python3 $BASEDIR/bench_build.py -n $parameterDataName -m $parameterMetric