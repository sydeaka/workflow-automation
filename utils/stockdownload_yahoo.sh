#!/usr/bin/sh
set -e

symbol=$1
today=$(date +%Y%m%d)
tomorrow=$(date --date='1 days' +%Y%m%d)

first_date=$(date -d "$2" '+%s')
last_date=$(date -d "$today" '+%s')

wget --no-check-certificate --save-cookies=cookie.txt https://finance.yahoo.com/quote/$symbol/?p=$symbol -O crumb.store

crumb=$(grep 'root.*App' crumb.store | sed 's/,/\n/g' | grep CrumbStore | sed 's/"CrumbStore":{"crumb":"\(.*\)"}/\1/')

wget --no-check-certificate --load-cookies=cookie.txt "https://query1.finance.yahoo.com/v7/finance/download/$symbol?period1=$first_date&period2=$last_date&interval=1d&events=history&crumb=$crumb" -O $symbol.csv

rm cookie.txt crumb.store