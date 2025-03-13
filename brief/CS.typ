#import "templates/common.typ": *
#import "@preview/wordometer:0.1.4": word-count-of
#show: doc(
    header: [_Computer Science Project_],
    theme: "light",
    heading_numbering: "1.1.",
    attributed: [TODO: Exam number here],
    // theme: "light",
    // auto_outline: true,
)
#set par(justify: true)
#let linkimage(url, image_url, name) = link(url, box([#name #box(image(image_url), height: 1em)]))
= Meeting the brief
#let meeting_brief = [
]
#meeting_brief

= Investigation
#let investigation = [
I've always been interested in ecology, and especially climate change.
This led to me looking for various datasets related to the global temperatures and metrics related to global warming,
such as $upright("CO")_2$ emission amounts, global average temperatures, weather station reports across Ireland,
global sea levels and methane emissions.

I decided that I'd like to find a correlation between the temperature increase and one of its indirect effects.

I was inspired by effective visualizations such as #link("https://climate.nasa.gov/vital-signs/global-temperature")[the global temperature graph by NASA],
but I wanted to make one that is more local to Ireland and is based on official temperature data from Met Éireann.

I started by looking for interesting datasets on #link("https://kaggle.com")[Kaggle.com] and #link("https://worlddata.info")[WorldData.info], but I
didn't find a dataset on temperature in Ireland that I was confident in, so I decided to search #link("https://data.gov.ie/dataset/")[data.gov.ie].

This prompted me to discover the #link("https://data.gov.ie/dataset/mtm02-temperature")[Ireland Air Temperature 1958-2022] dataset.
Ireland's oceanic climate made me consider that its temperature may correlate fairly closely to the rate at which glaciers are melting.

Eventually I realized that there's a lot of high-quality data being tracked about glaciers by the #link("https://wgms.ch/")[World Glacier Monitoring Service].
It is a pretty common belief that glaciers are melting, and that it's caused by global warming, so I decided to try to show that.


]
#investigation

= Plan & Design
#let plan_and_design = [
Immediately, I separated the project into distinct stages:
+ Downloading the data sets.
+ Cleaning the data sets.
+ Running the analysis on the clean data.
+ Database.
+ Backend to handle serving the results of the data analysis to the client and communication with the database.
+ Frontend to query the backend for data.

I decided to use the hugely popular #linkimage("https://pandas.pydata.org/", "./assets/pandas.svg")[`pandas`] Python library to conduct the data analysis.
For downloading the datasets I chose #linkimage("https://pypi.org/project/urllib3/", "./assets/urllib3.svg")[`urllib3`], as I was already familiar with it.
For reporting the progress of downloads to the user I used #linkimage("https://tqdm.github.io/", "./assets/tqdm.gif")[`tqdm`].
For the visualization I went with #link("https://plotly.com/python/")[`plotly`], as it has fairly good integration with JS.

Having used SQL-based relational DBMS's before, I went with #linkimage("https://www.postgresql.org/", "./assets/PostgreSQL.svg")[PostgreSQL] as it is easy to set up in a 
#linkimage("https://www.docker.com/", "./assets/docker-mark-blue.svg")[Docker container].

For the backend itself I knew I wanted to use #linkimage("https://www.rust-lang.org/", "./assets/Rust.svg")[The Rust Programming Language], as I enjoy its reliability, scalability
and structured concurrency.
To connect the backend to the database I chose #link("https://github.com/launchbadge/sqlx")[`SQLx`], as it provides compile-time checked SQL queries and has a great developer experience.

#import "@preview/fletcher:0.5.6" as fletcher: diagram, node, edge
#import fletcher.shapes: diamond

