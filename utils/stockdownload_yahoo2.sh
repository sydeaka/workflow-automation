#!/usr/bin/sh
set -e

# https://stackoverflow.com/questions/44498924/wget-cant-download-yahoo-finance-data-any-more
# https://unix.stackexchange.com/questions/184770/convert-input-string-to-date-in-shell-script

symbol=$1
echo $symbol
today=$(date +%Y%m%d)
echo $today

# Linux
#tomorrow=$(date --date='1 days' +%Y%m%d)
#first_date=$(date -d "$2" '+%s')
#last_date=$(date -d "$today" '+%s')

# Mac OS
tomorrow=$(date -v+1d "+%Y%m%d")
echo $tomorrow
first_date=$(date -j -f '%Y%m%d' "$2" +'%Y%m%d')
echo $first_date
last_date=$(date -j -f '%Y%m%d' "$today" +'%Y%m%d')
echo $last_date

wget --no-check-certificate --save-cookies=cookie.txt https://finance.yahoo.com/quote/$symbol/?p=$symbol -O crumb.store
echo "check 1"

crumb=$(grep 'root.*App' crumb.store | sed 's/,/\n/g' | grep CrumbStore | sed 's/"CrumbStore":{"crumb":"\(.*\)"}/\1/')
echo "crumb"

wget --no-check-certificate --load-cookies=cookie.txt "https://query1.finance.yahoo.com/v7/finance/download/$symbol?period1=$first_date&period2=$last_date&interval=1d&events=history&crumb=$crumb" -O $symbol.csv
echo "check 2"

rm cookie.txt crumb.store
