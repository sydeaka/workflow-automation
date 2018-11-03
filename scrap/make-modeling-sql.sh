#!/bin/bash
set -e


echo "SET GLOBAL local_infile=1;

USE LENDING;
DROP TABLE IF EXISTS modeling;
CREATE TABLE modeling AS (
select 
   issue_d
 , loan_amnt
 , term
 , int_rate
 , grade
 , home_ownership
 , annual_inc
 , annual_inc_joint
 , verification_status
 , purpose
 , application_type
 , disbursement_method
 , delinq_2yrs
 , dti
 , dti_joint
 , emp_length
 , inq_fi
 , inq_last_12m
 , inq_last_6mths
 , mo_sin_old_il_acct
 , mo_sin_old_rev_tl_op
 , mo_sin_rcnt_rev_tl_op
 , mo_sin_rcnt_tl
 , mort_acc
 , mths_since_last_delinq
 , mths_since_last_major_derog
 , mths_since_last_record
 , mths_since_rcnt_il
 , mths_since_recent_bc
 , mths_since_recent_bc_dlq
 , mths_since_recent_inq
 , mths_since_recent_revol_delinq
 , num_actv_bc_tl
 , num_actv_rev_tl
 , num_bc_sats
 , num_bc_tl
 , num_il_tl
 , num_op_rev_tl
 , num_rev_accts
 , num_rev_tl_bal_gt_0
 , num_sats
 , num_tl_120dpd_2m
 , num_tl_30dpd
 , num_tl_90g_dpd_24m
 , num_tl_op_past_12m
 , open_acc
 , open_acc_6m
 , open_il_12m
 , open_il_24m
 , open_act_il
 , open_rv_12m
 , open_rv_24m
 , out_prncp
 , out_prncp_inv
 , pct_tl_nvr_dlq
 , percent_bc_gt_75
 , pymnt_plan
 , addr_state
 , Population2018
 , Growth2018
 , Percent_of_US
 , loan_status
from $1 loans
left join 
state_pop_abbrev pop
on pop.Abbreviation = loans.addr_state
)
;" > data/sql/modeling.sql