#diagram(
	node-stroke: 1pt,
    node(
        align(bottom, [Data analysis pipeline]),
        enclose: (
            (0,0),
            (1,0),
            (2,0),
        ),
        inset: 4pt,
        stroke: teal,
        fill: teal.lighten(80%),
    ),
	node((0,0), [Data Downloader], corner-radius: 2pt),
	edge("-|>", label: "Raw data"),
	node((1,0), [Data Cleaner], corner-radius: 2pt),
	edge("-|>", label: "Clean data"),
	node((2,0), [Data Analysis], corner-radius: 2pt),
	edge((0, 0), (0, 1.4), "-|>", label: "Visualizations"),
	node((0,1.4), [Storage], corner-radius: 2pt, extrude: (0, -2pt)),
	node((1,1.4), [Database], corner-radius: 2pt, extrude: (0, -2pt)),
	edge("<|-|>", [Form responses], label-side: left),
	edge((0, 1.4), (0.5, 2.5), "-|>", [Static content, visualizations], label-side: right),
	node((0.5,2.5), [Backend], corner-radius: 2pt),
	edge("-|>", [Webpage]),
	node((0.5,3.5), [Frontend], corner-radius: 2pt),
)
]
#plan_and_design

= Create
#let create = [
This brief was written and typeset using #link("https://github.com/typst/typst")[typst].
I also used the `git` Version Control System and the GitHub platform to host #link("https://github.com/CordlessCoder/CSCoursework2025/")[the source code for this project].

== Data Downloader
I decided the downloader will download files into the `raw_data` directory, to be consumed by the Data Cleaner.
Implementing the basic data downloader was fairly simple, as most of the heavy lifting was done by `urllib3`.

I then added support for automatically extracting .zip archives, progress reporting with `tqdm` and support for cancelling downloads with Ctrl+C.

A problem I ran into here was that `tqdm` does not natively support progress reporting for a download, so I needed to implement that myself.
I did that by manually reading the file in small chunks(4096 bytes) and updating the progress bar with the amounts read in a loop.

#[
#set par(justify: false)
#tbx(columns: 2, align: start, 
    [Test (Python)],[Expected behavior],
    [```python get_content_length()```],[Size of the file.],
    [```python conn.read(4096)```],[Next chunk of the file.],
    [```python shutil.unpack_archive(path, f"raw_data/{name}/", format="zip")```],[Downloaded archive unpacked.],
    [```python run_download()```],[Datasets downloaded to `raw_data`.],
)
]



== Data Cleaner
I started by reading the datasets from the files downloaded by the Data Downloader.

I then dropped the columns I don't need and made sure all columns have descriptive names.

I then saved the now clean data into new CSV files into the `clean_data`.

#[
#set par(justify: false)
#tbx(columns: 2, align: start, 
    [Test (Python)],[Expected behavior],
    [```python read_temperatures()```],[`raw_data/MTM02_Temperature.csv` read and unused columns dropped.],
    [```python read_glacier_mass_changes()```],[`raw_data/DOI-WGMS-FoG-2024-01/data/mass_balance.csv` read and unused columns dropped.],
    [```python df.rename(columns={"VALUE": "Temperature"}, inplace=True)```],[`VALUE` column renamed to `TEMPERATURE`.],
    [```python run_clean()```],[Datasets read from `raw_data`, cleaned and saved to `clean_data`.],
)
]

== Data Analyzer
I started by reading the new clean data from `clean_data`, and doing the operations to prepare it for visualizations in-memory.

I negated the glacier mass change($m_Delta$)
statistics and summing them for each year to calculate the total glacier mass loss for each year.

I also averaged the monthly temperatures over each year to get a new dataframe with yearly temperatures,
that can be directly compared to the glacier loss statistics.

I initially rendered the plots to HTML in Plotly.py, but I then realized that will limit the reactivity of the plots when displayed.
So I then moved over to exporting the Plotly graph objects to JSON and rendering them entirely in the front-end using Plotly.JS.

I also calculated the correlation coefficient between the average temperature in Ireland for a year, and the glacier mass lost in that year.

