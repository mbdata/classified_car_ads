# Loading the 'Classified Ads for Cars' Dataset and Copying it to Hortonworks VM

The dataset I am using is found on Kaggle, the popular Machine Learning Competition website:

https://www.kaggle.com/mirosval/personal-cars-classifieds/

I am using a commerical distribution of Hadoop, Hortonworks HDP Sandbox, for this project. First, I need to log in to the Hortonworks VM from Git Bash on my local server and create a folder for this project:

```bash
ssh maria_dev@192.168.1.20 -p 2222
cd used-cars-mb/
exit
```
This creates a folder called used-cars-mb, where I will store my hive queries and their results.

From the Git bash console, copy the Classified Ads for Cars file to the Hortonworks VM:

```bash
scp -P 2222 classified-ads-for-cars.zip maria_dev@192.168.1.20:/home/maria_dev/used-cars-mb
```

Log in to the VM, unzip the file and count the number of lines in the created file (should be about 3.5MB):

```bash
ssh maria_dev@192.168.1.20 -p 2222
cd used-cars-mb/
gzip -d --suffix=.zip *.*
wc -l classified-ads-for-cars
```

Copy the first line of the file to a 'headers' file, so that we can store the headers for later use in analysis of the data

```bash
 head -1 classified-ads-for-cars > headers
```

Split the file into 50 chunks and remove the headers line from the first file:

```bash
mkdir chunks
cd chunks
split --number=l/50 ../classified-ads-for-cars classified-ads-for-cars_
sed -i 1d classified-ads-for-cars_aa
```

Now that the data is loaded onto the Hortonworks VM, I will proceed to copy the files to the HDFS.

# Copy the files to HDFS: 

I created a directory in hadoop called cars_mb/ads by using the following command: 
   
 ```bash
 hdfs dfs -mkdir -p  cars_mb/ads
 ```

You can now copy the event files you downloaded earlier to the hdfs directory you just created by running the commands below. These commands will print the name of each file (to see the progress), then load the file to the HDFS, and finally move the processed files to the folder ../loaded-files:
 
```bash
mkdir ../loaded-files
for file in *; do echo $file;  hdfs dfs -put $file cars_mb/ads/; mv $file -f ../loaded-files; done
```

To check how many unloaded files remain, run the following command from another(!) bash window:

```bash
ls events/ | wc -l
```

List the files copied to hadoop by running the following command: 

```bash
hdfs dfs -ls cars_mb/ads/
```

Remove the chunks

```bash
cd ..
rm -r -f chunks
rm -f loaded-files/*
rm -r -f loaded-files
```

The data is now loaded onto the Hadoop HDFS. Our next step is to use Hive to query the data and get the output ready for analysis on the local computer.
