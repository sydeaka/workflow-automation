


## Set session parameters
if (interactive()) {
  year = 2016
  quarter = 2
  work_dir='/Users/sw659h/Documents/training/mysql/repos/workflow-automation'
} else {
  ## Read in parameters passed in as arguments
  args = commandArgs(trailingOnly=TRUE)
  year = args[1]
  quarter = args[2]
  work_dir = args[3]
}

## Load package
library(mailR)

## Read in credentials
gmail_password = readLines('~/gmail.txt')

## Email subject
email_subject = paste0("Debt consolidation modeling results for ", year, " Q", quarter, ": ", Sys.time())

## Email body
email_body = paste0(
"
Greetings, team.

The Lending Club model was successfully updated. Recall that we are focusing on adverse outcomes for debt consolidation loans originating in ", 
year, ", Q", quarter, ".

The report is attached. 

I checked all of the code into our repository. You could review it at any time at the following link:
https://github.com/sydeaka/workflow-automation

Let me know if you have any questions. Best regards!

Sydeaka
"
)




## Attached_files
attached_files = c('reports/low_grade_debt_consolidation_report.html')


## Send the email
send.mail(from = 'sydeaka.watson@gmail.com',
    to = 'korelasidata@gmail.com',
    subject = email_subject,
    body = email_body,
    smtp = list(host.name = "smtp.gmail.com", port = 587,
                user.name = "sydeaka.watson@gmail.com",
                passwd = gmail_password, ssl = TRUE),
    authenticate = TRUE,
    send = TRUE,
    attach.files = attached_files
    )

