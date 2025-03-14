#!/usr/bin/env python3
import pandas as pd
from plotly.subplots import make_subplots
import plotly.graph_objects as go
import plotly.express as px
import json
from sklearn.linear_model import LinearRegression


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


# Returns the extrapolated temperature increase by 2050
def extrapolate_temperatures(df):
    model = LinearRegression()
    df["ordinal"] = df.index.map(pd.Timestamp.toordinal)
    x = df[["ordinal"]]
    y = df["Temperature"]

    # Train the model
    model.fit(x, y)

    model.score(x, y)
    baseline = (
        model.intercept_ + model.coef_[0] * pd.Timestamp("1900-01-01T12").toordinal()
    )
    temp_in_2050 = (
        model.intercept_ + model.coef_[0] * pd.Timestamp("2050-01-01T12").toordinal()
    )
    return temp_in_2050 - baseline


print("Reading datasets from disk.")


def run_analysis():
    temperatures = read_temperatures()
    temperatures = temperatures.reset_index()
    glacier_mass_changes = read_glacier_mass_changes()
    print("Preparing data for visualization.")
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
    monthly_temp_plot = px.scatter(
        temperatures.reset_index().rename(
            columns={"Date": "Year", "Temperature": "Temperature (C°)"}
        ),
        x="Year",
        y="Temperature (C°)",
        color="Statistic",
        trendline="lowess",
        title="Monthly Temperatures",
    )
    monthly_temp_plot.update_traces(visible="legendonly")
    monthly_temp_plot.data[-2].visible = True
    monthly_temp_plot.data[-1].visible = True
    monthly_temp_plot.update_layout(
        legend=dict(orientation="h", y=1, yanchor="bottom", xanchor="left", x=0)
    )
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
        title="Yearly Temperatures",
    )
    yearly_temp_plot.update_traces(visible="legendonly")
    yearly_temp_plot.update_layout(
        legend=dict(orientation="h", y=1, yanchor="bottom", xanchor="left", x=0)
    )
    yearly_temp_plot.data[-2].visible = True
    yearly_temp_plot.data[-1].visible = True

    glacier_mass_temp_change_combined = make_subplots(specs=[[{"secondary_y": True}]])
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
    glacier_mass_temp_change_combined.update_layout(
        legend=dict(orientation="h", y=1, yanchor="bottom", xanchor="left", x=0),
        title_text="Glacier Mass Lost and Yearly Temperatures Overlay",
    )
    glacier_mass_temp_change_combined.update_yaxes(
        title_text="Glacier Mass Lost",
        secondary_y=False,
    )
    glacier_mass_temp_change_combined.update_yaxes(
        title_text="Temperature (C°)", secondary_y=True
    )

    print("Rendering HTML.")

    def write_to_file(data, name: str):
        with open(f"backend/content/{name}", "w", encoding="utf-8") as output_file:
            output_file.write(data)

    graphs = {
        "glacier_mass_temp_change_combined_plot": glacier_mass_temp_change_combined,
        "yearly_temp_plot": yearly_temp_plot,
        "monthly_temp_plot": monthly_temp_plot,
    }

    # render plots
    graphs = {name: json.loads(data.to_json()) for (name, data) in graphs.items()}

    # extrapolate monthly tempearatures
    temp_increase_by_2050 = extrapolate_temperatures(year_means)

    # check for large anomalous increase in temperature

    warning = ""

    if temp_increase_by_2050 > 1.5:
        warning = f"The predicted temperature increase by 2050 is very high! {temp_increase_by_2050:.3}°C."
    write_to_file(
        warning,
        "template_data/temp_warning.txt",
    )

    write_to_file(
        json.dumps(graphs),
        "static/graphs_combined.json",
    )

    # Record correlation coefficient
    write_to_file(
        f"{corr_temp_diff_to_mass * 100:.4}%",
        "template_data/color_temp_diff_to_mass.txt",
    )

    print("Exported plots to the backend/content/ directory")


if __name__ == "__main__":
    run_analysis()
