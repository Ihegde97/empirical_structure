***************************************************
*Project: EPoD Stata Test
*Purpose: Data Preparation
*Last modified: March 7th 2020 by Ishwara
***************************************************


***************************************************
*00. Preamble
***************************************************
set more off

***************************************************
*(a),(b) Basic loading and cleaning Endline data
***************************************************
use "$dir/data/endline.dta", clear /// Loading the data 

// I use a for loop to avoid repetition of code 
// First I replace "None" with "0" before converting 
// the strings to numeric variables
//I use the force option with destring to ensure that 
// replies such as "Refuse to answer" are coded as missing values
// This is a reasonable assumption since only 4 obs refuse to answer


local string_int "totformalborrow_24 totinformalborrow_24 hhinc"
	foreach s of local string_int  {
		replace `s'= cond(`s' == "None", "0", `s')
		replace `s'= cond(`s' == "Refuse to answer", "0", `s')
		destring `s',force replace
		
	}



***************************************************
*(c) Exploring the data 
***************************************************
preserve 

 xtile cat = hhinc, nq(10) // creates a categoric variable depending on the decile of hhinc 
 bysort cat: egen formal_mean=mean(totformalborrow_24) // generates a mean formal debt per decile 
 bysort cat: egen informal_mean=mean(totinformalborrow_24) // generates a mean informal debt per decile 
 twoway connected formal_mean informal_mean cat, ytitle(Mean debt (in Rupees)) /// 
 xtitle(Deciles of household income) title(Mean Debt by Income Deciles) /// 
 subtitle(A comparison of formal and informal debt) ///
  graphregion(color(white)) bgcolor(white)  // Creates a graph 

 graph export "$dir/output/borrow_vs_income.png", as(png) replace // Save the graph

// Now exploring the household income 

// I take logs of the income data since large outliers make most 
// visualizations difficult to read

gen lhhinc = log(hhinc) 
graph box lhhinc, ytitle(log of household income) /// 
title(Distribution of Household Income) /// 
subtitle(logs of household incomes used)over(survey_round) scheme(s2mono) ///
graphregion(color(white)) bgcolor(white)

 graph export "$dir/output/income_endline.png", as(png) replace // Save the graph

restore 


***************************************************
*(d),(e), (g) Top coding debt  & creating total borrowed
***************************************************
// top coding the three variables 
local string_int "totformalborrow_24 totinformalborrow_24 hhinc"
	foreach s of local string_int  {
	summ `s',det // using the summary table to extract means/ sd
	gen mean_`s' = r(mean)
	gen sd_`s'=r(sd)
	local out_high=mean_`s' + 3*sd_`s' // creating an outlier value
	// compaing to outlier value:
	gen tc_`s'=cond( `s' > `out_high', `out_high', `s' ) 
	cap drop mean_`s' sd_`s' // dropping temp vars 
	}

// I create a new var for topcoded values since it is not 
//clear to me if I should replace existing variables or
// create new ones.

// Adding variable labels 
label var tc_totformalborrow_24 "Total formal debt topcoded"
label var tc_totinformalborrow_24 "Total informal debt topcoded"
label var tc_hhinc "Total household topcoded"

// creating total borrowed

gen total_borrowed = totformalborrow_24+totinformalborrow_24


***************************************************
* (h)-(k) Merging data  & Poverty dummies 
***************************************************
// Save the cleaned data in the temp directory
save "$dir/temp/endline_temp.dta",replace 

// Import the treatment_status csv 
import delimited "$dir/data/treatment_status.csv", ///
    clear  ///                         
    varnames(1) /// uses first row as var names 




// Now I merge the treatment status dta into the endline dta 

merge 1:m group_id using "$dir/temp/endline_temp.dta"
drop _merge // notice all variables merged successfully

// Creating the poverty dummy 
gen poorhh = (tc_hhinc/hhnomembers) < (30*26.995) 

// Note: I use household income per capita i.e. 
// (Household Income / no. of people in the household)


// Merging with baseline 

*isid hhid // I check that hhid uniquely identifies households
merge 1:1 hhid using "$dir/data/baseline_controls.dta"
drop if _merge==1
drop _merge 
// I drop observations that are only in the endline survey
// More details can be found in the written report


save "$dir/temp/cleaned_and_merged.dta",replace 



