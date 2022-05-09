#!/bin/bash -eu


filepath=$(pwd)
firstthree=${filepath:1:3}

if [ "$firstthree" == var ]; then
   currentbranch=$BRANCH_NAME
else
   currentbranch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
fi


cd ../../
DIR="ansible-conjur-collection/tests/output"
if [ -d "$DIR" ]; then
   echo "Existing '$DIR' found"
   rm -rf ansible-conjur-collection/tests/output
else
   echo "'$DIR' NOT found. "
fi

mkdir -p ansible_collections/cyberark/
cd ansible_collections/cyberark/
git clone --single-branch --branch "$currentbranch" https://github.com/cyberark/ansible-conjur-collection.git
mv ansible-conjur-collection conjur
cd conjur

# pip install pycairo
export PATH=/var/lib/jenkins/.local/bin:$PATH
pip install https://github.com/ansible/ansible/archive/devel.tar.gz --disable-pip-version-check
ansible-test units --docker default -v --python 3.8 tests/unit/plugins/lookup/test_conjur_variable.py --coverage
ansible-test coverage html -v --requirements --group-by command --group-by version
cd ../../../

CURRENTDIR="workspace"
if [ -d "$CURRENTDIR" ]; then
   rootdir="_-ansible-conjur-collection_"
   Combinedstring=$rootdir$currentbranch
   get32characters=${Combinedstring: -32}
   cp -r ansible_collections/cyberark/conjur/tests/output workspace/"$get32characters"/tests
else
   cp -r ansible_collections/cyberark/conjur/tests/output ansible-conjur-collection/tests
fi

rm -rf ansible_collections
