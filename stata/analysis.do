***************************************************
*Project: EPoD Stata Test
*Purpose: Analysis
*Last modified: March 7th 2020 by Ishwara
***************************************************


***************************************************
*00. Preamble
***************************************************
set more off 

use "$dir/temp/cleaned_and_merged.dta", clear /// Loading the data 

// I use the package balancetable. Alternatively 
// one could use outreg and a combination of regressing the variable of 
//interest on treatment variables.

ssc install balancetable // installing balancetable package 

***************************************************
*01. Balance Tests 
***************************************************
// Deifining a list of variables I want to check for balance:
global depvarlist hhnomembers gender_hoh  readwrite_hoh  /// 
hhnomembers_above18 hhnomembers_below18 hhreg_muslim hhreg_christian  ///
hhcaste_fc hhcaste_bc hhcaste_mbc hhcaste_sc_st 

// Using balancetable to create publication quality tables in Latex:
balancetable treated $depvarlist using "$dir/output/tab.tex", replace /// 
booktabs ctitles("Control" "Treatment" "Control vs Treatment") ///
            groups("Means" "Difference", pattern(1 0 1) /// 
            	end("\cmidrule(lr){2-3} \cmidrule(lr){4-4}")) ///
            vce(cluster pair_id)

***************************************************
*02.(c)-(e) Regressions 
***************************************************

reg hhinc treated i.pair_id, cluster( pair_id) // using uncensored income
reg tc_hhinc treated i.pair_id, cluster( pair_id) // using top coded income 

// Taking logs:
gen lhhinc=log(hhinc) 
gen ltc_hhinc=log(tc_hhinc)

// Regressing logs:
reg lhhinc treated i.pair_id, cluster( pair_id)
reg ltc_hhinc treated i.pair_id, cluster( pair_id)

reg lhhinc treated i.pair_id /// Regression with controls 
hhcaste_bc hhnomembers hhnomembers_below18 , cluster( pair_id)

// Creating a publication quality table:
ssc install outreg2 
outreg2 using ../output/Reg.tex, replace /// 
ctitle(Log household income) keep(lhhinc treated) addtext(FE, YES)

reg ltc_hhinc treated i.pair_id /// 
hhcaste_bc hhnomembers hhnomembers_below18 , cluster( pair_id)

outreg2 using ../output/Reg.tex, /// 
append ctitle(Topcoded Log household income) keep(lhhinc treated) addtext(FE, YES)


***************************************************
*02.Graphing 
***************************************************

preserve 
//First I reshape the data
keep treated total_borrowed hhinc hhid 
drop if treated==.
reshape wide hhinc total_borrowed , j(treated) i(hhid )


// creates a categoric variable depending on the quartile of hhinc: 
xtile cat0 = hhinc0, nq(4) //control group
xtile cat1 =hhinc1, nq(4) // treatment 
bysort 	cat0: egen borrowed_mean0=mean(total_borrowed0) // generates a mean debt per quartile 
bysort 	cat1: egen borrowed_mean1=mean(total_borrowed1) // generates a mean debt per quartile 

// Now that I have quantiles by treatment group
//I will recreate the dataset prior to reshape


gen treated = hhinc0==. // recreates treated indicator 

// Recreates borrowed_mean 
gen borrowed_mean=borrowed_mean0
replace borrowed_mean=cond( borrowed_mean== .,borrowed_mean1, borrowed_mean)

// recreates the cat variable 
gen cat=cat0
replace cat=cond( cat== .,cat1+4, cat0)

// Defines labels 
label define treatedl 0 "control" 1 "treatment" 
label values treated treatedl  

// Graph
graph bar borrowed_mean,  over(cat,gap(0)) over(treated, gap(*0)) asyvars ///
ytitle(Mean Amount Borrowed by Income Quartiles) ///
title(Mean Debt by Income Quartiles and Treatment Status) ///
graphregion(color(white)) bgcolor(white) /// Creates a graph 
legend(row(2)	order(1 "0-25" 2 "25-50" 3 "50-75" 4 "75-100" ///
	5 "0-25" 6 "25-50" 7 "50-75" 8 "75-100"))
 graph export "$dir/output/borrow_by_treat_quartiles.png", as(png) replace
  // Save the graph

restore 
