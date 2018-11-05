
git = function(git_name, git_email, commit_message) {

  cmd = paste0(
  'commit_message="', commit_message, '"
  git config --global user.name "', git_name, '"
  git config --global user.email "', git_email, '"
  git add --all
  echo "', commit_message, '" | git commit -F -
  git push -u origin --all
  ')

  system(cmd)

  msg('Code checked in successfully.')

} # end git function
