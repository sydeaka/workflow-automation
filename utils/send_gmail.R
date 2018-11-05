
## Load package
library(mailR)
library(getPass)
#library(plyr)



send_gmail <- function(cred_file='~/gmail.txt', email_body, attached_files=NULL,
	Gmail_address_from, email_address_to, email_subject) {

	## Read in credentials
	msg('Read in credentials')
	if (!file.exists(cred_file)) {
	    password_message <- paste0('Credentials file not found. Enter Gmail password for ', Gmail_address_from, ':')
	    gmail_password <- getPass(password_message)
	  } else {
	    gmail_password <- readLines(cred_file)
	}


	## Send the email
	msg('Send the email')
	email_function_failwith <- plyr::failwith(NULL, function(...) send.mail(from = Gmail_address_from,
	    to = email_address_to,
	    subject = email_subject,
	    body = email_body,
	    smtp = list(host.name = "smtp.gmail.com", port = 587,
	                user.name = Gmail_address_from,
	                passwd = gmail_password, ssl = TRUE),
	    authenticate = TRUE,
	    send = TRUE,
	    attach.files = attached_files
	    ), quiet=F)

	result <- email_function_failwith()
	if (is.null(result)) {
		stop('To use mailR utilities with a gmail account, you must allow less secure apps.
		 Please visit https://myaccount.google.com/lesssecureapps and turn this feature ON.')
	} 

	msg('Email sent.')
} # end send_email function

