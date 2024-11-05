#!/usr/bin/env nextflow   

nextflow.enable.dsl=2  

params.sra_accessions_file = 'SRR_Acc_List.txt'  
params.genome_ref = 'https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.gz'  
params.validated_sample = 'validated_samples'  // Define the validated samples directory  

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

process receive_samples {  
    input:  
    path sample_files // Input path for sample files  

    output:  
    path 'validated_samples/*' // Corrected quotation marks  

    script:  
    """  
    # Create output directory if it doesn't exist  
    mkdir -p validated_samples  

    # Example validation script (e.g., checksum verification)  
    for file in ${sample_files}; do  
        # Perform checksum verification (e.g., md5sum)  
        checksum=\$(md5sum "\$file" | awk '{ print \$1 }')  
        echo "Validating \$file: checksum is \$checksum"  

        # Here you can add logic to compare the checksum with expected values  
        # For example, if you have a checksum file:  
        # if ! grep -q "\$checksum" expected_checksums.txt; then  
        #     echo "Checksum validation failed for \$file" >&2  
        #     exit 1  
        # fi  

        # If validation passes, copy the file to the output directory  
        cp "\$file" validated_samples/  
    done  
    """  
}

process receive_host {  
    input:  
    path host_file  

    output:   
    path 'host_info'  

    script:   
    """  
    # Download human genome  
    wget ${params.genome_ref} -O host_info.gz  
    # Decompress the downloaded file  
    gunzip host_info.gz  
    """  
} 

process prepare_host_genome {  
    input:  
    path host_genome_file // Accept the downloaded genome file as input  

    output:  
    path 'host_genome_index'  

    script:  
    """  
    mkdir -p host_genome_index  
    bowtie2-build ${host_genome_file} host_genome_index/host_genome  
    """  


}



workflow {  
    // Load the SRA accessions from the specified file  
    Channel.fromPath(params.sra_accessions_file)  
        .flatMap { file -> file.text.readLines() }  
        .map { line -> line.trim() }  
        .filter { it } // Ensures only non-empty lines are processed  
        .set { accessions }  

    // Call the retrieve_sra process with each SRA accession  
    accessions | retrieve_sra   

    // Connect the output of retrieve_sra to receive_samples  
    retrieve_sra.out | receive_samples  

    // Store the result of receive_host  
    host_info_channel = receive_host(params.genome_ref)  
    host_info_channel | prepare_host_genome   
    
    
}



