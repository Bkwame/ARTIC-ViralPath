#!/bin/bash

set -e

# Paths to directories for the pipeline
inputData=/home/username/Desktop/20230921_SARS_COV_2_TRAINING/fastq_pass_1
outputData=/home/username/Desktop/20230921_SARS_COV_2_TRAINING/fastq_pass_1
primerSchemes=/home/username/fieldbioinformatics/test-data/primer-schemes
primerScheme=Midnight-ONT/V3

# Amplicon lengths (according to primer scheme used)
minLength=200
maxLength=1200

# Processing power to be used
threads=4

# Samplesheet path
samplesheet=$inputData/samplesheet.csv

# Read the samplesheet and process each sample (into the while loop)
while IFS=, read -r sample_id barcode
do
    # Ensuring that barcode is two digits
    barcode=$(printf "%02d" ${barcode})

    # Calling out the sample name and barcode
    echo "Processing sample: ${sample_id} with barcode: ${barcode}"
    
    # Create necessary directories if they don't exist
    mkdir -p ${outputData}/barcode${barcode}/${sample_id}

    # Move into the output folder
    cd ${outputData}/barcode${barcode}/${sample_id}

    # Run Artic commands    
    artic gather --min-length $minLength --max-length $maxLength --prefix ${sample_id} --directory ${inputData}/barcode${barcode} --no-fast5s

    artic demultiplex --threads ${threads} ${inputData}/barcode${barcode}/${sample_id}/${sample_id}_barcode${barcode}.fastq
    
    artic guppyplex --min-length $minLength --max-length $maxLength --prefix ${sample_id} --directory ${outputData}/barcode${barcode}/${sample_id} --output ${outputData}/barcode${barcode}/${sample_id}/${sample_id}_guppyplex_fastq_pass-barcode${barcode}.fastq

    artic minion --normalise 200 --threads ${threads} --scheme-directory ${primerSchemes} --read-file ${outputData}/barcode${barcode}/${sample_id}/${sample_id}_guppyplex_fastq_pass-barcode${barcode}.fastq --medaka --medaka-model r941_min_high_g360 ${primerScheme} ${sample_id}

    # Move back out into the parent directory
    cd ..
    
done < <(tail -n +2 ${samplesheet})  # Skipping the header row

