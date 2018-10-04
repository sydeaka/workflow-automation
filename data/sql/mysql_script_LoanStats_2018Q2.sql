SET GLOBAL local_infile=1;
    USE lending;
DROP TABLE IF EXISTS LoanStats_2018Q2;
CREATE TABLE LoanStats_2018Q2
(id int, 
member_id int, 
loan_amnt int, 
funded_amnt int, 
funded_amnt_inv int, 
term varchar(10), 
int_rate varchar(7), 
installment decimal(6,2), 
grade varchar(1), 
sub_grade varchar(2), 
emp_title varchar(40), 
emp_length varchar(9), 
home_ownership varchar(8), 
annual_inc decimal(9,2), 
verification_status varchar(15), 
issue_d varchar(8), 
loan_status varchar(18), 
pymnt_plan varchar(1), 
url int, 
desc_X int, 
purpose varchar(18), 
title varchar(23), 
zip_code varchar(5), 
addr_state varchar(2), 
dti decimal(5,2), 
delinq_2yrs int, 
earliest_cr_line varchar(8), 
inq_last_6mths int, 
mths_since_last_delinq int, 
mths_since_last_record int, 
open_acc int, 
pub_rec int, 
revol_bal int, 
revol_util varchar(6), 
total_acc int, 
initial_list_status varchar(1), 
out_prncp decimal(7,2), 
out_prncp_inv decimal(7,2), 
total_pymnt decimal(7,2), 
total_pymnt_inv decimal(7,2), 
total_rec_prncp decimal(7,2), 
total_rec_int decimal(6,2), 
total_rec_late_fee decimal(5,2), 
recoveries decimal(3,2), 
collection_recovery_fee decimal(3,2), 
last_pymnt_d varchar(8), 
last_pymnt_amnt decimal(7,2), 
next_pymnt_d varchar(8), 
last_credit_pull_d varchar(8), 
collections_12_mths_ex_med int, 
mths_since_last_major_derog int, 
policy_code int, 
application_type varchar(10), 
annual_inc_joint decimal(9,2), 
dti_joint decimal(4,2), 
verification_status_joint varchar(15), 
acc_now_delinq int, 
tot_coll_amt int, 
tot_cur_bal int, 
open_acc_6m int, 
open_act_il int, 
open_il_12m int, 
open_il_24m int, 
mths_since_rcnt_il int, 
total_bal_il int, 
il_util int, 
open_rv_12m int, 
open_rv_24m int, 
max_bal_bc int, 
all_util int, 
total_rev_hi_lim int, 
inq_fi int, 
total_cu_tl int, 
inq_last_12m int, 
acc_open_past_24mths int, 
avg_cur_bal int, 
bc_open_to_buy int, 
bc_util decimal(5,2), 
chargeoff_within_12_mths int, 
delinq_amnt int, 
mo_sin_old_il_acct int, 
mo_sin_old_rev_tl_op int, 
mo_sin_rcnt_rev_tl_op int, 
mo_sin_rcnt_tl int, 
mort_acc int, 
mths_since_recent_bc int, 
mths_since_recent_bc_dlq int, 
mths_since_recent_inq int, 
mths_since_recent_revol_delinq int, 
num_accts_ever_120_pd int, 
num_actv_bc_tl int, 
num_actv_rev_tl int, 
num_bc_sats int, 
num_bc_tl int, 
num_il_tl int, 
num_op_rev_tl int, 
num_rev_accts int, 
num_rev_tl_bal_gt_0 int, 
num_sats int, 
num_tl_120dpd_2m int, 
num_tl_30dpd int, 
num_tl_90g_dpd_24m int, 
num_tl_op_past_12m int, 
pct_tl_nvr_dlq decimal(5,2), 
percent_bc_gt_75 decimal(5,2), 
pub_rec_bankruptcies int, 
tax_liens int, 
tot_hi_cred_lim int, 
total_bal_ex_mort int, 
total_bc_limit int, 
total_il_high_credit_limit int, 
revol_bal_joint int, 
sec_app_earliest_cr_line varchar(8), 
sec_app_inq_last_6mths int, 
sec_app_mort_acc int, 
sec_app_open_acc int, 
sec_app_revol_util decimal(5,2), 
sec_app_open_act_il int, 
sec_app_num_rev_accts int, 
sec_app_chargeoff_within_12_mths int, 
sec_app_collections_12_mths_ex_med int, 
sec_app_mths_since_last_major_derog int, 
hardship_flag varchar(1), 
hardship_type int, 
hardship_reason int, 
hardship_status int, 
deferral_term int, 
hardship_amount int, 
hardship_start_date int, 
hardship_end_date int, 
payment_plan_start_date int, 
hardship_length int, 
hardship_dpd int, 
hardship_loan_status int, 
orig_projected_additional_accrued_interest int, 
hardship_payoff_balance_amount int, 
hardship_last_payment_amount int, 
disbursement_method varchar(9), 
debt_settlement_flag varchar(1), 
debt_settlement_flag_date varchar(8), 
settlement_status varchar(6), 
settlement_date varchar(8), 
settlement_amount int, 
settlement_percentage decimal(4,2), 
settlement_term int);

