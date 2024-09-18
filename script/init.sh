#!/bin/bash

helpFunction()
{
   echo ""
   echo -e "\t-o Org of pgvecto.rs code to clone, like: tensorchord"
   echo -e "\t-p Project of pgvecto.rs code to clone, like: pgvecto.rs"
   echo -e "\t-b Branch to checkout, like: main"
   exit 1 # Exit script after printing help
}

while getopts "o:p:b:" opt
do
   case "$opt" in
      o ) parameterOrg="$OPTARG" ;;
      p ) parameterProj="$OPTARG" ;;
      b ) parameterBranch="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

if [ -z "$parameterOrg" ] || [ -z "$parameterBranch" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

if  [ -z "$parameterOrg" ]
then
   $parameterOrg = "tensorchord"
fi

if  [ -z "$parameterProj" ]
then
   $parameterProj = "pgvecto.rs"
fi

sudo apt-get update
sudo apt-get install -y build-essential curl git \
libncurses-dev libicu-dev bison flex cmake wget \
unzip python3 python3-venv zip
sudo apt remove -y postgresql-16

curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly

# Install aws s3 CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install

# Download datasets
names=( "sift" "gist" "glove" "cohere" "openai" )
dirs=( "sift_128_1m" "gist_960_1m" "glove_200_1m" "cohere_768_1m" "openai_1536_500k" )

for i in "${!names[@]}"; do
    aws s3 cp s3://pgvecto.rs-bench/${dirs[i]}/${names[i]}.tar.gz ${names[i]}.tar.gz --no-progress
    tar -zxvf ${names[i]}.tar.gz
    aws s3 cp s3://pgvecto.rs-bench/${dirs[i]}/${names[i]}.hdf5 ${names[i]}/${names[i]}.hdf5 --no-progress
done

git clone -b $parameterBranch https://github.com/$parameterOrg/$parameterProj.git

python3 -m venv $HOME/venv