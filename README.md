# optiRADCT

OptiRADCT is a pipeline for optimizing Clustering Threshold values in Restrinction-site Associated DNA sequencing (RADseq) data assemblies performed with ipyrad for phylogenetic and phylogeography studies. It can be use to assemble RADseq datasets with a range of clustering parameters and vizualise how properties of the assemblies (e.g., proportion of informative sites and of missing data) and downstream phylogenetic inferences are affected by the values used.

# Dependencies

  - ipyrad (https://ipyrad.readthedocs.io/en/latest/)
  - R (https://www.r-project.org/)
  - raxml-PTHREADS (optionnal, https://cme.h-its.org/exelixis/web/software/raxml/)
    
The use of OptiRADCT presupposes a good understanding of the way ipyrad works. I strongly encourage the users to first get familiar with ipyrad's documentation.

 # Usage

A typical RADseq analysis workflow with de novo assembly would include the following steps:

- Step 1: Data demultiplexing and reads filtering. This can be performed by running steps 1 & 2 of ipyard, or using the process_radtags module of stacks.
- Step 2: Optimization of the clustering parameters.
  * Step 2.1: Optimization of the intra-samples clustering threshold, which is used to cluster reads within each samples.
  * Step 2.2: Optimization of the between-samples clustering threshold, which is used to cluster consensus sequences across samples.
- Step 3: Additionnal filtering of the dataset assembled with "optimal" parameters, and data formating. This is performed by re-running step 7 of ipyrad on the "best" assembly produced in Step 2.2
- Step 4: Downstream analyses.
  
OptiRADCT is meant to facilitate data exploration and vizualisation for the optimization step 2. Because ipyrad encodes a unique clustering threshold value for intra-samples and across-samples clustering, this is done by running ipyrad sequentially twice. For more detailed explanations, refer to Rancilhac et al. (2023) BioRxiv.

**1) optimization of the intra-samples Clustering Threshold (1_run_iCT.sh)**

in this first part, intra-samples clustering is performed with a user-specified range of thresholds (iCTs). Between samples clustering can be subsequently completed in each assembly using a user-specified standardized between-samples threshold (bCT).

``bash 1_run_iCT.sh -d /path/to/data -n assemblies_base_name -w /path/to/work/dir -i '0.80 0.81 0.82 0.83' -b 0.9 -D 8 -T 4 -t pairddrad -s /path/to/scripts -p -r /path/to/reference.tre``

arguments: 

``-d | --data : full path to a directory containing the raw data (cf. ipyrad documentation for file names formating). Files are expected to be gzip-compressed (.gz extension) and all .gz files in the directory will be used. See ipyrad's documentation for more details on files naming conventions.

-n | --name : a base name for ipyrad's assemblies.

-w | --work : full path to working directory where ipyrad assemblies and optiRADCT will be stored 

-u | --iCT : the range of iCTs to test, provided between apostrophes, e.g. '0.80 0.85 0.90'.

-b | --bCT : standardized clustering threshold to be used for between-samples clustering (e.g. 0.90) (optional)

-D | --depth : minimum depth of ipyrad's clusters (ipyrad parameter #11 & #12) 

-T | --threads : number of threads to use (default=1)

-t | --type : the data type used (one of: rad, ddrad, gbs, pairddrad, pairgbs, 2brad, pair3rad; ipyard parameter #7)

-s | --scripts : full path to the directory containing the optiRADCT scripts

-p | --tree : if this option is specified, maximum likelihood trees will be inferred with RAxML for each iCT.

-r | --ref : can be used to specify a reference tree in newick format to compare the RAxML trees to (using topological distances). Used only if -p is specified.

-h | --help : prints a help message and exits.``


This script will perform all assemblies and internaly execute harvest_stats.sh and 2_plot_iCT_stats.R, providing summary graphs in a pdf.

**2) optimization of the between-samples Clustering Threshold (3_run_bCT.sh)**

In this second part, the clusters assembled at the previous step with the iCT identified as optimal are used to assemble loci with a range of between-samples Clustering Thresholds (bCTs).


``bash 3_run_bCT.sh -n assemblies_base_name -i /path/to/iCT/assemblies -p iCT -t y``

arguments: 

-n | --name : a base name for ipyrad's assemblies

-i | --ict : path to the directory containing ipyrad's outputs from previous step

-p | --param [int]: iCT identified as optimal in previous step 

-t | --tree : optionnal, if ``-t y`` then raxml is used to calculate phylogenetic trees from the different assemblies

When executing this script, the user have to interactively type the bCTs to be tested, e.g.: ``0.70 0.80 0.90``
This script will perform all assemblies and internaly execute harvest_stats.sh and 4_plot_bCT_stats.R, providing summary graphs in a pdf.
