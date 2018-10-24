## Email the report
echo "
**** Email the report"
Rscript --vanilla utils/email.R ${year} ${quarter} ${work_dir} ${Gmail_name_from} ${Gmail_address_from} ${email_address_to}

## Check in code to github
echo "
**** Check in code to github"
sh data/bash/github.sh

## Open repository in Safari web browser
open -a Safari https://github.com/sydeaka/workflow-automation