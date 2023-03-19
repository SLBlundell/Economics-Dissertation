clear all
capture log close
log using "section_3-2.log", replace

cd "C:\Users\whisk\OneDrive\Documents\Bristol\Economics\Year 4\AED\AED GitHub\University-of-Bristol---AED"

import delimited "./data/spec_1.csv"

replace stringencyindex_weightedaverage = 0 if missing(stringencyindex_weightedaverage) 

gen r_m_sqr=r_m^2
gen r_m_abs=abs(r_m)
replace stringencyindex_weightedaverage=stringencyindex_weightedaverage/100

la var r_m "Market Return"
la var stringencyindex_weightedaverage "Stringency Index"
la var c6e_stayathomerequirements "C6: Shelter in Place Indicator"
la var populationvaccinated "Vaccination Rate"
la var rolling_deaths "COVID-19 Deaths 7-Day Rolling Average"
la var cases "COVID-19 Daily Cases"
la var r_m_sqr "Market Return Squared"
la var r_m_abs "Absolute Market Return"

tempvar PL75
egen `PL75' = pctile(stringencyindex_weightedaverage), p(75)
gen D25Upper = 0
label var D25Upper "Dummy variable = 1 if stringency fall within upper 25%"
replace D25Upper = 1 if stringencyindex_weightedaverage >= `PL75'

tempvar PL90
egen `PL90' = pctile(stringencyindex_weightedaverage), p(90)
gen D10Upper = 0
label var D10Upper "Dummy variable = 1 if stringency fall within upper 10%"
replace D10Upper = 1 if stringencyindex_weightedaverage >= `PL90'

tempvar PL95
egen `PL95' = pctile(stringencyindex_weightedaverage), p(95)
gen D5Upper = 0
label var D5Upper "Dummy variable = 1 if stringency fall within upper 5%"
replace D5Upper = 1 if stringencyindex_weightedaverage >= `PL95'

sort date
gen time=_n
drop if time==1

tsset time

// Summary Stats //

estpost tabstat csad cssd r_m stringencyindex_weightedaverage c6e_stayathomerequirements populationvaccinated rolling_deaths, c(stat) stat(sum mean sd min max n)
esttab using ".\TeX_files\SummaryTable.tex", replace cells("sum(fmt(%6.0fc)) mean(fmt(%6.3fc)) sd(fmt(%6.3fc)) min(fmt(%6.3fc)) max(fmt(%6.3fc)) count") nonumber nomtitle nonote noobs label booktabs collabels("Sum" "Mean" "SD" "Min" "Max" "N")

// t-tests //

quietly reg csad r_m_abs r_m_sqr stringencyindex_weightedaverage populationvaccinated rolling_deaths
estat bgodfrey, lags(1 2:20)

dfuller csad

// Regressions //

newey cssd r_m_abs r_m_sqr stringencyindex_weightedaverage populationvaccinated rolling_deaths, lag(5)

newey cssd r_m_abs r_m_sqr c.r_m_sqr#D25Upper populationvaccinated rolling_deaths, lag(5)
newey cssd r_m_abs r_m_sqr c.r_m_sqr#D10Upper populationvaccinated rolling_deaths, lag(5)
newey cssd r_m_abs r_m_sqr c.r_m_sqr#D5Upper populationvaccinated rolling_deaths, lag(5)

newey csad r_m_abs r_m_sqr stringencyindex_weightedaverage populationvaccinated rolling_deaths, lag(5)

newey csad r_m_abs r_m_sqr c.r_m_sqr#D25Upper populationvaccinated rolling_deaths, lag(5)
newey csad r_m_abs r_m_sqr c.r_m_sqr#D10Upper populationvaccinated rolling_deaths, lag(5)
newey csad r_m_abs r_m_sqr c.r_m_sqr#D5Upper populationvaccinated rolling_deaths, lag(5)

newey csad r_m_abs r_m_sqr c6e_stayathomerequirements populationvaccinated rolling_deaths, lag(5)

log close