
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name nixie_clock -dir "C:/Users/limpkin/Dropbox/Projets/nixie/fpga/nixie_clock/planAhead_run_3" -part xc3s50antqg144-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/limpkin/Dropbox/Projets/nixie/fpga/nixie_clock/TOP.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/limpkin/Dropbox/Projets/nixie/fpga/nixie_clock} }
set_property target_constrs_file "TOP.ucf" [current_fileset -constrset]
add_files [list {TOP.ucf}] -fileset [get_property constrset [current_run]]
link_design
