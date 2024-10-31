#!/usr/bin/env nextflow   

nextflow.enable.dsl=2  

params.sra_accessions_file = 'SRR_Acc_List.txt'  

process retrieve_sra {  
    input:  
    val sra_accession  // Input parameter for a single SRA accession  

    output:  
    path "data/${sra_accession}*.fastq" // Output path for downloaded FASTQ files  

    errorStrategy 'retry' // Continue to the next accession on error  

    script:  
    """  
    mkdir -p data  # Create output directory if it doesn't exist  

    # Download SRA data using fastq-dump  
    if ! fastq-dump --split-files --outdir data ${sra_accession}; then  
        echo "Error downloading ${sra_accession}" >&2  
        exit 1  
    fi  

    # Wait for 10 seconds before the next download  
    sleep 10  
    """  
}  

workflow {  
    Channel.fromPath(params.sra_accessions_file)  
        .flatMap { file -> file.text.readLines() }  
        .map { line -> line.trim() }  
        .filter { it } // Ensures only non-empty lines are processed  
        .set { accessions }  

    // Call the retrieve_sra process with each SRA accession  
    accessions | retrieve_sra   
}

