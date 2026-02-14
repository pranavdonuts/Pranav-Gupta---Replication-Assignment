set more off
version 12
#delim cr
pause on

set linesize 180
capture log close
set logtype text
log using ../log/state-codes.log, replace

/* --------------------------------------

This program creates a data set with many
different types of state codes.

--------------------------------------- */

clear all
set mem 10m

************************************************************
** Create State Codes, FIPS & Names                       **
************************************************************

input state_fips str2 state_abbrev str40 state_name 
01   AL		"Alabama"
02   AK		"Alaska"
04   AZ		"Arizona"
05   AR		"Arkansas"
06   CA		"California"
08   CO		"Colorado"
09   CT		"Connecticut"
10   DE		"Delaware"
11   DC		"District of Columbia"
12   FL		"Florida"
13   GA		"Georgia"
15   HI		"Hawaii"
16   ID		"Idaho"
17   IL		"Illinois"
18   IN		"Indiana"
19   IA		"Iowa"
20   KS		"Kansas"
21   KY		"Kentucky"
22   LA		"Louisiana"
23   ME		"Maine"
24   MD		"Maryland"
25   MA		"Massachusetts"
26   MI		"Michigan"
27   MN		"Minnesota"
28   MS		"Mississippi"
29   MO		"Missouri"
30   MT		"Montana"
31   NE		"Nebraska"
32   NV		"Nevada"
33   NH		"New Hampshire"
34   NJ		"New Jersey"
35   NM		"New Mexico"
36   NY		"New York"
37   NC		"North Carolina"
38   ND		"North Dakota"
39   OH		"Ohio"
40   OK		"Oklahoma"
41   OR		"Oregon"
42   PA		"Pennsylvania"
44   RI		"Rhode Island"
45   SC		"South Carolina"
46   SD		"South Dakota"
47   TN		"Tennessee"
48   TX		"Texas"
49   UT		"Utah"
50   VT		"Vermont"
51   VA		"Virginia"
53   WA		"Washington"
54   WV		"West Virginia"
55   WI		"Wisconsin"
56   WY		"Wyoming"
60   AS		"American Samoa"
64   FM		"Federated States of Micronesia"
66   GU		"Guam"
68   MH		"Marshall Islands"
72   PR		"Puerto Rico"
78   VI		"Virgin Islands"
end

list

************************************************************
**   Add AHA Codes, II
************************************************************

** This comes directly from the 1984 AHA codebook:
**** 
****       REGION  1                   REGION  4                REGION  8            
****     (NEW ENGLAND)            (EAST NORTH CENTRAL)          (MOUNTAIN)           
****  -------------------      --------------------------    ----------------        
****                                                                                 
****   11 MAINE                 41 OHIO                       81 MONTANA             
****   12 NEW HAMPSHIRE         42 INDIANA                    82 IDAHO               
****   13 VERMONT               43 ILLINOIS                   83 WYOMING             
****   14 MASSACHUSETTS         44 MICHIGAN                   84 COLORADO            
****   15 RHODE ISLAND          45 WISCONSIN                  85 NEW MEXICO          
****   16 CONNECTICUT                                         86 ARIZONA             
****                                                          87 UTAH                
****                                                          88 NEVADA              
****                                                                                 
****                                                                                 
****                                                                                 
****       REGION  2                   REGION  5                REGION  9            
****     (MID ATLANTIC)           (EAST SOUTH CENTRAL)          (PACIFIC)            
****  --------------------     --------------------------    ---------------         
****                                                                                 
****   21 NEW YORK              51 KENTUCKY                   91 WASHINGTON          
****   22 NEW JERSEY            52 TENNESSEE                  92 OREGON              
****   23 PENNSYLVANIA          53 ALABAMA                    93 CALIFORNIA          
****                            54 MISSISSIPPI                94 ALASKA              
****                                                          95 HAWAII              
****                                                                                 
****                                                                                 
****                                                                                 
****        REGION  3                  REGION  6                    REGION  0        
****     (SOUTH ATLANTIC)         (WEST NORTH CENTRAL)          (ASSOCIATED AREAS)   
****  ----------------------   --------------------------    ------------------------
****                                                                                 
****   31 DELAWARE              61 MINNESOTA                  03 MARSHALL ISLANDS    
****   32 MARYLAND              62 IOWA                       04 PUERTO RICO         
****   33 DIST. OF COLUMBIA     63 MISSOURI                   05 VIRGIN ISLANDS      
****   34 VIRGINIA              64 NORTH DAKOTA               06 GUAM                
****   35 WEST VIRGINIA         65 SOUTH DAKOTA               07 AMERICAN SAMOA      
****   36 NORTH CAROLINA        66 NEBRASKA                                          
****   37 SOUTH CAROLINA        67 KANSAS                                            
****   38 GEORGIA                                                                    
****   39 FLORIDA                                                                    
****                                                                                 
****                                                                                 
****                                   REGION  7                                     
****                              (WEST SOUTH CENTRAL)                               
****                           --------------------------                            
****                                                                                 
****                            71 ARKANSAS                                          
****                            72 LOUISIANA                                         
****                            73 OKLAHOMA                                          
****                            74 TEXAS                                             

