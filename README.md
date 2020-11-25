# optiRADCT

OptiRADCT is a pipeline for optimizing Clustering Threshold values in Restrinction-site Associated DNA sequencing (RADseq) data assemblies performed with ipyrad for phylogenetic and phylogeography studies.

# Dependencies

  - ipyrad (https://ipyrad.readthedocs.io/en/latest/)
  - R (https://www.r-project.org/)
  - raxml (optionnal, https://cme.h-its.org/exelixis/web/software/raxml/)

 # Usage
 
OptiRADCT works in two steps.

*1) optimization of the intra-samples Clustering Threshold (1_run_iCT.sh)*

in this first part, intra-samples clustering is performed with a user-specified range of thresholds (iCTs). Between samples clustering is subsequently completed in each assembly using a user-specified standardized threshold (bCT).

``bash 1_run_iCT.sh -d /path/to/data -n assemblies_base_name -w /path/to/work/dir -D depth -b bCT``

arguments: 

-d | --data : path to a directory containing the raw data (cf. ipyrad documentation for file names formating) 

-n | --name : a base name for ipyrad's assemblies

-w | --work : path to working directory where ipyrad assemblies and optiRADCT will be stored 

-D | --depth [int]: minimum depth of ipyrad's clusters (ipyrad parameter #11 & #12) 

-b | --bCT1 [int]: standardized clustering threshold to be used for between-samples clustering (e.g. 0.90)

When executing this script, the user have to interactively type the iCTs to be tested, e.g.: ``0.70 0.80 0.90``
This script will perform all assemblies and internaly execute harvest_stats.sh and 2_plot_iCT_stats.R, providing summary graphs in a pdf.

*2) optimization of the between-samples Clustering Threshold (3_run_bCT.sh)*

In this second part, the clusters assembled at the previous step with the iCT identified as optimal are used to assemble loci with a range of between-samples Clustering Thresholds (bCTs).


``bash 3_run_bCT.sh -n assemblies_base_name -i /path/to/iCT/assemblies -p iCT -t y``

arguments: 

-n | --name : a base name for ipyrad's assemblies

-i | --ict : path to the directory containing ipyrad's outputs from previous step

-p | --param [int]: iCT identified as optimal in previous step 

-t | --tree : optionnal, if ``-t y`` then raxml is used to calculate phylogenetic trees from the different assemblies

When executing this script, the user have to interactively type the bCTs to be tested, e.g.: ``0.70 0.80 0.90``
This script will perform all assemblies and internaly execute harvest_stats.sh and 4_plot_bCT_stats.R, providing summary graphs in a pdf.
