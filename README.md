# CultureGraph Config Set

  * [Quickstart](#quickstart)
  * [Configure](#configure)
  * [Installation](#installation)
    + [Modify solrconfig.xml](#modify-solrconfigxml)
    + [Install Add-ons](#install-add-ons)
  * [Automatic Installation](#automatic-installation)

The Apache Solr configuration for Culturegraph.

## Quickstart

```
# Start solr with 1GB Memory on Port 1111 and be verbose
solr start -m 1g -p 1111 -V

# Create core test with culturegraph config set
solr create_core -c test -d culturegraph -p 1111 -V

# Configure the data import handler for the core
cd solr/CORE/conf
nano solr-data-config.xml
# Change fileName, baseDir or jdbc

# Stop solr
solr stop -all
```

## Configure

Change the locations or data sources in `solr-data-config.xml`.

## Installation

**NOTE**: The config set contains a vanilla `solrconfig.xml` that needs to be modified.

### Modify solrconfig.xml

Add a */dataimport* request handler to `solrconfig.xml` (Location: `configsets/culturegraph`)

```
<lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-dataimporthandler-.*\.jar" />
```

```
<requestHandler name="/dataimport" class="solr.DataImportHandler">
  <lst name="defaults">
    <str name="config">solr-data-config.xml</str>
  </lst>
</requestHandler>
```

### Install Add-ons

Install the following add-ons:

* https://github.com/culturegraph/solr-hashcode-transformer
* https://github.com/culturegraph/solr-morph-transformer
* https://github.com/culturegraph/solr-metamorph-entity-processor

Add libraries to `solrconfig.xml`

```
<lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-hashcode-transformer-.*\.jar" />
<lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-morph-transformer-.*\.jar" />
<lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-metamorph-entity-processor-.*\.jar" />
```

## Automatic Installation

The `solr-respin.sh` script modifies a Apache Solr release by doing the following:

* Download Solr release
* Add the culturegraph config set
* Add the required add-ons (and dependencies)
* Modify the `sorlconfig.xml`
  * Add data import request handler
  * Include libraries for the required add-ons


Run it with:

```
bash solr-respin.sh
```