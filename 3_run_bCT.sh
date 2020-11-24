#!/bin/bash

## PARAMETERS TO PARSE:
# Data dir
# $ICT = directory were the assemblies from 1_run_iCT.sh are located
# $TREE = whether to run raxml on the resulting assemblies or not
# $PICT = iCT value selected as optimal (assemblies will be generated from these clusters)
# path to param file used for ICT.sh

while [[ $# -gt 0 ]]
do
key="$1"

case "$key" in
	-n | --name)
	NAME=$2
	shift
	shift
	;;
	-i | --ict)
	WORK=$2
	shift
	shift
	;;
	-p | --param)
	
	PICT=$2
	shift
	shift
	;;
	-t | --tree)
	TREE=$2
	shift
	shift
	;;
esac
done

SCRIPTS="/home/lois/Documents/Projects/Species_delimitation/RADseq/Assembly_pipeline_v1"


#### PART 2: bCT ####

echo "Enter the bCT to be tested (e.g. 0.50 0.60 0.70 0.80)"
read BCT

echo -e "\n ipyrad will be run with the following bCTs: \n $BCT \n"

cd $WORK

OPTPAR=$(ls params*iCT_$PICT*)

echo -e "generating the parameter files\n"

# This loop generates a parameter file for each bCT
for i in $BCT
do

PARAM=$(echo $i | cut -d'.' -f2)

ipyrad -p $OPTPAR -b "$NAME"_bCT_$PARAM


sed -r -i "s/^.*(\#\# \[14\].*)/$i \1/" $WORK/params-"$NAME"_bCT_"$PARAM".txt

# these should be useless now (useful only if files are moved to a new directory) - kept just in case.
#sed -r -i "s@^.*(\#\# \[1\].*)@$WORK \1@" $WORK/params-"$NAME"_bCT_"$(echo $i | cut -d'.' -f2)"*
#sed -r -i "s@(.*_project_dir\":\").*(\"\,)@\1$WORK\2@" $WORK/"$NAME"_bCT_"$(echo $i | cut -d'.' -f2)".json

done

cd $WORK

for i in params*
do
echo -e "\n Starting steps 6 & 7 for bCT=$(echo $i | cut -d'_' -f5 | cut -d'.' -f1)\n"

ipyrad -p $i -s 67 -f
done

if [ $TREE == "y" ]
then
RAXEX=$(compgen -c "raxml" | head -1)

for o in *bCT*outfiles
do
cd $o
$RAXEX -s *.phy -m GTRGAMMA -n $(echo $o | cut -d'_' -f5 | cut -d'.' -f1) -f a -# 50 -p $RANDOM -x $RANDOM -T 20
cd ..
done

fi

mkdir tmp

cp -r *bCT*outfiles tmp
cd tmp

bash $SCRIPTS/harvest_stats.sh -s 7 -w $WORK/tmp -o $WORK/stats_bCT

rm -rf tmp

# plot stats

cd $WORK/stats_bCT
Rscript $SCRIPTS/4_Plot_bCT_stats.R $WORK/stats 

echo "stats plots are stored in" $(ls $WORK/stats/*.pdf)

echo -e "\n iCT RUNS SUCCESSFULLY COMPLETED \n"
