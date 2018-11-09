#!/bin/bash
set -e

## Automatically detect working directory
export work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

## Change into working directory
cd ${work_dir}

## Set parameters
echo -e "\n**** Set parameters"
source config/set_params.config
export $(cut -d= -f1 config/set_params.config)
source ${cred_file}
export $(cut -d= -f1 ${cred_file})
website=https://resources.lendingclub.com
dataset=LoanStats_${year}Q${quarter}
csv=${dataset}.csv
zip=${csv}.zip
mysql_file=mysql_script_LoanStats_${year}Q${quarter}.sql


## Download the dataset if it does not exist
echo -e "\n**** Download the dataset if it does not exist"
cd data/downloads
if [ -f "$csv" ]
then
	echo "$csv found. Using local copy."
else
	echo "$csv not found. Downloading..."
	echo ${website}/${zip}
	wget ${website}/${zip}
	echo "Unzipping..."
	unzip ${zip}
	echo "Delete zip file"
	rm ${zip}
	echo "Done."
fi
cd ${work_dir}


if [ "$use_mysql" == "TRUE" ]
then
	## Generate MYSQL script
	echo -e "\n**** Generate MYSQL script"
	R_bots/generate_mysql_script.R ${year} ${quarter}

	## Start MYSQL session, login
	## Run MYSQL script to create table and load dataset
	echo -e "\n**** Run MYSQL script to create table and load dataset"
	#${mysql_run} --user=${user} --password=${password} < data/sql/${mysql_file}
	utils/run_mysql_script.R ${user} ${password} data/sql/${mysql_file}
	 
	## Start MYSQL session, login
	## Run MYSQL script to create modeling table
	## Joins raw data from previous step to population tables, 
	## Create new table with subset of columns
	echo -e "\n**** Create MYSQL script that creates modeling table"
	sh make-modeling-sql.sh LoanStats_${year}Q${quarter}
	echo -e "\nRun MYSQL script to create modeling table"
	#${mysql_run} --user=${user} --password=${password} < data/sql/modeling.sql 
	utils/run_mysql_script.R ${user} ${password} data/sql/modeling.sql 
	
	
else 
	echo "Running without mysql."
fi


## Within an R session, connect to MYSQL, retrieve dataset, apply transformations
echo -e "\n**** Within an R session, connect to MYSQL (if use_mysql=TRUE) or retrieve locally stored data (if use_mysql != TRUE);
**** retrieve dataset, apply transformations"
R_bots/get_modeling_data.R ${user} ${password} ${year} ${quarter} ${work_dir} ${use_mysql} ${csv}

## Within an R session, analyze the data and save artifacts to disk
echo -e "\n**** Within an R session, analyze the data and save artifacts to disk"
R_bots/analysis.R ${year} ${quarter} ${work_dir} 

## Render markdown report
echo -e "\n**** Render markdown report"
R_bots/render.R ${year} ${quarter} ${work_dir} 

## Email the report
echo -e "\n**** Email the report."
R_bots/email_report.R ${year} ${quarter} ${work_dir} ${Gmail_name_from} ${Gmail_address_from} ${email_address_to}

## Check in code to github
echo -e "\n**** Check in code to github"
R_bots/github_code_checkin.R ${year} ${quarter} ${Gmail_name_from} ${Gmail_address_from} ${email_address_to}

echo "DONE."
