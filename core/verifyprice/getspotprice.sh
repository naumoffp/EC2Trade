#!/bin/bash

# Read in the parameters from the filter files
mapfile -t <$PWD/core/verifyprice/filters/instance-types.txt INSTANCETYPES
mapfile -t <$PWD/core/verifyprice/filters/product-descriptions.txt PRODUCTDESCRIPTIONS

DATE=$(date +%Y-%m-%d);

# Retrieve the price history based on the above filters
aws ec2 describe-spot-price-history \
    --instance-types ${INSTANCETYPES[@]} \
    --product-descriptions ${PRODUCTDESCRIPTIONS[@]} \
    --start-time ${DATE} \
    --output json | tee $PWD/core/verifyprice/data/spot-price-history.json

clear
