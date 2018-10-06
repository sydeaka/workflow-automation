
msg = function(u) cat('\n', u, '\n')

## Set session parameters
msg('Set session parameters')
if (interactive()) {
  year = 2016
  quarter = 2
  work_dir='/Users/sw659h/Documents/training/mysql/repos/workflow-automation'
  Gmail_name_from='Watson, Sydeaka'
  Gmail_address_from='sydeakawatson@gmail.com'
  email_address_to='korelasidata@gmail.com'
} else {
  ## Read in parameters passed in as arguments
  args = commandArgs(trailingOnly=TRUE); #print(args)
  year = args[1]
  quarter = args[2]
  work_dir = args[3]
  Gmail_name_from=args[4]; #msg(Gmail_name_from)
  Gmail_address_from=args[5]; #msg(Gmail_address_from)
  email_address_to=args[6]; #msg(email_address_to)
}

## Load package
library(mailR)

## Read in credentials
msg('Read in credentials')
cred_file = '~/gmail.txt'
if (!file.exists(cred_file)) {
    library(getPass)
    password_message = paste0('Credentials file not found. Enter Gmail password for ', Gmail_address_from, ':')
    gmail_password=getPass(password_message)
  } else {
    gmail_password = readLines(cred_file)
}


msg('Email subject, body, and attachments')
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
msg('Send the email')
send.mail(from = Gmail_address_from,
    to = email_address_to,
    subject = email_subject,
    body = email_body,
    smtp = list(host.name = "smtp.gmail.com", port = 587,
                user.name = Gmail_address_from,
                passwd = gmail_password, ssl = TRUE),
    authenticate = TRUE,
    send = TRUE,
    attach.files = attached_files
    )

