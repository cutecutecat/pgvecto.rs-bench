import h5py
import struct
import tarfile
from tqdm import tqdm
import requests
import os


def load_hdf5_file(filename):
    f = h5py.File(filename, "r")
    return f


def to_fvecs(filename, data):
    with open(filename, "wb") as fp:
        for y in data:
            d = struct.pack("I", y.size)
            fp.write(d)
            for x in y:
                a = struct.pack("f", x)
                fp.write(a)


def to_ivecs(filename, data):
    with open(filename, 'wb') as fp:
        for y in data:
            d = struct.pack('I', y.size)
            fp.write(d)
            for x in y:
                a = struct.pack('I', x)
                fp.write(a)


def download(url: str, fname: str, chunk_size=1024):
    resp = requests.get(url, stream=True)
    total = int(resp.headers.get("content-length", 0))
    with open(fname, "wb") as file, tqdm(
        desc=fname,
        total=total,
        unit="iB",
        unit_scale=True,
        unit_divisor=1024,
    ) as bar:
        for data in resp.iter_content(chunk_size=chunk_size):
            size = file.write(data)
            bar.update(size)


META = {
    "glove": "http://ann-benchmarks.com/glove-200-angular.hdf5",
    "sift": "http://ann-benchmarks.com/sift-128-euclidean.hdf5",
    "gist": "http://ann-benchmarks.com/gist-960-euclidean.hdf5",
}

if __name__ == "__main__":
    for name, link in META.items():
        # os.makedirs(name, exist_ok=True)
        # download(link, f"{name}/{name}.hdf5")
        f = load_hdf5_file(f"{name}/{name}.hdf5")
        to_fvecs(f"{name}/{name}_base.fvecs", f["train"])
        to_fvecs(f"{name}/{name}_query.fvecs", f["test"])
        to_ivecs(f"{name}/{name}_groundtruth.ivecs", f["neighbors"])

        tar = tarfile.open(f"{name}.tar.gz", "w:gz")
        for name in [
            f"{name}/{name}_base.fvecs",
            f"{name}/{name}_query.fvecs",
            f"{name}/{name}_groundtruth.ivecs",
        ]:
            tar.add(name)
        tar.close()
