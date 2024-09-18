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

# Install release bindings
export PGRX_PG_CONFIG_PATH=$HOME/pgvecto.rs/vendor/pg16_x86_64_debian/pg_config/pg_config
export PGRX_TARGET_INFO_PATH_PG16=$HOME/pgvecto.rs/vendor/pg16_x86_64_debian/pgrx_binding

. $HOME/.cargo/env
cd $HOME/pgvecto.rs/
cargo build --package pgvectors --lib --features pg16 --target x86_64-unknown-linux-gnu --release
./tools/schema.sh --features pg16 --target x86_64-unknown-linux-gnu --release | expand -t 4 > ./target/schema.sql

export SEMVER="0.0.0"
export VERSION="16"
export ARCH="x86_64"
export PLATFORM="amd64"
./scripts/package.sh

# Install postgres and extension
sudo apt install -y postgresql-16
sudo apt install -y ./build/vectors-pg16_0.0.0_amd64.deb

sudo -u postgres psql -U postgres -c "CREATE USER bench WITH PASSWORD '123';"
sudo -u postgres psql -U postgres -c "ALTER ROLE bench SUPERUSER;"
sudo -u postgres psql -U postgres -c 'ALTER SYSTEM SET shared_preload_libraries = "vectors.so"'
sudo -u postgres psql -U postgres -c 'ALTER SYSTEM SET search_path TO "$user", public, vectors'

sudo systemctl restart postgresql.service

sleep 20

pip3 install psycopg pgvecto_rs h5py numpy

BASEDIR=$(dirname $0)
python3 $BASEDIR/bench_build.py -n $parameterDataName -m $parameterMetric