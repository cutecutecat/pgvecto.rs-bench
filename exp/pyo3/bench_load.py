from os.path import join
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
dataset = h5py.File(DATA_PATH, "r")

if args.metric == "l2":
    metric = "l2"
elif args.metric == "cos":
    metric = "dot"
else:
    raise ValueError

if args.name == "glove":
    train = sklearn.preprocessing.normalize(dataset["train"][:], axis=1, norm="l2")
    test = sklearn.preprocessing.normalize(dataset["test"][:], axis=1, norm="l2")
else:
    train = dataset["train"][:]
    test = dataset["test"][:]

answer = dataset["neighbors"][:]
n, dims = numpy.shape(train)
m = numpy.shape(test)[0]

index = vectors.Indexing.open(INDEX_PATH)

Ks = [10, 100]
for k in Ks:
    start = time.perf_counter()
    _, result = index.search(test, k, ivf_nprobe=300, rq_fast_scan=True)
    end = time.perf_counter()

    hits = sum(
        map(
            lambda i: len(set(result[i][:k].tolist()) & set(answer[i][:k].tolist())),
            range(m),
        )
    )
    delta = end - start
    recall = hits / k / m
    qps = m / delta
    print(f"Top: {k} recall: {recall:.4f} QPS: {qps:.2f}")
