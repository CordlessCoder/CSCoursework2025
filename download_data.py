#!/usr/bin/env python3
from urllib3 import PoolManager, HTTPHeaderDict
from typing import Optional
from bs4 import BeautifulSoup
import urllib
import re
import os
from tqdm import tqdm

pool = PoolManager()


def get_content_length(headers: HTTPHeaderDict) -> Optional[int]:
    length = headers.get("Content-Length", None)
    if length is None:
        return None

    try:
        return int(length)
    except ValueError:
        return None


indirect_sources = [
    "https://cli.fusio.net/cli/grids_daily/max/",
    "https://cli.fusio.net/cli/grids_daily/min/",
]
direct_sources = ["https://wgms.ch/downloads/DOI-WGMS-FoG-2024-01.zip"]


__link_is_absolute_regex__ = re.compile("^https?://")


def link_is_absolute(link: str) -> bool:
    return __link_is_absolute_regex__.match(link) is not None


for source in indirect_sources:
    with pool.request("GET", source, preload_content=False) as conn:
        soup = BeautifulSoup(conn, features="html.parser")
        relative_links = (
            a.get("href")
            for a in soup.find_all(
                "a", attrs={"href": lambda link: not link_is_absolute(link)}
            )
        )
        direct_sources.extend(
            urllib.parse.urljoin(source, link) for link in relative_links
        )
        absolute_links = (
            a.get("href") for a in soup.find_all("a", attrs={"href": link_is_absolute})
        )
        direct_sources.extend(absolute_links)


if not os.path.isdir("raw_data"):
    print("Cannot find the `raw_data` directory to download files into.")
    print("Please create it, or navigate to the proper directory.")
    exit(1)

for source in direct_sources:
    path = "raw_data/" + source.split("/")[-1]
    if os.path.exists(path):
        print(f"{path} is already downloaded, skipping")
        continue
    with (
        pool.request("GET", source, preload_content=False) as conn,
        open(path, "xb") as out,
        tqdm(
            total=get_content_length(conn.headers),
            desc=source,
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
