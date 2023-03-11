clear all
capture log close
log using "section_2.log", replace

cd "C:\Users\whisk\OneDrive\Documents\Bristol\Economics\Year 4\AED\Small Group Sessions\Section 2\Data"

import delimited "spec_1_stringency_CSSD_CSAD_updated_csi"

sort date
gen time=_n
drop if time==1

replace stringency = 0 if missing(stringency) 

tempvar PL75
egen `PL75' = pctile(stringency), p(75)
gen D25Upper = 0
label var D25Upper "Dummy variable = 1 if stringency fall within upper 25%"
replace D25Upper = 1 if stringency >= `PL75'

tempvar PL90
egen `PL90' = pctile(stringency), p(90)
gen D10Upper = 0
label var D10Upper "Dummy variable = 1 if stringency fall within upper 10%"
replace D10Upper = 1 if stringency >= `PL90'

tempvar PL95
egen `PL95' = pctile(stringency), p(95)
gen D5Upper = 0
label var D5Upper "Dummy variable = 1 if stringency fall within upper 5%"
replace D5Upper = 1 if stringency >= `PL95'

gen r_m_sqr=r_m^2

tsset time

estpost sum r_m - r_m_sqr

quietly reg cssd r_m r_m_sqr stringency
estat bgodfrey, lags(1 2:30)

dfuller cssd

newey cssd r_m r_m_sqr stringency, lag(5)

newey cssd r_m c.r_m_sqr##D25Upper, lag(5)
newey cssd r_m c.r_m_sqr##D10Upper, lag(5)
newey cssd r_m c.r_m_sqr##D5Upper, lag(5)

newey csad r_m r_m_sqr stringency, lag(5)

newey csad r_m c.r_m_sqr##D25Upper, lag(5)
newey csad r_m c.r_m_sqr##D10Upper, lag(5)
newey csad r_m c.r_m_sqr##D5Upper, lag(5)

log close