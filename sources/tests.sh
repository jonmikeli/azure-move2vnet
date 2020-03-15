#!/bin/bash
rKind="functionapp;linux"

if [[ $rKind == *"app"* ]];
then
    echo "yes"
else
    echo "non"
fi
