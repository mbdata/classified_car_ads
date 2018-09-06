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
Note that it is a requirement to prefix the table name 'events' with the name of the database in which we want the table schema to be located. In this case, we type 'used_cars_mb.events'. After specifying the field names and their data types, we need to ensure that the table has a reference to the location of our data in HDFS, which here is the full path '/user/maria_dev/cars_mb/ads'. Additionally, and particular to this dataset, the two fields we are storing as timestamps (date_created, date_last_seen) are not in the default SQL way (yyyy-mm-dd hh:mm:ss); to prevent an error, we will alter the table to recognize the extension to the timestamps using the ALTER TABLE command above. Finally, we output the table structure onto the command line.

## Querying Data from the 'events' Table and Storing the Output in HDFS
As our table is now created, we need to extract the data and store the output in a new folder in HDFS.

In HDFS, create a new folder inside our main project folder, and call it query_results:
```bash
hdfs dfs -mkdir -p cars_mb/query_results
```

Go to the hive folder, and create a new textfile:
```bash
vi output_1
```

Enter the following query,
```SQL
USE used_cars_mb;

insert overwrite directory 'cars_mb/query_results/'
row format delimited
fields terminated by '\t'
stored as textfile
select * from events
where rand(123) < (30000/3552912);
```
and run it:
```bash
hive -f output_1
```
This will query the data to select all rows and fields from the table, and it will return approximately 30,000 rows that we will use as a sample for analysis. The output will be stored in our HDFS folder 'query_results'.

Go to the 'query_results' folder to make sure that the output has indeed been stored:
```bash
hdfs dfs -ls cars_mb/query_results/
```

## Copy the Output Results to the Local Computer
In my case, the output results were split into 25 files, each named like 000000_0, 000000_1,..., 000000_25. We would like to have the data as one file, however, so we will need to concatenate them. First, let's copy the data over to our local computer.

Create a new folder in our main project directory, used-cars-mb:
```bash
mkdir results
```

Inside the 'results' folder, copy the output over from HDFS:
```bash
hdfs dfs -copyToLocal cars_mb/query_results/* ./
```
You should be able to see all 25 (or however many) files now on your local computer.

Now let's run a bash command to concatenate them. Inside the 'results' folder:
```bash
cat $(ls) > outputfile_1
```
The concatenated file is created, but we still need to delete all of the original files:
```bash
rm -f 000000*
```
We are left with a single file, 'outputfile_1', that we can now import into data analysis software, such as R.
