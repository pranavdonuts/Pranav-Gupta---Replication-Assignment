#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 200
set logtype text

* Ensuring the log folder exists and using relative paths
log using "../log/create-brfss-data-1990-2008.log" , replace

/* --------------------------------------
This program compiles the BRFSS data 
from the raw files using relative paths.
--------------------------------------- */

clear all
estimates clear

************************************************************
** Updated programs to move around using relative paths
************************************************************

capture program drop move_to_bulk
program define move_to_bulk
    * Navigate specifically to the brfss subfolder inside src
    cd "../src/brfss"
end

capture program drop move_back 
program define move_back 
    * Return to the do folder
    cd "../../do"
end

************************************************************
** Clean raw files
************************************************************

forvalues year = 1990(1)2008 {

    clear
    
    * Navigate to where the .dct and raw data files are
    move_to_bulk
    
    * Check if the file exists before running to avoid errors
    capture confirm file "brfss`year'.dct"
    if _rc == 0 {
        infile using brfss`year'.dct
        move_back
        
        compress
        * Save to your local dta folder
        capture mkdir "../dta/brfss"
        save "../dta/brfss/brfss_data_`year'", replace
    }
    else {
        display as error "Warning: brfss`year'.dct not found in src folder. Skipping..."
        move_back
    }
}

log close
exit
