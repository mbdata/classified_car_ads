# Querying the Data Using Hive
Now that the classified ads data is loaded onto Hadoop, I will proceed to write Hive queries in order to create a database to store table schemas, create a table from which the data can be extracted, and output the results to HDFS, followed by copying the results to the local computer for analysis.

## Create a Database in Hive
Hive is a data warehouse that runs on top of Hadoop. It uses an SQL-like query language called HQL that we use to query data stored in a Hadoop cluster. We need first to create a database so that we can store table schemas.

Inside our main project folder, used-cars-mb, create a new directory called 'hive' for storing queries:
```bash
mkdir hive
```
Inside the hive folder, use the vi text editor to create an HQL textfile that will be used to initialize the database:
```bash
vi create-db.hql
```
Once inside the textfile, write the following query:
```SQL
CREATE DATABASE
    IF NOT EXISTS used_cars_mb
    COMMENT 'This is the used cars classified ads database'
    With dbproperties ('Created by' = 'mbaranov','Created on' = 'September-2018');

SHOW DATABASES;
```
Now, the database is created and Hive will display its name on the command line.

## Create a Table Using Hive
The next step is to create a table with Hive, called 'events', that we will use for querying the data. An interesting detail about Hive is that it stores a table only as a schema, or structure of a table (i.e. field names and data types). To extract data from the table, we refer to the table schema and point it to the HDFS location of the data we are using.

Inside the hive folder, create another textfile, named 'create-table.hql':
```bash
vi create-table.hql
```
Enter the following query:
```SQL
CREATE EXTERNAL TABLE IF NOT EXISTS used_cars_mb.events (
maker STRING,
model STRING,
mileage INT,
manufacture_year INT,
engine_displacement INT,
engine_power INT,
body_type STRING,
color_slug STRING,
stk_year STRING,
transmission STRING,
door_count INT,
seat_count INT,
fuel_type STRING,
date_created TIMESTAMP,
date_last_seen TIMESTAMP,
price_eur DECIMAL(13,2))
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/maria_dev/cars_mb/ads';

ALTER TABLE used_cars_mb.events SET SERDEPROPERTIES ("timestamp.formats"="yyyy-MM-dd HH:mm:ss.SSSSSSZ");

DESCRIBE used_cars_mb.events;
```
