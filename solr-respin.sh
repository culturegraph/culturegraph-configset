#!/bin/bash
# Desc: A script that automates the modification of a vanilla solr release

#
# Settings
# Change those, if needed
#

SOLR_VERSION="7.5.0"
METAFACTURE_VERSION="5.0.0"
MYSQL_CONNECTOR_VERSION="8.0.12"

#
# Settings End
#

SOLR="solr-${SOLR_VERSION}"
TARGET=${SOLR}-culturegraph-respin.zip

#
# Welcome
#

echo "SOLR CULTUREGRAPH RESPIN"
echo "------------------------"

#
# Check required commands
#

if [! which realpath 2> /dev/null ]; then echo "Command 'realpath' not found" && exit 1; fi
if [! which sed 2> /dev/null ]; then echo "Command 'sed' not found" && exit 1; fi
if [! which wget 2> /dev/null ]; then echo "Command 'wget' not found" && exit 1; fi
if [! which unzip 2> /dev/null ]; then echo "Command 'unzip' not found" && exit 1; fi
if [! which zip 2> /dev/null ]; then echo "Command 'zip' not found" && exit 1; fi

#
# Prepare solr release archive
#

if [ -f ${TARGET} ]; then
echo "Removing previous target!"
rm ${TARGET}
fi

if [ -d ${SOLR} ]; then
echo "Removing previous solr directory!"
rm -rf ${SOLR}
fi

if [ ! -f ${SOLR}.zip ]; then
echo "Downloading solr release ${SOLR_VERSION}"
url="http://ftp.halifax.rwth-aachen.de/apache/lucene/solr/${SOLR_VERSION}/${SOLR}.zip"

echo "Url: ${url}"
wget -q ${url}
fi

if [ ! -f ${SOLR}.zip ];
then echo "Solr release not found!" && exit 1;
fi

echo "Unzipping archive"
unzip -q ${SOLR}.zip
echo "Removing zip file"
rm ${SOLR}.zip


#
# Add and modify config set
#

echo "Copying config set"
if [ ! -d configsets/culturegraph ]; then
echo "Config set not found!" && exit 1
fi
cp -a configsets/culturegraph ${SOLR}/server/solr/configsets

solr=$(realpath ${SOLR})
solrconfig=${solr}/server/solr/configsets/culturegraph/conf/solrconfig.xml

# Backup vanilla solrconfig.xml
echo "Creating backup of vanilla solrconfig.xml"
cp ${solrconfig} ${solrconfig}.bak

echo "Adding libs to solrconfig.xml"
# Add plugin jars
# NOTE: We need to mask $ with \$ to please sed
cat <<-EOF > snippet.txt
  <lib dir="\${solr.install.dir:../../../..}/dist/" regex="solr-dataimporthandler-.*\.jar" />
  <!-- MySQL -->
  <lib dir="\${solr.install.dir:../../../..}/lib/mysql" regex="mysql-connector-java-.*\.jar" />
  <!-- Metafacture -->
  <lib dir="\${solr.install.dir:../../../..}/lib/metafacture" regex="metafacture-.*\.jar" />
  <!-- Data Import Handler Add-Ons -->
  <lib dir="\${solr.install.dir:../../../..}/lib/dataimporthandler" regex="solr-metamorph-transformer-.*\.jar" />
  <lib dir="\${solr.install.dir:../../../..}/lib/dataimporthandler" regex="solr-metamorph-entity-processor-.*\.jar" />
EOF
sed -i '/<!-- Data Directory/i <!-- ADDED LIBS -->' ${solrconfig}
sed -i '/<!-- ADDED LIBS -->/r snippet.txt' ${solrconfig}

echo "Adding request handler to solrconfig.xml"
# Add data import request handler
cat <<-EOF > snippet.txt
  <requestHandler name="/dataimport" class="solr.DataImportHandler">
    <lst name="defaults">
      <str name="config">solr-data-config.xml</str>
    </lst>
  </requestHandler>
EOF
sed -i '/<!-- Request Handlers/i <!-- ADDED REQUEST HANDLERS -->' ${solrconfig}
sed -i '/<!-- ADDED REQUEST HANDLERS -->/r snippet.txt' ${solrconfig}

# Remove temporay file
rm snippet.txt


#
# Modify solr server
#

# Add MySQL Connector to solr server (into: lib/mysql)
echo "Adding MySQL Connector ${MYSQL_CONNECTOR_VERSION}"
repo="http://central.maven.org/maven2/mysql/mysql-connector-java"

mkdir -p $(realpath ${SOLR})/lib/mysql
wget -q -P $(realpath ${SOLR})/lib/mysql ${repo}/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
[ ! $? ] && echo "MySQL Connector ${MYSQL_CONNECTOR_VERSION} not found!" && exit 1

# Add third party add-ons for the data import handler (into: lib/dataimporthandler)
echo "Adding third-party jars (data import handler add-ons)"

mkdir -p $(realpath ${SOLR})/lib/dataimporthandler

wget -q -P $(realpath ${SOLR})/lib/dataimporthandler https://github.com/culturegraph/solr-metamorph-transformer/releases/download/v0.2.0/solr-metamorph-transformer-0.2.0-fat.jar
[ ! $? ] && echo "solr-metamorph-transformer-0.2.0-fat.jar not found!" && exit 1

wget -q -P $(realpath ${SOLR})/lib/dataimporthandler https://github.com/culturegraph/solr-metamorph-entity-processor/releases/download/v0.4.0/solr-metamorph-entity-processor-0.4.0-fat.jar
[ ! $? ] && echo "solr-metamorph-entity-processor-0.4.0-fat.jar not found!" && exit 1

# Adding metafacture (into: lib/metafacture and WEB-INF/lib)
echo "Adding third-party jars (metafacture)"

repo="http://central.maven.org/maven2/org/metafacture"
modules="metafacture-biblio metafacture-commons metafacture-flowcontrol metafacture-framework metafacture-io metafacture-mangling metamorph metamorph-api"
for module in $modules; do
  wget -q -P $(realpath ${SOLR})/lib/metafacture ${repo}/${module}/${METAFACTURE_VERSION}/${module}-${METAFACTURE_VERSION}.jar
done

cp $(realpath ${SOLR})/lib/metafacture/*.jar $(realpath ${SOLR})/server/solr-webapp/webapp/WEB-INF/lib

#
# Create new zip archive
#

echo "Creating archive ${TARGET}"
zip -q -r ${TARGET} ${SOLR}
echo "Removing solr directory"
rm -rf ${SOLR}

if [ ! -f ${TARGET} ]; then
echo "Final archive not found!" && exit 1;
else
echo "Done"
fi

