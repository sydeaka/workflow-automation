SET GLOBAL local_infile=1;

USE LENDING;
DROP TABLE IF EXISTS modeling;
CREATE TABLE modeling AS (
select 
 
   loan_amnt
 , term
 , int_rate
 , installment
 , grade
 , sub_grade
 , emp_length
 , home_ownership
 , annual_inc
 , verification_status
 , loan_status
 , purpose
 , dti
 , delinq_2yrs
 , inq_last_6mths
 , pub_rec_bankruptcies
 , open_acc
 , pub_rec
 , revol_bal
 , revol_util
 , total_acc
 , addr_state
 , Population2018
 , Growth2018
 , Percent_of_US
 
from LoanStats_2016Q2 loans
left join 
state_pop_abbrev pop
on pop.Abbreviation = loans.addr_state
)
;
