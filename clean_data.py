#!/usr/bin/env python3
import pandas as pd


def print_markdown(df):
    print(r"```")
    print(df.reset_index().describe())
    print(r"```")
    print("\n---")


def read_temperatures():
    with open("raw_data/MTM02_Temperature.csv", "r") as file:
        df = pd.read_csv(
            file,
            index_col=["Month", "Statistic Label"],
            parse_dates=["Month"],
            date_format="%YM%m",
        )
        print("## Before cleaning")
        print_markdown(df)
        df.index.names = ["Date", "Statistic"]
        df.drop(
            [
                "TLIST(M1)",
                "C02431V02938",
                "UNIT",
                "STATISTIC",
                "Meteorological Weather Station",
            ],
            axis=1,
            inplace=True,
        )
        df.rename(columns={"VALUE": "Temperature"}, inplace=True)
        df = (
            df[df["Temperature"].notna()]
            .groupby(["Date", "Statistic"])
            .Temperature.mean()
        )
        print("# After cleaning")
        print_markdown(df)
        return df


def read_glacier_mass_changes():
    with open("raw_data/DOI-WGMS-FoG-2024-01/data/mass_balance.csv", "r") as file:
        df = pd.read_csv(
            file,
            index_col=["YEAR"],
            parse_dates=["YEAR"],
            date_format="%Y",
        )
        print("## Before cleaning")
        print_markdown(df)
        df = df.groupby("YEAR").ANNUAL_BALANCE.sum()
        df.index.names = ["Date"]
        df.name = "Change"
        # Drop empty data for 2024
        df = df.iloc[:-1]
        print("## After cleaning")
        print_markdown(df)
        return df


def run_clean():
    glacier_mass_changes = read_glacier_mass_changes()
    glacier_mass_changes.to_csv(
        "clean_data/glacier_mass_changes.csv", date_format="%Y %m"
    )

    temperatures = read_temperatures()
    temperatures.to_csv("clean_data/temperatures.csv", date_format="%Y %m")


if __name__ == "__main__":
    run_clean()