A problem I ran into while implementing the analysis is that the glacier records are annual while the temperature data contains monthly entries.
I solved this by averaging the records for the temperature over each year, bulding a new dataframe.

#[
#set par(justify: false)
#tbx(columns: 2, align: start, 
    [Test (Python)],[Expected behavior],
    [```python read_temperatures() ```],[`clean_data/temperatures.csv` read into a DataFrame.],
    [```python read_glacier_mass_changes() ```],[`clean_data/glacier_mass_changes.csv` read into a DataFrame.],
    [```python write_to_file(json.dumps(graphs), "static/graphs_combined.json")```],[Rendered plotly graphs exported into `graphs_combined.json`.],
)
]

== Database
I started by putting together a basic PostgreSQL docker container.

I then wrote the SQL migration to create the `replies` table, which will store the responses to the form.

#[
#set par(justify: false)
#tbx(columns: 2, align: start, 
    [Test (SQL query)],[Expected behavior],
    [```sql SELECT * FROM replies ORDER BY id DESC LIMIT N ```],[Returns `N` last replies.],
    [```sql SELECT count(*) AS total, count(*) FILTER (WHERE agree) AS agreed FROM replies ```],[Returns the total number of replies with agree set to true,
    and the grand total number of replies.],
    [```sql INSERT INTO replies (age, agree, name) VALUES ($1, $2, $3) ```],[Inserts a new reply into the database.],
)
]

== Backend
I wrote a simple backend server using #linkimage("https://github.com/tokio-rs/tokio", "./assets/Tokio.svg")[`tokio`] and #link("https://github.com/tokio-rs/axum")[`axum`].

I added the endpoint ```http POST /reply``` to add a new reply to the database, ```http GET /list_replies?latest=N ``` to get the information about the latest responses
and ```http GET /stats ``` to gather statistics about all responses in the database.

I also added a #link("https://developer.mozilla.org/en-US/docs/Web/API/WebSocket")[WebSocket] endpoint at `/ws_notifications`
that handles the real-time viewer count as well as notifying users about new responses.

I then added a service to route any other accesses to files in the `backend/content/static` directory, to serve the `.js` scripts, `.css` stylesheets and 
the exported visualizations as `.json`.

I then wrote a `Dockerfile` to automatically build and package the backend into a Docker image, and connected it to the database using `docker-compose.yaml`.

#[
#set par(justify: false)
#tbx(columns: 2, align: start, 
    [Test (HTTP Request)],[Expected behavior],
    [```http GET /replies?latest=N HTTP/1.1 ```],[Returns `N` last replies as JSON.],
    [```http POST /reply?name={NAME}&age={AGE}&agree={AGREE} HTTP/1.1 ```],[Adds a new response to the database.],
    [```http GET /ws_notifications HTTP/1.1 ```],[Establishes a WebSocket connection for the client to recieve notifications over.],
)
]

== Frontend
I started with a simple `flexbox` based layout, and immediately wrote a `<header>` for all the pages, which includes navigation.
I built a simple data page with `<div>`s that I draw charts into via Plotly.js.
I then added commentary onto the page that recommends the user how to interpret the data.

Then I built a "survey" page with an HTML form that communicates with the backend via JavaScript.
I gave it the fields `name` of type `text`, `age` of type `number` and `agree` of type `boolean`.

#columns(2)[
#box(image("./assets/survey_plot_vertical.png"), stroke: none)

#colbreak()

I then added plotly to this survey page to draw statistics based on the responses to the form.
These statistics are:
- A pie chart of what part of the responses answered _Yes_ to the `agree` field.
- A histogram of the ages of the people responding.
]


I also made a `<footer>` with the copyright and a link to the source code of the project at GitHub. 

I then wrote a theme switching script(`theme.js`) to enable light and dark theme.