preserve
	clear

	input state_aha str20 state_name 
	03 "Marshall Islands"
	04 "Puerto Rico"
	05 "Virgin Islands"
	06 "Guam"
	07 "American Samoa"
	08 "Saipan"
	11 "Maine"
	12 "New Hampshire"
	13 "Vermont"
	14 "Massachusetts"
	15 "Rhode Island"
	16 "Connecticut"
	21 "New York"
	22 "New Jersey"
	23 "Pennsylvania"
	31 "Delaware"
	32 "Maryland"
	33 "District of Columbia"
	34 "Virginia"
	35 "West Virginia"
	36 "North Carolina"
	37 "South Carolina"
	38 "Georgia"
	39 "Florida"
	41 "Ohio"
	42 "Indiana"
	43 "Illinois"
	44 "Michigan"
	45 "Wisconsin"
	51 "Kentucky"
	52 "Tennessee"
	53 "Alabama"
	54 "Mississippi"
	61 "Minnesota"
	62 "Iowa"
	63 "Missouri"
	64 "North Dakota"
	65 "South Dakota"
	66 "Nebraska"
	67 "Kansas"
	71 "Arkansas"
	72 "Louisiana"
	73 "Oklahoma"
	74 "Texas"
	81 "Montana"
	82 "Idaho"
	83 "Wyoming"
	84 "Colorado"
	85 "New Mexico"
	86 "Arizona"
	87 "Utah"
	88 "Nevada"
	91 "Washington"
	92 "Oregon"
	93 "California"
	94 "Alaska"
	95 "Hawaii"
	end

	tempfile aha
	sort state_name
	save `aha'
restore
                       
sort state_name
merge 1:1 state_name using `aha' 
tab _merge
list if _merge != 3
drop _merge
                       
************************************************************
** Add Census State Codes                                 **
************************************************************

** This code comes from the 1960 census, as cataloged
** in CPS NBER codebooks.

preserve
	clear

	input state_census str20 state_name 
	11 "Maine"
	12 "New Hampshire"
	13 "Vermont"
	14 "Massachusetts"
	15 "Rhode Island"
	16 "Connecticut"
	21 "New York"
	22 "New Jersey"
	23 "Pennsylvania"
	31 "Ohio"
	32 "Indiana"
	33 "Illinois"
	34 "Michigan"
	35 "Wisconsin"
	41 "Minnesota"
	42 "Iowa"
	43 "Missouri"
	44 "North Dakota"
	45 "South Dakota"
	46 "Nebraska"
	47 "Kansas"
	51 "Delaware"
	52 "Maryland"
	53 "District of Columbia"
	54 "Virginia"
	55 "West Virginia"
	56 "North Carolina"
	57 "South Carolina"
	58 "Georgia"
	59 "Florida"
	61 "Kentucky"
	62 "Tennessee"
	63 "Alabama"
	64 "Mississippi"
	71 "Arkansas"
	72 "Louisiana"
	73 "Oklahoma"
	74 "Texas"
	81 "Montana"
	82 "Idaho"
	83 "Wyoming"
	84 "Colorado"
	85 "New Mexico"
	86 "Arizona"
	87 "Utah"
	88 "Nevada"
	91 "Washington"
	92 "Oregon"
	93 "California"
	94 "Alaska"
	95 "Hawaii"
	end

	sort state_name
	tempfile census
	save "`census'"
restore

sort state_name
merge state_name using "`census'" , uniqusing uniqmaster
tab _merge
list if _merge!=3
*keep if _merge==3
drop _merge

************************************************************
** ICP State Code                                         **
************************************************************

preserve
	clear
	input str20 state_name state_icp
	"Connecticut" 01
	"Maine" 02
	"Massachusetts" 03
	"New Hampshire" 04
	"Rhode Island" 05
	"Vermont" 06
	"Delaware" 11
	"New Jersey" 12
	"New York" 13
	"Pennsylvania" 14
	"Illinois" 21
	"Indiana" 22
	"Michigan" 23
	"Ohio" 24
	"Wisconsin" 25
	"Iowa" 31
	"Kansas" 32
	"Minnesota" 33
	"Missouri" 34
	"Nebraska" 35
	"North Dakota" 36
	"South Dakota" 37
	"Virginia" 40
	"Alabama" 41
	"Arkansas" 42
	"Florida" 43
	"Georgia" 44
	"Louisiana" 45
	"Mississippi" 46
	"North Carolina" 47
	"South Carolina" 48
	"Texas" 49
	"Kentucky" 51
	"Maryland" 52
	"Oklahoma" 53
	"Tennessee" 54
	"West Virginia" 56
	"Arizona" 61
	"Colorado" 62
	"Idaho" 63
	"Montana" 64
	"Nevada" 65
	"New Mexico" 66
	"Utah" 67
	"Wyoming" 68
	"California" 71
	"Oregon" 72
	"Washington" 73
	"Alaska" 81
	"Hawaii" 82
	"Puerto Rico" 83
	"District of Columbia" 98
	end
	tempfile icp
	sort state_name
	save "`icp'"
restore

sort state_name
merge state_name using "`icp'" , uniqusing uniqmaster
tab _merge
list if _merge!=3
drop _merge

************************************************************
** Save & Close                                           **
************************************************************

sort state_fips
d, f
compress
label data "Every Possible State Code"
save ../dta/state-codes.dta, replace

log close
exit

