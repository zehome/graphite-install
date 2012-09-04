#!/bin/bash

default_venv="$PWD/local"

echo "Automatic graphite install"

echo -n "Proceed install ? [y] "
read yesno

if [ "$yesno" != "Y" ] && [ "$yesno" != "y" ] && [ ! -z "$yesno" ]; then
    exit 0
fi

# Check dependencies
to_install=""
for dep in libsqlite3-dev sqlite3 python-cairo libmemcached-dev memcached \
           rrdtool librrd-dev fontconfig ttf-dejavu; do
    dpkg -l | grep ${dep} &>/dev/null
    if [ "$?" != "0" ]; then
        to_install="$to_install $dep"
    fi
done

if [ ! -z "${to_install}" ]; then
    echo "Missing dependencies: ${to_install}. Trying to install..."
    sudo apt-get install ${to_install}
fi

echo -n "where to install virtualenv ? [${default_venv}] "
read venvdir
if [ -z "$venvdir" ]; then
    venvdir=${default_venv}
fi

if [ -d "$venvdir" ]; then
    echo "${venvdir} already exists."
    # TODO
    #exit 0
fi

echo "Creating virtualenv in ${venvdir}..."
virtualenv --system-site-packages $venvdir

echo "Sourcing virtualenv..."
source $venvdir/bin/activate

echo "Install basic requirements..."
pip install -r requirements.txt

echo "Install whisper..."
pip install whisper

echo "Install carbon..."
# TODO: UGGLY REFERENCE TO PYTHON VERSION!
pip install carbon \
    --install-option="--prefix=${venvdir}/graphite" \
    --install-option="--install-scripts=${venvdir}/bin" \
    --install-option="--install-lib=${venvdir}/lib/python2.7/site-packages"

# TODO: UGGLY REFERENCE TO PYTHON VERSION!
echo "Install graphite-web..."
pip install graphite-web \
    --install-option="--prefix=${venvdir}/graphite" \
    --install-option="--install-scripts=${venvdir}/bin" \
    --install-option="--install-lib=${venvdir}/lib/python2.7/site-packages"
echo "Link graphite-web webapp to ${venvdir}/graphite/webapp"
ln -s ${venvdir}/lib/python2.7/site-packages/graphite ${venvdir}/graphite/webapp

echo "Install basic configiration..."
sed -e "s,%%GRAPHITE%%,${venvdir}/graphite," conf/carbon.conf.template > ${venvdir}/graphite/conf/carbon.conf
cp -a conf/storage-schemas.conf ${venvdir}/graphite/conf/
