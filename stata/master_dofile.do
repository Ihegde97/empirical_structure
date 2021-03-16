/*********************
 The Stata do-file that calls all other do files to run
  all code from start to finish.
  
  Ishwara Hegde
  CEMFI
  
  
  This version: 7th-March-2021
 ********************/

clear all                // Get rid of anything stored in memory

version 14.1             // Store the version of Stata for forward
                         // compatibility                       
set maxvar 30000

**** Set user and the directory *******
// Comment out Ishwara and use Other user. 
// Replace "Enter your directory here" with your directory


local users  "Ishwara" // "Other" 

// Please point your dir variable to the Ishwara_Hegde directory on your computer

  if "`users'" == "Other" {
  global dir "Enter your directory here" 
}

  if "`users'" == "Ishwara" {
    global dir "C:/Users/user/Desktop/Replication-Template/Ishwara_Hegde"
  }

/* ======================================================================
   Now, we call each do-file in the project in sequence to create
   the project from start to finish.
   1. Perform Data Preparation
   2. Perform Analysis 
======================================================================  */  
log using "$dir/output/hegde.log", replace 

do "$dir/stata/data_preparation.do"          /* Prepare the data for analysis */


do "$dir/stata/analysis.do"     /* Estimate regressions and export the
                                           results to a formatted table */


log close 

