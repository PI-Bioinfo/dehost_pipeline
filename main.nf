#!/usr/bin/env nextflow 

nextflow.enable.dsl=2

params.sra_accessions_file = 'accessions.txt' // Make sure this file exists!  

process retrieve_sra {  
    input:  
    path sra_accessions_file  

    output:  
    path 'data/*_1.fastq', emit: paired1  
    path 'data/*_2.fastq', emit: paired2  

    script:  
    """  
    # Create output directory if not exists  
    mkdir -p data  

    # Read each accession from the file and download using fastq-dump  
    while read accession; do  
        fastq-dump --split-files --outdir data \$accession  
    done < ${sra_accessions_file}  
    """  
}  

workflow {  
    retrieve_sra()  
}  