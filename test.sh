runner() {
  echo "Running \`$*\`"
  echo "\`\`\`"
  bash -c "$*"
  echo "\`\`\`"
}

runner \
  sed -i -e 's/\ \(stable\|wheezy\|jessie\)/\ testing/g' /etc/apt/sources.list
