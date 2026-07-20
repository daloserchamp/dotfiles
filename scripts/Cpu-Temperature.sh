#!/bin/bash
main=$(sensors | grep "Package id 0:" | tr -d '+' | awk '{print $4}' | tr -d -c '[0-9]+.')
echo "${main}°C"
