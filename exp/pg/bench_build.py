from os.path import join
import os
import time
import argparse
from pathlib import Path

import psycopg
import h5py
from pgvecto_rs.psycopg import register_vector
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument(
    "-m", "--metric", help="Metric to pick, in l2 or cos", required=True
)
parser.add_argument("-n", "--name", help="Dataset name, like: sift", required=True)
args = parser.parse_args()

HOME = Path.home()
INDEX_PATH = join(HOME, f"indexes/pg/{args.name}/{args.metric}")
DATA_PATH = join(HOME, f"{args.name}/{args.name}.hdf5")

os.makedirs(join(HOME, f"indexes/pg/{args.name}"), exist_ok=True)
dataset = h5py.File(DATA_PATH, "r")

train = dataset["train"][:]
test = dataset["test"][:]

if args.metric == "l2":
    metric_ops = "vector_l2_ops"
    ivf_config = """
optimizing.optimizing_threads = 8
[indexing.ivf]
nlist = 4096
residual_quantization = true
spherical_centroids = false
[indexing.ivf.quantization.rabitq]
"""
elif args.metric == "cos":
    metric_ops = "vector_cos_ops"
    ivf_config = """
optimizing.optimizing_threads = 8
[indexing.ivf]
nlist = 4096
residual_quantization = false
spherical_centroids = true
[indexing.ivf.quantization.rabitq]
"""
else:
    raise ValueError

answer = dataset["neighbors"][:]
n, dims = np.shape(train)
m = np.shape(test)[0]


# enable extensions
conn = psycopg.connect(
    conninfo="postgres://bench:123@localhost:5432/postgres",
    dbname="postgres",
    autocommit=True,
)
conn.execute("CREATE EXTENSION IF NOT EXISTS vectors")
register_vector(conn)

conn.execute("DROP TABLE IF EXISTS items")
conn.execute("CREATE TABLE items (id integer, embedding vector(%d))" % dims)

with conn.cursor().copy(
    "COPY items (id, embedding) FROM STDIN WITH (FORMAT BINARY)"
) as copy:
    copy.set_types(["integer", "vector"])

    for i in range(n):
        copy.write_row([i, train[i]])
        while conn.pgconn.flush() == 1:
            pass

start = time.perf_counter()
conn.execute(
    f"CREATE INDEX ON items USING vectors (embedding {metric_ops}) WITH (options = $${ivf_config}$$)"
)
end = time.perf_counter()

delta = end - start
print(f"Index build time: {delta:.2f}s")
