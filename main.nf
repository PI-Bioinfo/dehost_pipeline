#!/usr/bin/env nextflow 

nextflow.enable.dsl=2

params.sra_accessions = 'SRX26126976'

process retrieve_sra  {
    input:
    val sra_accessions

    output:
    path 'data/*.fastq'

    script:
    """
    # Load SRA Toolkit 
    module load sratoolkit 

    # Download SRA data using fastq-dump 
    fastq-dump --split-files --outdir data ${sra_accessions}
    """
}


process receive_samples { 
    input: 
    path sample_files

    output: 
    path 'confirmed_samples/*'

    script:
    """
    # Validate script
    """
}

workflow {
    // Fetch and process SRA data 
    sra_data = retrieve_sra(params.sra_accessions)

    // Continue with the existing process 
    validated_samples = receive_samples(sra_data)
}


# this is a test