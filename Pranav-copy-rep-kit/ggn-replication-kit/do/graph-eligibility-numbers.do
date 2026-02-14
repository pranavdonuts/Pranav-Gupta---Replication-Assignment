#delim cr
set more off
version 12
pause on
graph set ps logo off

capture log close
set linesize 80
set logtype text
log using ../log/graph-eligibility-numbers.log , replace

/* --------------------------------------

This program graphs the long-term trend in
eligibility for TennCare.

--------------------------------------- */

clear all
estimates clear
set mem 50m


************************************************************
**   Graph long-term annual data, FP
************************************************************

input year overall_tenncare_enrollment	traditional_medicaid_enrollment uninsured_uninsurable_enrollment
1996	1180449	846067	334382
1997	1188570	842334	346236
1998	1266373	840113	426260
1999	1312969	814181	498788
2000	1297932	782265	515667
2001	1426622	819374	607248
2002	1412910	818925	593985
2003	1273732	1014192	259540
2004	1338187	1075872	262315
2005	1349591	1126358 223233 
2006	1183721	1144910 38811
2007	1186768	1151753	35015
2008	1221283	1187742	33541
2009	1236154	1204648	31506
end
list

format overall_tenncare_enrollment traditional_medicaid_enrollment uninsured_uninsurable_enrollment  %15.0gc
local golden_ratio = ( sqrt(5) + 1 ) / 2
local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
disp "Golden ratio is `golden_ratio'"
disp "Inverse golden ratio is `inv_golden_ratio'"

graph set window fontface "Garamond"
twoway ///
	(connected overall_tenncare_enrollment year , lpattern(solid) lcolor(gray) mcolor(red) msymbol(d)) ///
	(connected traditional_medicaid_enrollment year , lpattern(dash) lcolor(gray) mcolor(blue) msymbol(s)) ///
	(connected uninsured_uninsurable_enrollment year , lpattern(solid) lcolor(gray) mcolor(red) msymbol(o)) ///
	, ///
	ylabel(, nogrid angle(horizontal)  ) ///
	scheme(s2mono)  ///
	aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white))  ///
	legend(off) ///
	yscale( nofextend ) xscale(nofextend) ///
	xlabel(1996(3)2009)  ///
	xtitle(" ") ytitle(" ")
graph save ../gph/long-term-eligibility.gph , replace

************************************************************
**   Graph quarterly data, FP
************************************************************

clear

input str20 date total_medicaid x uninsured_n_uninsurable
"10/15/2002"    1439772 869004   570768 
"1/15/2003"     1311942 942973  368969
"4/15/2003"     1339259 974053  365206
"7/15/2003"     1273732 1014192 259540
"10/15/2003"    1299235 1037340 261895
"1/15/2004"     1310450 1048880 261570
"4/15/2004"     1345206 1083304 261902
"7/15/2004"     1338187 1075872 262315
"10/15/2004"    1340824 1079975 260849
"1/15/2005"     1336691  1094015        242676
"4/15/2005"     1335457 1104932 230525
"7/15/2005"     1349591  1126358         223233 
"10/15/2005"    1261751  1185109         76642 
"1/15/2006"     1205526  1154953        50573
"4/15/2006"     1184937  1146458        38479
"7/15/2006"     1183721  1144910        38811
"10/15/2006"    1183052 1142400 40652
"1/15/2007"     1171947 1136586 35361
"4/15/2007"     1204852 1170056 34796
"7/15/2007"     1186768 1151753 35015
"10/15/2007"    1223213 1188429 34784
"1/15/2008"     1137756 1101949 35807
"4/15/2008"     1233223 1198884 34339
"7/15/2008"     1221283 1187742 33541
"10/15/2008"    1185348 1151916 33432
"1/15/2009"     1205214 1172226 32988
"4/15/2009"     1232561 1200588 31973
"7/15/2009"     1236154 1204648 31506
"10/15/2009"    1174904 1142868 32036
end

gen statadate = date(date, "MDY")
format statadate %td

codebook statadate

** Convert date to quarter
gen yq = qofd(statadate)
format yq %tq
tab yq
list

format total_medicaid %-12.0gc

label variable total_medicaid "Total Medicaid Enrollment"

format uninsured_n_uninsurable %-12.0gc

label variable uninsured_n_uninsurable "Uninsured and Uninsurable"

replace uninsured_n_uninsurable = uninsured_n_uninsurable / 1000

replace total_medicaid = total_medicaid / 1000

local tenncarecuts = mdy(8,1,2005)
local tenncarecuts_q = yq(2005,3)

list

drop if year(statadate) < 2003

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

graph set window fontface "Garamond"

local x2003 = yq(2003,1)
local x2004 = yq(2004,1)
local x2005 = yq(2005,1)
local x2006 = yq(2006,1)
local x2007 = yq(2007,1)
local x2008 = yq(2008,1)
local x2009 = yq(2009,1)
local x2010 = yq(2010,1)




tw ///
	(scatter total_medicaid yq , sort connect(l) symbol(o) lcolor(gray) mcolor(blue) yaxis(1) ) ///
	(scatter uninsured_n_uninsurable yq , sort connect(l) symbol(s) lcolor(gray) mcolor(red) yaxis(2) ) ///
	, ///
	scheme(s2mono) graphregion(fcolor(white)) ///
	legend(region(style(none)) rows(2) ) ///
	legend(off) ///
	ylabel(, nogrid angle(horizontal) axis(1) )  ///
	ylabel(, nogrid angle(horizontal) axis(2) )  ///
	yscale(range(1000 1400) axis(1)) ///
	aspectratio(`inv_golden_ratio') ///
	yscale(range(0 400) axis(2)) ///
	ylabel(1000(50)1400 , axis(1) ) ///
	ylabel(0(50)400 , axis(2) ) ///
	xtitle(" ") ///
	xline(`tenncarecuts_q') ///
	xlabel(`x2003' "2003" `x2004' "2004" `x2005' "2005" `x2006' "2006" `x2007' "2007" `x2008' "2008" `x2009' "2009" `x2010' "2010") ///
	ytitle(" ", orientation(horizontal) axis(1) ) ///
	ytitle(" ", orientation(horizontal) axis(2) ) ///
	yscale( nofextend ) xscale(nofextend) ///
	title(" ")
graph save ../gph/enrollment-trends.gph , replace

log close
exit

