clear all
capture log close
log using "section_2.log", replace

cd "C:\Users\whisk\OneDrive\Documents\Bristol\Economics\Year 4\AED\Small Group Sessions\Section 2\Data"

import delimited "spec_1_stringency_CSSD_CSAD_(2020_inc)"

sort date
gen time=_n

replace stringency = 0 if missing(stringency) 


gen r_m_sqr=r_m^2

tsset time
newey cssd r_m r_m_sqr stringency, lag(7)