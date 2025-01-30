#!/usr/bin/env python3
import pandas as pd


def read_temperatures():
    with open("raw_data/MTM02_Temperature.csv", "r") as file:
        df = pd.read_csv(
            file,
            index_col=["Month", "Statistic Label"],
            parse_dates=["Month"],
            date_format="%YM%M",
        )
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
        return (
            df[df["VALUE"].notna()].groupby(["Month", "Statistic Label"]).VALUE.mean()
        )


def read_glacier_mass_changes():
    with open("raw_data/DOI-WGMS-FoG-2024-01/data/mass_balance.csv", "r") as file:
        df = (
            pd.read_csv(
                file,
                index_col=["YEAR"],
                parse_dates=["YEAR"],
                date_format="%Y",
            )
            .groupby("YEAR")
            .ANNUAL_BALANCE.mean()
        )
        return df


glacier_mass_changes = read_glacier_mass_changes()
glacier_mass_changes.to_csv("clean_data/glacier_mass_changes.csv")

temperatures = read_temperatures()
temperatures.to_csv("clean_data/temperatures.csv")
