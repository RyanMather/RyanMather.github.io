//Get rdrobust, if you do not already have it
	cap which rdrobust
	if _rc!=0 {
		net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
	}
//Get rddensity, if you do not already have it
	cap which rddensity
	if _rc!=0 {
		net install rddensity, from(https://raw.githubusercontent.com/rdpackages/rddensity/master/stata) replace
	}
//Get lpdensity, if you do not already have it
	cap which lpdensity
	if _rc!=0 {
		net install lpdensity, from(https://raw.githubusercontent.com/nppackages/lpdensity/master/stata) replace
	}
//Get "binscatter" if you do not already have it
	cap which binscatter
	if _rc!=0 {
		ssc install binscatter
	}
//Put a folder to save the graphs to here with a "\" at the end:
	// For example, global save_folder "C:\Users\ryan\Documents\"
	global save_folder ""
	
	
	
///////////////////////////////////////
///////////////////////////////////////
**# An example of RD with real data from Cattaneo et. al, 2014
///////////////////////////////////////
///////////////////////////////////////
//Bring in the voting data
	use "https://github.com/rdpackages/rdrobust/raw/refs/heads/master/stata/rdrobust_senate.dta", clear
//Make some graphs
	//First, the raw data:
		twoway(scatter vote margin, msize(vtiny) mcolor(gray)), ///
			xline(0) title("Raw U.S. Senate Election Data") ///
                     ytitle(Share of Votes Democratic this Election) ///
                     xtitle(Democratic Winning Margin in the Last Election)
			cap graph export "${save_folder}raw data.png", replace
		binscatter vote margin, mcolor(gray) linetype(none) ///
			xline(0) title("Raw U.S. Senate Election Data") ///
                     ytitle(Share of Votes Democratic this Election) ///
                     xtitle(Democratic Winning Margin in the Last Election)
			cap graph export "${save_folder}averages of data in bins.png", replace
	//Next, make "RD" figures
	binscatter vote margin, mcolor(gray) ///
		xline(0) rd(0) title("RD Plot: U.S. Senate Election Data") ///
				 ytitle(Share of Votes Democratic this Election) ///
				 xtitle(Democratic Winning Margin in the Last Election)
		cap graph export "${save_folder}Linear RD plot.png", replace
	rdplot vote margin, ///The first variable is the outcome, the next is the running variable
		nbins(8 9) ///This tells the program how many bins to put to the left of the cutoff
					///and how many bins to put to the right. You can also have Stata
					///pick the number of bins for you with binselect(es) instead of nbins(# #).
		ci(95) ///Tells the program the confidence level for the confidence intervals
		p(4) ///Tells the program the order of the polynomial fit used to make
			///the conditional expectation line. By doing "4", I am specifying a "quartic"
       graph_options(title("RD Plot: U.S. Senate Election Data with Quartic Polynomial") ///
                     ytitle(Share of Votes Democratic this Election) ///
                     xtitle(Democratic Winning Margin in the Last Election) ///
                     graphregion(color(white)) legend(off))
		cap graph export "${save_folder}Quartic RD plot.png", replace
//Have Stata estimate the treatment effect:
	rdrobust vote margin, p(4) ///Tells the program the order of the polynomial fit used to make
			///the conditional expectation line.
			h(30 30) ///Specifies the "bandwidth" of 30 to the left of the cutoff
					//and 30 to the right of the cutoff. This tells Stata what range
					//of data to use to make its estimate. On the right side, we are using
					//the range from 0 to 30.
					//You can also not put anything for h, and let Stata pick its own bandwidth.

	esttab . , stats(N N_h_l N_h_r, ///
		labels("Observations" "Effective Obs. on Left" ///
				"Effective Obs. on Right")) noabbrev varwidth(25)
	//For more examples on how to use rdrobust and rdplot, see this do file from
		//Cattaneo et. al, 2014:
		// https://github.com/rdpackages/rdrobust/raw/refs/heads/master/stata/rdrobust_illustration.do
		
//Do a "McCrary" Style check for manipulation around the cutoff:
	rddensity margin //I will do this first to save the p-value in e()
	rddensity margin, plot ///The plot option makes a graph
						plot_range(-50 50) ///These two options specify 
							///the x-axis range for the plot
						hist_range(-50 50) ///
			graph_opt( legend(off) ///
			title("McCrary test for Manipulation") ///
			xtitle("Democratic Winning Margin in the Last Election") ///
			///This last line adds the p-value to the graph. If you want to use
				///this command in the future, you will need to change the first
				///two numbers after text (.023 and 2). These give the "y" and "x"
				///location of where you want your text to go.
			`"text(.023 2  "P-value=`= round(e(pv_q),.001)'"  , place(3) size(15pt) color(black))"' )
	cap graph export "${save_folder}McCrary Test.png", replace

//Do a balance test of something that should not change at cutoff: State Population
	gen pop_in_millions=population/1e6
	rdrobust pop_in_millions margin, p(4) h(30 30) 
	rdplot pop_in_millions margin, nbins(8 9) ci(95) p(4) ///
       graph_options(title("Balance Test: State Population with Quartic Polynomial") ///
                     ytitle("State Population") ///
                     xtitle(Democratic Winning Margin in the Last Election) ///
                     graphregion(color(white)) legend(off))
	cap graph export "${save_folder}Balance Test.png", replace
