#!/usr/bin/env nextflow 

nextflow.enable.dsl=2

params.sra_accessions = 'SRR30723710'

process retrieve_sra  {
    input:
    val sra_accessions

    output:
    path 'data/*.fastq'

    script:
    """
    mkdir -p data  # Create output directory if it doesn't exist  

    # Download SRA data using fastq-dump 
    fastq-dump --outdir data ${sra_accessions}
    """
}

workflow {  
    // Call the retrieve_sra process with the specified SRA accession  
    retrieve_sra(params.sra_accessions)  
}  




