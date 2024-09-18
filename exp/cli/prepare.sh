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

# Glove + Cos need norm, cannot be done by CLI

if [ "$parameterMetric" = "l2" ]; then METRIC="L2"
# elif [ "$parameterMetric" = "cos" ]; then METRIC="Cos"
else echo "Unsupported metric"; helpFunction
fi

if [ "$parameterDataName" = "sift" ]; then DIM="128"
elif [ "$parameterDataName" = "gist" ]; then DIM="960"
elif [ "$parameterDataName" = "glove" ]; then DIM="200"
elif [ "$parameterDataName" = "cohere" ]; then DIM="768"
elif [ "$parameterDataName" = "openai" ]; then DIM="1536"
else echo "Unsupported dataset"; helpFunction
fi

INDEX_PATH="$HOME/indexes/cli/$parameterDataName/$parameterMetric"
BASE_PATH="$HOME"/"$parameterDataName"/"$parameterDataName"_base.fvecs
QUERY_PATh="$HOME"/"$parameterDataName"/"$parameterDataName"_query.fvecs
TRUTH_PATH="$HOME"/"$parameterDataName"/"$parameterDataName"_groundtruth.ivecs

# Install CLI bindings
. $HOME/.cargo/env
RUSTFLAGS="-C target-cpu=native -C opt-level=3" cargo build -p cli --release \
--manifest-path $HOME/pgvecto.rs/Cargo.toml --target-dir $HOME

$HOME/release/cli -p $INDEX_PATH create --dim $DIM --distance $METRIC --threads 8 '
    [ivf]
    nlist = 4096
    residual_quantization = true
    [ivf.quantization]
    rabitq = { }
'
$HOME/release/cli -p $INDEX_PATH add --file $BASE_PATH