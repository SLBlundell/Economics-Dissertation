clear all
capture log close
log using "section_3-2.log", replace

cd "C:\Users\whisk\OneDrive\Documents\Bristol\Economics\Year 4\AED\AED GitHub\University-of-Bristol---AED"

import delimited "./data/spec_1.csv"

// Data Cleaning //

replace stringencyindex_weightedaverage = 0 if missing(stringencyindex_weightedaverage) 

sort date
drop if stringencyindex_weightedaverage==0
gen time=_n

// Generating Regression Variables //

egen r_m_mean = mean(r_m)
gen r_m_sqr= (r_m-r_m_mean)^2
gen r_m_abs=abs(r_m)
replace stringencyindex_weightedaverage=stringencyindex_weightedaverage/100

tempvar PL75
egen `PL75' = pctile(stringencyindex_weightedaverage), p(75)
gen D25Upper = 0
label var D25Upper "S upper 25%"
replace D25Upper = 1 if stringencyindex_weightedaverage >= `PL75'

tempvar PL90
egen `PL90' = pctile(stringencyindex_weightedaverage), p(90)
gen D10Upper = 0
label var D10Upper "S upper 10%"
replace D10Upper = 1 if stringencyindex_weightedaverage >= `PL90'

tempvar PL95
egen `PL95' = pctile(stringencyindex_weightedaverage), p(95)
gen D5Upper = 0
label var D5Upper "S upper 5%"
replace D5Upper = 1 if stringencyindex_weightedaverage >= `PL95'

gen days = 0
label var days "Days"
replace days = days[_n-1] + 1 if c6e_stayathomerequirements == 3
replace days = 0 if c6e_stayathomerequirements < 3

// Labelling Variables //

la var r_m "Market Return"
la var stringencyindex_weightedaverage "Stringency Index"
la var c6e_stayathomerequirements "C6: Shelter in Place Indicator"
la var populationvaccinated "Vaccination Rate"
la var rolling_deaths "COVID-19 Deaths 7-Day Rolling Average"
la var cases "COVID-19 Daily Cases"
la var r_m_sqr "Market Return Squared"
la var r_m_abs "Absolute Market Return"

tsset time

outsheet csad cssd r_m r_m_abs r_m_sqr stringencyindex_weightedaverage c6e_stayathomerequirements D25Upper D10Upper D5Upper days populationvaccinated rolling_deaths cases using ./data/spec_1_stata.csv , comma replace

// Summary Stats //

estpost tabstat csad cssd r_m r_m_sqr stringencyindex_weightedaverage c6e_stayathomerequirements days populationvaccinated rolling_deaths, c(stat) stat(sum mean sd min max n)
esttab using ".\TeX_files\SummaryTable.tex", replace cells("sum(fmt(%6.0fc)) mean(fmt(%6.3fc)) sd(fmt(%6.3fc)) min(fmt(%6.3fc)) max(fmt(%6.3fc)) count") nonumber nomtitle nonote noobs label booktabs collabels("Sum" "Mean" "SD" "Min" "Max" "N")

// Statistical tests //

pac csad
ac csad
hist csad

quietly reg csad r_m_abs r_m_sqr stringencyindex_weightedaverage populationvaccinated rolling_deaths
estat bgodfrey, lags(1 2:20)
dfuller csad
swilk csad

// Regressions //

eststo: newey csad r_m_abs r_m_sqr, lag(5)
eststo: newey csad r_m_abs r_m_sqr stringencyindex_weightedaverage populationvaccinated rolling_deaths, lag(5)
eststo: newey csad r_m_abs r_m_sqr c.r_m_sqr#D25Upper populationvaccinated rolling_deaths, lag(5)
eststo: newey csad r_m_abs r_m_sqr c.r_m_sqr#D10Upper populationvaccinated rolling_deaths, lag(5)
eststo: newey csad r_m_abs r_m_sqr c.r_m_sqr#D5Upper populationvaccinated rolling_deaths, lag(5)
eststo: newey csad r_m_abs r_m_sqr c6e_stayathomerequirements days populationvaccinated rolling_deaths, lag(5)


esttab, b(5) se(5) nomtitle label star(* 0.10 ** 0.05 *** 0.01)
esttab using "./TeX_files/Regressions_1.tex", replace b(5) se(5) nomtitle label star(* 0.10 ** 0.05 *** 0.01) booktabs title("Regression Results \label{reg1}") addnotes("First line" "Second line")
est clear

// Robustness Checks //

pca c6e_stayathomerequirements c2e_workplaceclosing c3e_cancelpublicevents c4e_restrictionsongatherings c5e_closepublictransport c7e_restrictionsoninternalmoveme c8e_internationaltravelcontrols, components(3)
predict pc1 pc2 pc3, score

eststo: newey csad r_m_abs r_m_sqr pc1 pc2 pc3 populationvaccinated rolling_deaths, lag(5)

esttab, b(5) se(5) nomtitle label star(* 0.10 ** 0.05 *** 0.01)
esttab using "./TeX_files/Regressions_2.tex", replace b(5) se(5) nomtitle label star(* 0.10 ** 0.05 *** 0.01) booktabs title("PC Regression \label{reg2}") addnotes("First line" "Second line")
est clear

eststo: newey cssd r_m_abs r_m_sqr, lag(5)
eststo: newey cssd r_m_abs r_m_sqr stringencyindex_weightedaverage populationvaccinated rolling_deaths, lag(5)
eststo: newey cssd r_m_abs r_m_sqr c.r_m_sqr#D25Upper populationvaccinated rolling_deaths, lag(5)
eststo: newey cssd r_m_abs r_m_sqr c.r_m_sqr#D10Upper populationvaccinated rolling_deaths, lag(5)
eststo: newey cssd r_m_abs r_m_sqr c.r_m_sqr#D5Upper populationvaccinated rolling_deaths, lag(5)
eststo: newey cssd r_m_abs r_m_sqr c6e_stayathomerequirements days populationvaccinated rolling_deaths, lag(5)

esttab, b(5) se(5) nomtitle label star(* 0.10 ** 0.05 *** 0.01)
esttab using "./TeX_files/Regressions_2.tex", replace b(5) se(5) nomtitle label star(* 0.10 ** 0.05 *** 0.01) booktabs title("Robustness Results \label{reg2}") addnotes("First line" "Second line")
est clear

log close