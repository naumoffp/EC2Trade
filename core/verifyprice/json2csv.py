#!/usr/local/bin/python3
# Solution from https://stackoverflow.com/questions/41180960/convert-nested-json-to-csv-file-in-python
# TODO - make this https://stackoverflow.com/questions/36752050/converting-nested-json-to-csv-in-go

from copy import deepcopy
import pandas
import json
import os


def cross_join(left, right):
    new_rows = [] if right else left
    for left_row in left:
        for right_row in right:
            temp_row = deepcopy(left_row)
            for key, value in right_row.items():
                temp_row[key] = value
            new_rows.append(deepcopy(temp_row))
    return new_rows


def flatten_list(data):
    for elem in data:
        if isinstance(elem, list):
            yield from flatten_list(elem)
        else:
            yield elem


def json_to_dataframe(data_in):
    def flatten_json(data, prev_heading=''):
        if isinstance(data, dict):
            rows = [{}]
            for key, value in data.items():
                rows = cross_join(rows, flatten_json(value, prev_heading + "." + key))
        elif isinstance(data, list):
            rows = []
            for item in data:
                [rows.append(elem) for elem in flatten_list(flatten_json(item, prev_heading))]
        else:
            rows = [{prev_heading[1:]: data}]
        return rows

    return pandas.DataFrame(flatten_json(data_in))


if __name__ == "__main__":
    json_data = None
    infile = os.getcwd() + "/core/verifyprice/data/spot-price-history"

    # For testing locally
    # infile = os.getcwd() + "/data/spot-price-history"

    with open(infile + ".json") as f:
        json_data = json.load(f)

    df = json_to_dataframe(json_data)
    df.sort_values(by=["SpotPriceHistory.SpotPrice", "SpotPriceHistory.InstanceType", "SpotPriceHistory.AvailabilityZone"], ascending=[True, False, False], inplace=True)

    # Temporary fix for table being too wide
    df = df.drop(["SpotPriceHistory.ProductDescription", "SpotPriceHistory.Timestamp"], axis=1)
    print(df)

    df.to_csv(infile + ".csv", encoding="utf-8", index=False)
