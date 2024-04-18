#!/bin/bash

kohaplugindir="$(grep -Po '(?<=<pluginsdir>).*?(?=</pluginsdir>)' $KOHA_CONF)"
kohadir="$(grep -Po '(?<=<intranetdir>).*?(?=</intranetdir>)' $KOHA_CONF)"

rm -r $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/AutoFrameworkCode
rm $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/AutoFrameworkCode.pm

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ln -s "$SCRIPT_DIR/Koha/Plugin/Fi/KohaSuomi/AutoFrameworkCode" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/AutoFrameworkCode
ln -s "$SCRIPT_DIR/Koha/Plugin/Fi/KohaSuomi/AutoFrameworkCode.pm" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/AutoFrameworkCode.pm

perl $kohadir/misc/devel/install_plugins.pl

