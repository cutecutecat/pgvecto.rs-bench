from os.path import join
import os
import argparse
from pathlib import Path
import time

import h5py
import sklearn.preprocessing
import vectors
import numpy


parser = argparse.ArgumentParser()
parser.add_argument(
    "-m", "--metric", help="Metric to pick, in l2 or cos", required=True
)
parser.add_argument("-n", "--name", help="Dataset name, like: sift", required=True)
args = parser.parse_args()

HOME = Path.home()
INDEX_PATH = join(HOME, f"indexes/pyo3/{args.name}/{args.metric}")
DATA_PATH = join(HOME, f"{args.name}/{args.name}.hdf5")

os.makedirs(join(HOME, f"indexes/pyo3/{args.name}"), exist_ok=True)
dataset = h5py.File(DATA_PATH, "r")

if args.metric == "l2":
    metric = "l2"
    train = dataset["train"][:]
    test = dataset["test"][:]
    ivf_config = {
        "nlist": 4096,
        "residual_quantization": True,
        "spherical_centroids": False,
        "quantization": {"rabitq": {}},
    }
elif args.metric == "cos":
    metric = "dot"
    train = sklearn.preprocessing.normalize(dataset["train"][:], axis=1, norm="l2")
    test = sklearn.preprocessing.normalize(dataset["test"][:], axis=1, norm="l2")
    ivf_config = {
        "nlist": 4096,
        "residual_quantization": False,
        "spherical_centroids": True,
        "quantization": {"rabitq": {}},
    }
else:
    raise ValueError

answer = dataset["neighbors"][:]
n, dims = numpy.shape(train)
m = numpy.shape(test)[0]

start = time.perf_counter()
index = vectors.Indexing.create(
    INDEX_PATH,
    metric,
    dims,
    train,
    numpy.arange(n, dtype=numpy.int64),
    ivf=ivf_config,
)
end = time.perf_counter()
delta = end - start
print(f"Index build time: {delta:.2f}s")
