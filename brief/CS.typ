#import "templates/common.typ": *
#show: doc(
    header: [_Computer Science Project_],
    // theme: "tokyonight",
    heading_numbering: "1.1.",
    attributed: [TODO: Exam number here],
    // theme: "light",
    // auto_outline: true,
)
= Investigation
I've always been interested in ecology, and especially climate change.
This led to me looking for various datasets related to the global temperatures and metrics related to global warming,
such as $upright("CO")_2$ emission amounts, global average temperatures, weather station reports accross ireland,
global sea levels and methane emissions.

Eventually I realized that there's a lot of high-quality data being tracked about glaciers by the #link("https://wgms.ch/")[World Glacier Monitoring Service].
It is a pretty common belief that glaciers are melting, and that it's caused by global warming, so I decided to try to show that.

I was inspired by effective visualizations such as #link("https://climate.nasa.gov/vital-signs/global-temperature")[this one by nasa],
but I wanted to make one that is more local to Ireland and is based on official temperature data from the government.

This prompted me to discover the #link("https://data.gov.ie/dataset/mtm02-temperature")[Ireland Air Temperature 1958-2022] dataset.
Ireland's oceanic climate made me consider that its temperature may correlate fairly closely to the rate at which glaciers are melting.

= Plan & Design
Immediately, I separated the project into distinct stages:
+ Downloading the data sets.
+ Cleaning the data sets.
+ Running the analysis on the clean data.
+ Database.
+ Backend to handle serving the results of the data analysis to the client and communication with the database.
+ Frontend to query the backend for data.

I decided to use the hugely popular #link("https://pandas.pydata.org/")[`pandas`] Python library to conduct the data analysis.
For downloading the datasets I chose #link("https://pypi.org/project/urllib3/")[`urllib3`], as I was already familiar with it.
For reporting the progress of downloads to the user I used #link("https://tqdm.github.io/")[`tqdm`].
For the visualization I went with #link("https://plotly.com/python/")[`plotly`], as it has fairly good integration with JS.

Having used SQL-based relational DBMSs, I went with #link("https://www.postgresql.org/")[PostgreSQL] as it is easy to set up in a 
#link("https://www.docker.com/")[Docker container].

For the backend itself I knew I wanted to use #link("https://www.rust-lang.org/")[The Rust Programming Language], as I enjoy its reliability, scalability
and structured concurrency.
To connect the backend to the database I chose #link("https://github.com/launchbadge/sqlx")[`SQLx`], as it provides compile-time checked SQL queries and has a great developer experience.

= Create
This brief was written and typeset using #link("https://github.com/typst/typst")[typst].
I also used the `git` Version Control System and the GitHub platform to host #link("https://github.com/CordlessCoder/CSCoursework2025/")[the source code for this project].

== Data Downloader
I decided the downloader will download files into the `raw_data` directory, to be consumed by the Data Cleaner.
Implementing the basic data downloader was fairly simple, as most of the heavy lifting was done by `urllib3`.

I then added support for automatically extracting .zip archives, progress reporting with `tqdm` and Ctrl+C handling during downloads.

== Data Cleaner
I started by reading the datasets from the files downloaded gby the Data Downloader.

I then dropped the columns I don't need and made sure all columns have descriptive names.

I then saved the now clean data into new CSV files into the `clean_data`.

== Data Analyzer
I started by reading the new clean data from `clean_data`, and doing the operations to prepare it for visualizations in-memory.

I negated the glacier mass change($m_Delta$)
statistics and summing them for each year to calculate the total glacier mass loss for each year.

I also averaged the monthly temperatures over each year to get a new dataframe with yearly temperatures,
that can be directly compared to the glacier loss statistics.

I initially rendered the plots to HTML in Plotly.py, but I then realized that will limit the reactivity of the plots when displayed.
So I then moved over to exporting the Plotly graph objects to JSON and rendering them entirely in the front-end using Plotly.JS.

I also calculated the correlation coefficient between the average temperature in Ireland for a year, and the glacier mass lost in that year.

== Database
I started by putting together a basic PostgreSQL docker container.

I then wrote the SQL migration to create the `replies` table, which will store the responses to the form.

== Backend
I wrote a simple backend server using #link("https://github.com/tokio-rs/tokio")[`tokio`] and #link("https://github.com/tokio-rs/axum")[`axum`].

I added the endpoints `/reply` to add a new reply to the database, `/list_replies?latest=N` to get the information about the latest responses
and `/stats` to gather statistics about all responses in the database.

I also added a WebSocket endpoint at `/ws_notifications` that handles the real-time viewer count as well as notifying users about new responses.

I then added a service to route any other accesses to files in the `backend/content/static` directory, to serve the `.js` scripts, `.css` stylesheets and 
the exported visualizations as `.json`.

I then wrote a `Dockerfile` to automatically build and package the backend into a Docker image, and connected it to the database using `docker-compose.yaml`.

== Frontend
I started with a simple `flexbox` based layout, and immediately wrote a `<header>` for all the pages, which includes navigation.
I built a simple data page with `<div>`s that I draw charts into via Plotly.js.
I then added commentary onto the page that recommends the user how to interpret the data.

Then I built a "survey" page with an HTML form that communicates with the backend via JavaScript.
I gave it the fields `name` of type `text`, `age` of type `number` and `agree` of type `boolean`.

I then added plotly to this survey page to draw statistics based on the responses to the form.
These statistics are:
- A pie chart of what part of the responses answered _Yes_ to the `agree` field.
- A histogram of the ages of the people responding.

I also made a `<footer>` with the copyright and a link to the source code of the project at GitHub. 

I then wrote a theme switching script(`theme.js`) to enable light and dark theme.

== Deployment
The webpage is deployed at #link("https://roman.vm.net.ua")[roman.vm.net.ua] hosted in a VPS by Hetzner.

#pagebreak()
== Progress Log
#import "@preview/gantty:0.1.0": gantt
#gantt(yaml("gantt.yaml"))

= Evaluation
The brief suggested using publicly available datasets from the Irish government and other worldwide data repositories,
which I did with the #link("https://doi.org/10.5904/wgms-fog-2024-01")[Met Éireann] and #link("https://doi.org/10.5904/wgms-fog-2024-01")[WGMS] datasets.

Using my `download_data.py` script I extracted the data from a `.zip` archive into `raw_data`, then in my `clean_data.py` script I cleaned
the data using `pandas`.

= Datasets
- WGMS (2024):
    Fluctuations of Glaciers Database.
    World Glacier Monitoring Service (WGMS), Zurich, Switzerland.

    https://doi.org/10.5904/wgms-fog-2024-01

    Dataset download link: https://wgms.ch/downloads/DOI-WGMS-FoG-2024-01.zip

- Met Éireann (2021): 
    MTM02 - Temperature 
    Dr Sam Belton, Dr Grzegorz Głaczyński, Dublin, Ireland.

    https://data.gov.ie/dataset/mtm02-temperature

    Dataset download link: https://ws.cso.ie/public/api.restful/PxStat.Data.Cube_API.ReadDataset/MTM02/CSV/1.0/en
    
