
2plus2gating_genrpt.pl

	Purpose: compare gater cap and area between vanilla run and a run with 2+2 gating topology. Prints out a comparison table for the two runs.





b2b_quad.pl

	Purpose: ECO utility, Generates a PT script that checks timing on back-to-back design check failures. 





cellFIT.pl

	Purpose: ECO utility, Generates a tcl script that upsizes cells by the appropriate amount to get them to pass the Failure-in-time design check.





IRstapler_hotspots_all.pl

	Purpose: Tile level IR staple utility for generating the .rs file for tile simulation data. Process Redhawk IR failures and generate power grid staple patches around hotspots. Process Vdd and Vss separately to make stapling less disruptive. 





IRstapler_hotspots_separate_corestats.pl

	Purpose: Core level IR staple utility for generating the .rs file based on core simulation data. For each tile in the core, process Redhawk IR failures and generate power grid staple patches around hotspots.Process Vdd and Vss separately to make stapling less disruptive. 




compare_fp.pl

	Purpose: Used for flagging any signficant changes to port locations and IO constraints between a recent floorplan and a newly generated floorplan.





compare_io_getdef.pl

	Purpose: Compare a new run's .def file with that of an older run to flag any hidden issues with port placements and sdc's early in the build flow.





component_timing_summary.pl

	Purpose: Generate a table that lists critical information about every path failing at the component level. REALLY helps IO triage. Combination logic count, buffer/inverter count, worst edge rate, manhattan distance, ports in the path, time spent in a tile vs time given to tile from the sdc previous slack, next slack, clock skew, total sdc budget, etc.





find_possible_crossbars*.pl

	Purpose: I found a crossbar (many to many mapping of logic, creates problems when routing, can be unbuildable) in an rtl (.v file) and wrote this to flag other crossbars in all .x files (these are file written that will get unrolled/expanded into .v files) for the chip. Flagged code signatures were sent to the authors of the files and this effort helped ease route congestion in the tiles where they were implemented once they were recoded. 




flops.pl

	Purpose: This script was cron'd so we could monitor flop count creep from week to week. This also broke down flop counts by type.




maxtrans.pl

	Purpose: ECO utility, grab all the nets that have transitions about the failure threshold  that are on a repeater network out of the core level log file. Used later for adjusting handplaced repeaters on timing-difficult fabrics so they don't fail tranistion violation design checks.





port_swap.pl

	Purpose: Flag any buses (ports) that want to swap locaitons based on their center-of-mass fanin/fanout. Also flags buses that would like to live elsewhere.


pt_summary.pl

	Purpose: Generates timing histogram and path summaries additional detail for timing triage.





rtl_tracer*.pl

	Purpose: Traces through rtl files/modules and flags equations/flops/modules,etc. that are connected to a provided net/module/state element. Good for identifying the culprits of routing congestion in a tile.





rv_compare.pl

	Purpose: There was an rtl issues where flops bundled into quadflops had different reset values. I wrote this script for the team so that it would flag those quads where the individual state elements in the rtl didn't all have the same reset value.





timing_report_summary.pl

	Purpose: 1000ft view of a timing path group. Allows user to understand who the most prevalent offenders are in terms of timing as well as the most significant i.e. which paths are hogging all the resources of the timing optimizer. Prints out timing histogram, and for each bin who the most significant contributor is. Lets you know where the best bang for you buck is for timing triage. 





compare_statepoints.pl

	Purpose: compare WNS/TNS on specified statpoints between various branched runs and the baseline run. 





