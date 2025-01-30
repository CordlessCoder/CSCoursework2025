#!/usr/bin/env python3
from urllib3 import PoolManager, HTTPHeaderDict
from typing import Optional
import os
from tqdm import tqdm
import shutil

pool = PoolManager()


def get_content_length(headers: HTTPHeaderDict) -> Optional[int]:
    length = headers.get("Content-Length", None)
    if length is None:
        return None

    try:
        return int(length)
    except ValueError:
        return None


direct_sources: dict[str, str] = {
    "DOI-WGMS-FoG-2024-01.zip": "https://wgms.ch/downloads/DOI-WGMS-FoG-2024-01.zip",
    "MTM02_Temperature.csv": "https://ws.cso.ie/public/api.restful/PxStat.Data.Cube_API.ReadDataset/MTM02/CSV/1.0/en",
}


if not os.path.isdir("raw_data"):
    print("Cannot find the `raw_data` directory to download files into.")
    print("Please create it, or navigate to the proper directory.")
    exit(1)

for name, source in direct_sources.items():
    path = "raw_data/" + name
    if (
        os.path.exists(path)
        or name.endswith(".zip")
        and os.path.isdir("raw_data/" + name[:-4])
    ):
        print(f"{path} is already downloaded, skipping")
        continue

    with (
        pool.request("GET", source, preload_content=False) as conn,
        open(path, "xb") as out,
        tqdm(
            total=get_content_length(conn.headers),
            desc=name,
            unit="B",
            unit_scale=True,
        ) as bar,
    ):
        try:
            while True:
                read = conn.read(4096)
                if len(read) == 0:
                    break
                out.write(read)
                bar.update(len(read))
        except KeyboardInterrupt:
            print(f"Removing incomplete download {path}")
            os.remove(path)
    if name.endswith(".zip"):
        print("Found a .zip archive. Extracting")
        name = name[:-4]
        shutil.unpack_archive(path, f"raw_data/{name}/", format="zip")
        os.remove(path)