That theme switching script in particular was quite difficult to get right because I wanted to animate the transition,
but when I added the ```css * {
    --color-transition: 250ms;
    transition: background-color var(--color-transition) 100ms, color var(--color-transition), filter var(--color-transition) 100ms;
}```
CSS rule, this caused the page to animate from light theme to dark theme when loading, if dark theme was set.
This is because when the page first loaded, it defaulted to light theme as my `theme.js` script has not loaded the `theme` value from localStorage yet.

Once it did, and the ```css [theme="dark"]``` CSS query became true, the transition ran as if the user switched the theme. 
The way I solved this is by removing the transition from the CSS and instead moving it to my theme.js script, where it injects the CSS for the animation
when the `Toggle theme` button is pressed (using ```js document.styleSheets[0].insertRule()``` ).

#[
#set par(justify: false)
#tbx(columns: 2, align: start, 
    [Test (Interaction)],[Expected behavior],
    [Pressing the `Toggle theme` button],[Toggles between light/dark theme with a smooth transition.],
    [Hovering over a button in the navbar],[The button anymates up slightly.],
    [Hovering over any of the plots],[The plot shows more in-depth information about the data point hovered over.],
)
]

== Deployment
The webpage is deployed at #link("https://roman.vm.net.ua")[roman.vm.net.ua] hosted in a VPS by Hetzner.

The backend and database are bundled together into a docker compose service.

TLS, which is needed for HTTPS is handled by the reverse proxy: #linkimage("https://caddyserver.com/", "./assets/Caddy.png")[Caddy].
Caddy also handles compression with gzip and zlib.

Logging in the backend is handled by the #linkimage("https://github.com/tokio-rs/tracing", "./assets/tracing.svg")[tracing] Rust library,
configured to output to `stderr`.

== Progress Log
#import "@preview/gantty:0.1.0": gantt
#gantt(yaml("gantt.yaml"))
]
#create

= Evaluation
#let evaluation = [
The brief suggested using publicly available datasets from the Irish government and other worldwide data repositories,
which I did with the #link("https://doi.org/10.5904/wgms-fog-2024-01")[Met Éireann] and #link("https://doi.org/10.5904/wgms-fog-2024-01")[WGMS] datasets.

Using my `download_data.py` script I extracted the data from a `.zip` archive into `raw_data`, then in my `clean_data.py` script I cleaned
the data using `pandas`.

Using my `clean_data.py` script I cleaned the downloaded data by removing columns I don't need, renaming columns to be more consistent
and making sure the two datasets I'm using are coherent(share the same range of dates).

These two fulfill the requirement for collectiong and preparing the data.

Using my `analyze.py` script I created line plots and bar charts, as well as an overlaid bar+line plot to show the correlation between
the temperature in Ireland and glacier melting rate.

The line chart shows how the temperature has increased on average over $1 degree upright(C)$ since 1958.
The bar chart shows the rate at which glaciers are melting.

I also calculated the correlation ratio between the two, which is quite high($56.78%$).

Each of the plots is clearly labelled with titles, axis labels and legends.
When representing the plots interally, I used dictionaries and lists.

These visualizations are fully rendered on the client-side via Plotly.js, so they are entirely interactive.

My backend enables persistent storage of the responses to the form, as well as running statistics over that data.
The data collected is stored in a PostgreSQL database, and validated by the backend before being inserted into the DB.


The Data page of my information system provides additional context to aid in interpreting the visualizations.
]
#evaluation



= References
#let references = [
== Datasets
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
]
#references
#pagebreak()
= Word counts
#tbx(columns: 2,
    [Section],[Word Count],
    [Meeting the brief],word-count-of(meeting_brief).words,
    [Investigation],word-count-of(investigation).words,
    [Plan and design],word-count-of(plan_and_design).words,
    [Create],word-count-of(create).words,
    [Evaluation],word-count-of(evaluation).words,
    [Total],(
        word-count-of(meeting_brief).words
            + word-count-of(investigation).words
            + word-count-of(plan_and_design).words
            + word-count-of(create).words
            + word-count-of(evaluation).words
    )
)
