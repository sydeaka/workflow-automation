commit_message="Analysis of ${year} Q${quarter} Lending Club dataset"
git config --global user.name "${Gmail_name_from}"
git config --global user.email "${Gmail_address_from}"
git add --all
echo "${commit_message}" | git commit -F -
git push -u origin --all