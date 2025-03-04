#!/usr/bin/env python3
import pandas as pd
from plotly.subplots import make_subplots
import plotly.graph_objects as go
import plotly.express as px
# from jinja2 import Template
# import streamlit as st


def read_temperatures():
    with open("clean_data/temperatures.csv", "r") as file:
        df = pd.read_csv(
            file,
            index_col=["Statistic", "Date"],
            parse_dates=["Date"],
            date_format="%Y %m",
        )
        return df


def read_glacier_mass_changes():
    with open("clean_data/glacier_mass_changes.csv", "r") as file:
        df = pd.read_csv(
            file,
            # index_col=["Date"],
            parse_dates=["Date"],
            date_format="%Y %m",
        ).sort_index()
        return df


print("Reading datasets from disk.")

temperatures = read_temperatures()
temperatures = temperatures.reset_index()
glacier_mass_changes = read_glacier_mass_changes()
print("Preparing data for visualization.")
mean_temps = (
    temperatures.groupby(
        [
            temperatures["Date"].dt.year,
            temperatures["Statistic"],
        ],
        as_index=False,
    )
    .mean()
    .set_index("Statistic")
    .loc["Mean Temperature"]
    .reset_index()
    .drop(columns="Statistic")
)
year_means = (
    temperatures.groupby(
        [
            temperatures["Date"].dt.year,
            temperatures["Statistic"],
        ],
        as_index=False,
    )
    .mean()
    .set_index("Statistic")
    .loc["Mean Temperature"]
    .reset_index()
    .drop(columns="Statistic")
    .set_index("Date")
    # .diff()[1:]
)
year_mass_change = (
    pd.merge(
        year_means.reset_index(),
        glacier_mass_changes.reset_index(),
        left_on=year_means.reset_index()["Date"].dt.year,
        right_on=glacier_mass_changes.reset_index()["Date"].dt.year,
    )
    .rename(columns={"key_0": "Year", "Change": "Mass lost"})[
        ["Year", "Temperature", "Mass lost"]
    ]
    .set_index("Year")
)
year_mass_change["Mass lost"] = year_mass_change["Mass lost"].apply(lambda x: -x)
corr_temp_diff_to_mass = year_mass_change["Temperature"].corr(
    year_mass_change["Mass lost"]
)


print("Building figures.")
# st.write("##### Cumulative glacier mass change")
# st.line_chart(
#     glacier_mass_changes.set_index("Date").cumsum(),
#     x_label="Year",
#     y_label="Total mass change",
# )
# st.write("##### Ireland Air Temperature")
monthly_temp_plot = px.scatter(
    temperatures.reset_index().rename(
        columns={"Date": "Year", "Temperature": "Temperature (C°)"}
    ),
    x="Year",
    y="Temperature (C°)",
    color="Statistic",
    trendline="lowess",
)
monthly_temp_plot.update_traces(visible="legendonly")
monthly_temp_plot.data[-2].visible = True
monthly_temp_plot.data[-1].visible = True
# st.plotly_chart(temp_plot, key=2)
# st.write("##### Ireland Air Temperature(annual averages)")
yearly_temp_plot = px.scatter(
    temperatures.groupby(
        [
            temperatures["Date"].dt.year,
            temperatures["Statistic"],
        ],
        as_index=False,
    )
    .mean()
    .rename(columns={"Date": "Year", "Temperature": "Temperature (C°)"}),
    x="Year",
    y="Temperature (C°)",
    color="Statistic",
    trendline="lowess",
)
yearly_temp_plot.update_traces(visible="legendonly")
yearly_temp_plot.data[-2].visible = True
yearly_temp_plot.data[-1].visible = True
# st.plotly_chart(yearly_temp_plot, key=1)

glacier_mass_temp_change_combined = make_subplots(
    # 2,
    # 1,
    # shared_xaxes=True,
    # shared_yaxes=True,
    # vertical_spacing=0.02,
    specs=[[{"secondary_y": True}]],
)
glacier_mass_temp_change_combined.add_trace(
    go.Bar(
        x=year_mass_change.index,
        y=year_mass_change["Mass lost"],
        name="Glacier Mass Lost (Metric tonnes)",
    ),
    secondary_y=False,
)
glacier_mass_temp_change_combined.add_trace(
    go.Scatter(
        x=year_mass_change.index,
        y=year_mass_change["Temperature"],
        name="Mean Annual Temperature (C°)",
    ),
    secondary_y=True,
)
glacier_mass_temp_change_combined.update_yaxes(
    title_text="Glacier Mass Lost",
    secondary_y=False,
)
glacier_mass_temp_change_combined.update_yaxes(
    title_text="Temperature (C°)", secondary_y=True
)
# st.plotly_chart(glacier_mass_temp_change_combined)


print("Rendering HTML.")


# def render_html(fig: go.Figure) -> str:
#     return fig.to_html(full_html=False, include_plotlyjs=False)
def export_json(fig: go.Figure) -> str:
    return fig.to_json()


def write_to_file(data, name: str):
    with open(f"backend/content/{name}", "w", encoding="utf-8") as output_file:
        output_file.write(data)


graphs = {
    "static/glacier_mass_temp_change_combined.json": glacier_mass_temp_change_combined,
    "static/yearly_temp_plot.json": yearly_temp_plot,
    "static/monthly_temp_plot.json": monthly_temp_plot,
}

# render plots
for name, fig in graphs.items():
    write_to_file(export_json(fig), name)


# Record correlation coefficient
write_to_file(
    f"Correlation coefficient between temperature and glacier mass lost: {corr_temp_diff_to_mass * 100:.4}%",
    "template_data/color_temp_diff_to_mass.txt",
)

print("Exported plots to the backend/content/ directory")

# jinja_data = {
#     "glacier_mass_temp_change_combined": render(glacier_mass_temp_change_combined),
#     "yearly_temp_plot": render(yearly_temp_plot),
#     "monthly_temp_plot": render(monthly_temp_plot),
# }
#
# with open("static/index.html", "w", encoding="utf-8") as output_file:
#     with open("templates/index.html") as template_file:
#         j2_template = Template(template_file.read())
#         output_file.write(j2_template.render(jinja_data))
