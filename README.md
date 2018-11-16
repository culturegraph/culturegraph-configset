# CultureGraph Config Set

- [CultureGraph Config Set](#culturegraph-config-set)
  * [Quickstart](#quickstart)
  * [Data Import](#data-import)
    + [Configure JDBC](#configure-jdbc)
  * [Installation](#installation)
    + [Modify solrconfig.xml](#modify-solrconfigxml)
    + [Install Add-ons](#install-add-ons)
    + [Install MySQL Connector](#install-mysql-connector)
  * [Automatic Installation](#automatic-installation)
    + [Configuration](#configuration)

The Apache Solr configuration for Culturegraph.

## Quickstart

```
# Start solr with 1GB Memory on Port 8983 and be verbose
solr start -m 1g -p 8983 -V

# Create core test with culturegraph config set
solr create_core -c test -d culturegraph -p 8983 -V

# Configure the data import handler for the core
cd solr/test/conf
nano solr-data-config.xml
# Change jdbc configuration, if required

# Data Import
# NOTE: Consult the logs, when a command is not working.

# Retrieve current status
curl -s http://localhost:8983/solr/test/dataimport?command=status

# Abort current action
# curl -s http://localhost:8983/solr/test/dataimport?command=abort

# Full-Import MARCXML from D:\data\marcxml
curl -s http://localhost:8983/solr/test/dataimport?command=full-import&entity=FileSystemFolder&dataDir=D:\data\marcxml&format=marcxml

# Full-Import Marc21 from database
# curl -s http://localhost:8983/solr/test/dataimport?command=full-import&entity=Marc21Database

# Commit
curl -s http://localhost:8983/solr/test/update?commit=true

# Stop solr
solr stop -all
```

## Data Import

_NOTE:_
 * It is recommended to use the [Solr Admin UI](https://lucene.apache.org/solr/guide/7_5/overview-of-the-solr-admin-ui.html)
    * Select your core and go to _Dataimport_
    * Be aware that API calls are also possible (see [quickstart](#quickstart))
 * Solr's Import Handler has various [commands](https://lucene.apache.org/solr/guide/7_5/uploading-structured-data-store-data-with-the-data-import-handler.html#dataimporthandler-commands) your may use to control the import procedure.

There are the following two ways to import data with _this_ config set.

**FileSystemFolder**

You may import your records (Marc21 or MARCXML) from a custom location.

If you run a request with `entity=FileSystemFolder` you need to set the following
request parameters (see also: [DIH Request Parameters](https://lucene.apache.org/solr/guide/6_6/uploading-structured-data-store-data-with-the-data-import-handler.html#dih-request-parameters)):

| Parameter | Description | Example |
| --------- | ----------- | ------- |
| dataDir | Folder location. | D:\data\marcxml |
| format | File format. Choose _marc21_ or _marcxml_. | |

**Marc21Database**

If you run a request with `entity=Marc21Database`, you need a working JDBC configuration in your `solr-data-config.xml`.
Inspect the following section ([Configure JDBC](#configure-jdbc)) for further details.

The database needs at least the following columns:

| Column | Type | Description |
| ------ | ---- | ----------- |
| id | String | Record identifer. Format: ([ISIL](http://sigel.staatsbibliothek-berlin.de/vergabe/isil/))IDN . |
| update_time | Timestamp | Insertion or update date for a record (UTC). |
| full_record | String | A bibliographic record formatted as [MARC21](https://www.loc.gov/marc/96principl.html). |

### Configure JDBC

**IMPORTANT**: This step is mandatory, otherwise the Data Import Handler won't work with your MySQL Database.

Change the [JDBC Data Source](https://lucene.apache.org/solr/guide/7_5/uploading-structured-data-store-data-with-the-data-import-handler.html#jdbcdatasource) in `solr-data-config.xml`.
The values in the provided jdbc data source element are only for demonstration purpose.

## Installation

It is advised to use the [Automatic Installation](#automatic-installation).

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

* https://github.com/culturegraph/solr-morph-transformer
* https://github.com/culturegraph/solr-metamorph-entity-processor

Add libraries to `solrconfig.xml`

```
<lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-morph-transformer-.*\.jar" />
<lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-metamorph-entity-processor-.*\.jar" />
```

### Install MySQL Connector

Place the required [MySQL Connector/J](https://mvnrepository.com/artifact/mysql/mysql-connector-java) JAR in the `solr/server/lib` directory.

## Automatic Installation

The `solr-respin.sh` script modifies a Apache Solr release by doing the following:

* Download Solr release
* Add MySQL Connector
* Add the culturegraph config set
* Add the required add-ons (and dependencies)
* Modify the `sorlconfig.xml`
  * Add data import request handler
  * Include libraries for the required add-ons


Run it with:

```
bash solr-respin.sh
```

### Configuration

The header section of the script contains the following changeable parameters:

| Parameter | Description |
| --------- | ----------- |
| SOLR_VERSION | Version of the [Apache Solr](http://lucene.apache.org/solr/) distribution |
| METAFACTURE_VERSION | Version of the [Metafacture](https://github.com/metafacture/metafacture-core) distribution. |
| MYSQL_CONNECTOR_VERSION | Version of the used [MySQL Connector](https://mvnrepository.com/artifact/mysql/mysql-connector-java).