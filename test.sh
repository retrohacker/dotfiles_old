USERNAME=$(who am i | awk '{print $1}')
HOMEDIR=$(eval echo ~$USERNAME)
echo $HOMEDIR
