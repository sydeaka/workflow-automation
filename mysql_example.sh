#!/bin/bash
set -e

## Settings
# https://stackoverflow.com/questions/49194719/authentication-plugin-caching-sha2-password-cannot-be-loaded
# ALTER USER 'username'@'ip_address' IDENTIFIED WITH mysql_native_password BY 'password';
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
	#wget -P data/ ${website}/${zip}
	wget ${website}/${zip}
	echo "Unzipping..."
	unzip ${zip}
	echo "Done."
fi
cd ${work_dir}


## Generate MYSQL script
echo "
**** Generate MYSQL script"
# https://medium.com/@AviGoom/how-to-import-a-csv-file-into-a-mysql-database-ef8860878a68
# https://stackoverflow.com/questions/16285864/how-can-i-correct-mysql-load-error
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
# http://worldpopulationreview.com/states/
# https://github.com/jasonong/List-of-US-States/blob/master/states.csv
echo "
**** Create MYSQL script that creates modeling table"
sh data/bash/make-modeling-sql2.sh LoanStats_${year}Q${quarter}
echo "
Run MYSQL script to create modeling table"
${mysql_run} --user=${user} --password=${password} < data/sql/modeling.sql 

## Export modeling table as a csv <--- DO NOT RUN
# https://coderwall.com/p/medjwq/mysql-output-as-csv-on-command-line
#alias mysql2csv='sed '\''s/\\t/","/g;s/^/"/;s/$/"/;s/\n//g'\'''
#${mysql_run} --user=${user} --password=${password} -e "select * from lending.modeling" | \
#mysql2csv > data/modeling_${year}Q${quarter}.csv

## Within an R session, connect to MYSQL, retrieve dataset, apply transformations
# https://stackoverflow.com/questions/47932246/rscript-detect-if-r-script-is-being-called-sourced-from-another-script
echo "
**** Within an R session, connect to MYSQL, retrieve dataset, apply transformations"
Rscript --vanilla utils/get_modeling_data.R ${user} ${password} ${year} ${quarter} ${work_dir}

## Within an R session, analyze the data and save artifacts to disk
# https://github.com/SunilAppanaboyina/MachineLearning/tree/master/Loan%20Default
Rscript --vanilla utils/analysis.R ${year} ${quarter} ${work_dir} 

## Render markdown report


## Email the report
Rscript --vanilla utils/report.R ${year} ${quarter} ${work_dir} 

## Check in code to github
# https://help.github.com/articles/caching-your-github-password-in-git/
git config --global user.name "Watson, Sydeaka"
git config --global user.email "sydeakawatson@gmail.com"
git add --all
git commit -m "Analysis of ${year} Q{$quarter} Lending Club dataset"
#git config http.postBuffer 524288000
git push -u origin --all



