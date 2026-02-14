#delim cr
set more off
pause on
graph set ps logo off

capture log close
set linesize 80
set logtype text
log using ../log/create-google-figures.log , replace

/* --------------------------------------

This program creates figures based on the google
search data.

--------------------------------------- */

clear all
estimates clear
set mem 500m



************************************************************
**   Program used below
************************************************************

capture program drop convert_week_to_date
program define convert_week_to_date
	tab week
	gen startyear = real( regexs(1) ) if regexm(week, "([0-9]+)-([0-9]+)-([0-9]+) - ([0-9]+)-([0-9]+)-([0-9]+)")
	gen startmonth = real( regexs(2) ) if regexm(week, "([0-9]+)-([0-9]+)-([0-9]+) - ([0-9]+)-([0-9]+)-([0-9]+)")
	gen startday = real( regexs(3) ) if regexm(week, "([0-9]+)-([0-9]+)-([0-9]+) - ([0-9]+)-([0-9]+)-([0-9]+)")
	gen endyear = real( regexs(4) ) if regexm(week, "([0-9]+)-([0-9]+)-([0-9]+) - ([0-9]+)-([0-9]+)-([0-9]+)")
	gen endmonth = real( regexs(5) ) if regexm(week, "([0-9]+)-([0-9]+)-([0-9]+) - ([0-9]+)-([0-9]+)-([0-9]+)")
	gen endday = real( regexs(6) ) if regexm(week, "([0-9]+)-([0-9]+)-([0-9]+) - ([0-9]+)-([0-9]+)-([0-9]+)")

	gen startdate = mdy(startmonth , startday, startyear)
	format startdate %td
	gen enddate = mdy(endmonth , endday, endyear)
	format enddate %td
	list week startdate enddate
	drop startyear startmonth startday endyear endmonth endday
end

capture program drop destring_ifstring
program define destring_ifstring
    local type: type `1'
    if substr("`type'",1,3) == "str" { 
	    rename `1' `1'_orig
	    gen `1' = real(`1'_orig)
	    drop `1'_orig
	    disp "`1' destringed"
    }
    if substr("`type'",1,3) == "str" {
	    disp "`1' not a string"
    }
end


************************************************************
**   Bring in Tennessee data, "job openings"
************************************************************

** I'm having a problem creating the Tennessee time series,
** because of bugs in the Google Trends web server.

clear
input year month searchload
2004 01	52
2004 02	66
2004 03	47
2004 04	47
2004 05	77
2004 06	87
2004 07	64
2004 08	68
2004 09	80
2004 10	54
2004 11	47
2004 12	56
2005 01	69
2005 02	37
2005 03	33
2005 04	69
2005 05	52
2005 06	39
2005 07	88
2005 08	100
2005 09	59
2005 10	48
2005 11	49
2005 12	42
2006 01	60
2006 02	42
2006 03	63
2006 04	61
2006 05	72
2006 06	69
2006 07	74
2006 08	69
2006 09	45
2006 10	65
2006 11	55
2006 12	33
2007 01	38
end

gen byte tn = 1

gen ym = ym(year, month)
drop year month
format ym %tm

tempfile tn_nums
save `tn_nums'

************************************************************
**   Bring in other data, "job openings"
************************************************************

foreach file in alabama arkansas dc delaware florida georgia kentucky louisiana maryland mississippi northcarolina oklahoma southcarolina texas virginia westvirginia {

	insheet using ../src/google-trends/job-openings-`file'.csv , comma names clear
	gen str20 state = "`file'"

	destring_ifstring jobopening


	tempfile t_`file'
	save `t_`file''
}

clear
foreach file in alabama arkansas dc delaware florida georgia kentucky louisiana maryland mississippi northcarolina oklahoma southcarolina texas virginia westvirginia {
	append using `t_`file''
}

tab state
d, f

convert_week_to_date

rename jobopening searchload
drop if searchload == 0

** Normalize to month
gen ym = ym( year(startdate) , month(startdate) )
format ym %tm
tab ym
collapse (mean) searchload , by(ym) fast

** Add in Tennessee
gen byte tn = 0
append using `tn_nums'

local tenncare_cuts = ym(2005,7)

keep if ym >= ym(2004, 1) & ym <= ym(2006,12)

** Normalize series by the 2004/1 value
list if ym == ym(2004, 1)
sort tn ym
by tn: gen searchload_norm = searchload / searchload[1]
list tn ym searchload_norm searchload , sepby(tn)

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway ///
	(connected searchload_norm ym if tn == 1, lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o)) ///
	(connected searchload_norm ym if tn == 0, lpattern(solid) lcolor(gray) mcolor(red) msymbol(s)) ///
	, ///
	ylabel(, nogrid angle(horizontal)  ) ///
	scheme(s2mono)  ///
	aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white))  ///
	legend(off) ///
	xline(`tenncare_cuts') ///
	xlabel(528 "2004" 540 "2005" 552 "2006" 564 "2007") ///
	yscale( nofextend ) xscale(nofextend) ///
	xtitle(" ") ytitle(" ")
graph save ../gph/jobopening-tnvsouth-monthly.gph , replace

************************************************************
**   Create a graph for just Tennessee, "TennCare"
************************************************************

** Web Search Interest: tenncare
** Tennessee (United States); 2004 - present
** Interest over time

** 1) November 2004.  This is from the TennCare timeline:   November 10, 2004
** - Acknowledging that the proposed reform effort of September 2004 could not
** proceed without significant modification of the Consent Decrees, Governor
** Bredesen announced that he was setting in motion a process to end TennCare and
** return to Medicaid.
** 2) July 2005 – When the disenrollments begin.

insheet using ../src/google-trends/tenncare-tn.csv , comma names clear
d, f

convert_week_to_date

sum tenncare
gen searchload = real(tenncare)
list searchload tenncare in 1/10

** Zeroes are missing
drop if searchload == 0

** Normalize to month
gen ym = ym( year(startdate) , month(startdate) )
format ym %tm
tab ym
collapse (mean) searchload , by(ym) fast


local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

keep if ym >= ym(2004, 1) & ym <= ym(2006,12)

local tenncare_cuts = ym(2005,7)
local tenncare_announcement = ym(2004,11)

** Normalize based on first value
isid ym
sort ym
gen searchload_norm = searchload / searchload[1]

graph set window fontface "Garamond" 
twoway ///
	(connected searchload_norm ym , lpattern(solid) lcolor(gray) mcolor(blue) msymbol(o)) ///
	, ///
	ylabel(, nogrid angle(horizontal)  ) ///
	scheme(s2mono)  ///
	aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white))  ///
	legend(off) ///
	xline(`tenncare_cuts') ///
	xline(`tenncare_announcement') ///
	xlabel(528 "2004" 540 "2005" 552 "2006" ) ///
	yscale( nofextend ) xscale(nofextend) ///
	xtitle(" ") ytitle(" ")
graph save ../gph/tenncare-tn-monthly.gph , replace


log close
exit

