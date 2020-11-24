#!/bin/bash

## DEV NOTES
# add options for demultiplexed vs. multiplexed data
# add more options for param files (data type, ect)

## PARAMETERS TO PARSE:
# Data dir
# Working dir
# bCT for step 3
# basename
# Depth

while [[ $# -gt 0 ]]
do
key="$1"

case "$key" in
	-d | --data)
	DATA=$2
	shift
	shift
	;;
	-n | --name)
	NAME=$2
	shift
	shift
	;;
	-w | --work)
	WORK=$2
	shift
	shift
	;;
	-D | --depth)
	DEPTH=$2
	shift
	shift
	;;
	-b | --bCT1)
	bCT1=$2
	shift
	shift
	;;
esac
done


#### PART 1: iCT ####

cd $WORK

echo "Enter the iCT to be tested (e.g. 0.50 0.60 0.70 0.80)"
read ICT
echo -e "\n ipyrad will be run with the following iCTs: \n $ICT \n"


cd $WORK 

echo -e "generating the parameter files\n"

# This loop generates a parameter file for each iCT
for i in $ICT
do
TN=$(echo $i | cut -d'.' -f2)
ipyrad -n "$NAME"_iCT_"$TN"
sed -i -r "s/^.*([[:space:]]*\#\# \[14\])/$i   \1/" params-"$NAME"_iCT_"$TN".txt
done

# set the remaining parameters: path to sorted data, mindepth
sed -i -r "s@^.*([[:space:]]*\#\# \[4\])@$DATA\*\.gz   \1@" param*
sed -i -r "s/^.*([[:space:]]*\#\# \[11\])/$DEPTH   \1/" param*
sed -i -r "s/^.*([[:space:]]*\#\# \[12\])/$DEPTH   \1/" param*
sed -i -r "s/^.*([[:space:]]*\#\# \[7\])/pairddrad   \1/" param*


# this loop performs the first 3 steps of ipyrad for all the param files generated above
for i in $ICT
do
echo -e "\nStarting assembly for iCT=$i\n"
TN=$(echo $i | cut -d'.' -f2)
ipyrad -p params-"$NAME"_iCT_"$TN".txt -s 123
done


if [ -n $bCT1  ]
then

sed -i -r "s/^.*([[:space:]]*\#\# \[14\])/$bCT1   \1/" params-*

for i in $ICT
do
echo -e "\nCompleting the assembly of iCT=$i with bCT=$bCT1\n"
TN=$(echo $i | cut -d'.' -f2)
ipyrad -p params-"$NAME"_iCT_"$TN".txt -s 4567
done

fi

# harvest stats for all assemblies

cd $WORK

bash harvest_stats.sh -s 357 -w $WORK -o $WORK/stats_iCT

# plot stats

cd $WORK/stats_iCT
Rscript 2_plot_iCT_stats.R $WORK/stats_iCT 

echo "stats plots are stored in" $(ls $WORK/stats/*.pdf)

echo -e "\n iCT RUNS SUCCESSFULLY COMPLETED \n"


