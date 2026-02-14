#!/bin/bash

## This script runs our bootstrap procedure in the background. 
## This way, we create multiple parallel jobs, which each recreate
## a table.

nohup nice statamp -b run-cps-main-tables.do 1 &
nohup nice statamp -b run-cps-main-tables.do 2 &
nohup nice statamp -b run-cps-main-tables.do 3 &
nohup nice statamp -b run-cps-main-tables.do 4 &

exit

nohup nice statamp -b run-cps-main-tables.do 5 &
nohup nice statamp -b run-cps-main-tables.do 6 &
nohup nice statamp -b run-cps-main-tables.do 7 &
nohup nice statamp -b run-cps-main-tables.do 8 &
nohup nice statamp -b run-cps-main-tables.do 9 &
nohup nice statamp -b run-cps-main-tables.do 10 &
nohup nice statamp -b run-cps-main-tables.do 11 &
nohup nice statamp -b run-cps-main-tables.do 12 &
nohup nice statamp -b run-cps-main-tables.do 13 &
nohup nice statamp -b run-cps-main-tables.do 14 &
nohup nice statamp -b run-cps-main-tables.do 15 &
nohup nice statamp -b run-cps-main-tables.do 16 &
nohup nice statamp -b run-cps-main-tables.do 17 &
nohup nice statamp -b run-cps-main-tables.do 18 &
