#!/bin/bash
set -e

## Settings
work_dir=/Users/sw659h/Documents/training/mysql/repos/workflow-automation
cd ${work_dir}

## Set parameters
echo "
**** Set parameters"
source config/set_params.config
export $(cut -d= -f1 config/set_params.config)
source ${cred_file}
export $(cut -d= -f1 ${cred_file})
website=https://resources.lendingclub.com
dataset=LoanStats_${year}Q${quarter}
csv=${dataset}.csv
zip=${csv}.zip
mysql_file=mysql_script_LoanStats_${year}Q${quarter}.sql


## Change into working directory
cd ${work_dir}


## Download the dataset if it does not exist
echo "
**** Download the dataset if it does not exist"
cd data/downloads
if [ -f "$zip" ]
then
	echo "$zip found. Using local copy."
else
	echo "$zip not found. Downloading..."
	echo ${website}/${zip}
	wget ${website}/${zip}
	echo "Unzipping..."
	unzip ${zip}
	echo "Done."
fi
cd ${work_dir}


if [ "$use_mysql" == "TRUE" ]
then
	## Generate MYSQL script
	echo "
	**** Generate MYSQL script"
	Rscript utils/generate_mysql_script.R ${year} ${quarter}

	## Start MYSQL session, login
	## Run MYSQL script to create table and load dataset
	echo "
	**** Run MYSQL script to create table and load dataset"
	${mysql_run} --user=${user} --password=${password} < data/sql/${mysql_file}
	 
	## Start MYSQL session, login
	## Run MYSQL script to create modeling table
	## Joins raw data from previous step to population tables, 
	## Create new table with subset of columns
	echo "
	**** Create MYSQL script that creates modeling table"
	sh data/bash/make-modeling-sql2.sh LoanStats_${year}Q${quarter}
	echo "
	Run MYSQL script to create modeling table"
	${mysql_run} --user=${user} --password=${password} < data/sql/modeling.sql 
else 
	echo "Running without mysql."
fi


## Within an R session, connect to MYSQL, retrieve dataset, apply transformations
echo "
**** Within an R session, connect to MYSQL (if use_mysql=TRUE) or retrieve locally stored data (if use_mysql != TRUE);
**** retrieve dataset, apply transformations"
Rscript --vanilla utils/get_modeling_data.R ${user} ${password} ${year} ${quarter} ${work_dir} ${use_mysql} ${csv}

## Within an R session, analyze the data and save artifacts to disk
echo "
**** Within an R session, analyze the data and save artifacts to disk"
Rscript --vanilla utils/analysis.R ${year} ${quarter} ${work_dir} 

## Render markdown report
echo "
**** Render markdown report"
Rscript --vanilla utils/render.R ${year} ${quarter} ${work_dir} 

## Email the report
echo "
**** Email the report"
Rscript --vanilla utils/email.R ${year} ${quarter} ${work_dir} 

## Check in code to github
echo "
**** Check in code to github"
commit_message="Analysis of ${year} Q${quarter} Lending Club dataset"
git config --global user.name "Watson, Sydeaka"
git config --global user.email "sydeakawatson@gmail.com"
git add --all
echo "${commit_message}" | git commit -F -
git push -u origin --all