LOAD DATA LOCAL INFILE '/Users/sw659h/Documents/training/mysql/data/downloads/LoanStats_2018Q2.csv'
    INTO TABLE LoanStats_2018Q2 
    FIELDS TERMINATED BY ',' 
    OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\n' 
    IGNORE 2 ROWS 
    ( id, member_id, loan_amnt, funded_amnt, funded_amnt_inv, term, int_rate, installment, grade, sub_grade, emp_title, emp_length, home_ownership, annual_inc, verification_status, issue_d, loan_status, pymnt_plan, url, desc_X, purpose, title, zip_code, addr_state, dti, delinq_2yrs, earliest_cr_line, inq_last_6mths, mths_since_last_delinq, mths_since_last_record, open_acc, pub_rec, revol_bal, revol_util, total_acc, initial_list_status, out_prncp, out_prncp_inv, total_pymnt, total_pymnt_inv, total_rec_prncp, total_rec_int, total_rec_late_fee, recoveries, collection_recovery_fee, last_pymnt_d, last_pymnt_amnt, next_pymnt_d, last_credit_pull_d, collections_12_mths_ex_med, mths_since_last_major_derog, policy_code, application_type, annual_inc_joint, dti_joint, verification_status_joint, acc_now_delinq, tot_coll_amt, tot_cur_bal, open_acc_6m, open_act_il, open_il_12m, open_il_24m, mths_since_rcnt_il, total_bal_il, il_util, open_rv_12m, open_rv_24m, max_bal_bc, all_util, total_rev_hi_lim, inq_fi, total_cu_tl, inq_last_12m, acc_open_past_24mths, avg_cur_bal, bc_open_to_buy, bc_util, chargeoff_within_12_mths, delinq_amnt, mo_sin_old_il_acct, mo_sin_old_rev_tl_op, mo_sin_rcnt_rev_tl_op, mo_sin_rcnt_tl, mort_acc, mths_since_recent_bc, mths_since_recent_bc_dlq, mths_since_recent_inq, mths_since_recent_revol_delinq, num_accts_ever_120_pd, num_actv_bc_tl, num_actv_rev_tl, num_bc_sats, num_bc_tl, num_il_tl, num_op_rev_tl, num_rev_accts, num_rev_tl_bal_gt_0, num_sats, num_tl_120dpd_2m, num_tl_30dpd, num_tl_90g_dpd_24m, num_tl_op_past_12m, pct_tl_nvr_dlq, percent_bc_gt_75, pub_rec_bankruptcies, tax_liens, tot_hi_cred_lim, total_bal_ex_mort, total_bc_limit, total_il_high_credit_limit, revol_bal_joint, sec_app_earliest_cr_line, sec_app_inq_last_6mths, sec_app_mort_acc, sec_app_open_acc, sec_app_revol_util, sec_app_open_act_il, sec_app_num_rev_accts, sec_app_chargeoff_within_12_mths, sec_app_collections_12_mths_ex_med, sec_app_mths_since_last_major_derog, hardship_flag, hardship_type, hardship_reason, hardship_status, deferral_term, hardship_amount, hardship_start_date, hardship_end_date, payment_plan_start_date, hardship_length, hardship_dpd, hardship_loan_status, orig_projected_additional_accrued_interest, hardship_payoff_balance_amount, hardship_last_payment_amount, disbursement_method, debt_settlement_flag, debt_settlement_flag_date, settlement_status, settlement_date, settlement_amount, settlement_percentage, settlement_term )
    ;
