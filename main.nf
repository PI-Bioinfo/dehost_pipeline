#!/usr/bin/env nextflow   

nextflow.enable.dsl=2  

params.sra_accessions_file = 'SRR_Acc_List.txt'  
params.genome_ref = 'https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.gz'  
params.validated_sample = 'validated_samples'  // Define the validated samples directory  

process retrieve_sra {  
    input:  
    val sra_accession  // Input parameter for a single SRA accession  

    output:
    // path "data/${sra_accession}*.fastq", emit: sample_files  // Emits the FASTQ files with just the path
    tuple val(sra_accession), path("data/${sra_accession}*.fastq") , emit: sample_files 

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
    // path sample_files // Input path for sample files  
    tuple val(sra_accession), path(sample_files)

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

// process align_reads {  
//     input:  
//     tuple val(sra_accession), path(fastq_files), path(host_genome_index) // Correct syntax  

//     output:  
//     tuple val(sra_accession), path("${sra_accession}_aligned.bam")  

//     script:  
//     """  
//     bowtie2 -x ${host_genome_index}/host_genome -1 ${fastq_files[0]} -2 ${fastq_files[1]} | samtools view -bS - > ${sra_accession}_aligned.bam  
//     """  
// }

process align_reads {
    input:
    tuple val(sra_accession), path(fastq_files), path(host_genome_index) // Correct input tuple format

    output:
    tuple val(sra_accession), path("${sra_accession}_aligned.bam") // Output BAM file with sra_accession label

    script:
    """
    bowtie2 -x ${host_genome_index}/host_genome \
        -1 ${fastq_files[0]} -2 ${fastq_files[1]} | samtools view -bS - > ${sra_accession}_aligned.bam
    """
}


// workflow {  
//     // Load the SRA accessions from the specified file  
//     Channel.fromPath(params.sra_accessions_file)  
//         .flatMap { file -> file.text.readLines() }  
//         .map { line -> line.trim() }  
//         .filter { it } // Ensures only non-empty lines are processed  
//         .set { accessions }  
   

//     sra_data = accessions | retrieve_sra

    
//     // Call the retrieve_sra process with each SRA accession  
//     validated_samples = sra_data | receive_samples // work


//     // Store the result of receive_host  
//     host_info_channel = receive_host(params.genome_ref)  
//     host_index = host_info_channel | prepare_host_genome   
    
//     // Alignment
//     sra_data_for_alignment = accessions.combine(sra_data)  
//     aligned_data = sra_data_for_alignment.combine(host_index) | align_reads //work

// }

workflow {
    // Load the SRA accessions from the specified file
    Channel.fromPath(params.sra_accessions_file)
        .flatMap { file -> file.text.readLines() }
        .map { line -> line.trim() }
        .filter { it } // Ensures only non-empty lines are processed
        .set { accessions }

    // Run SRA retrieval and emit tuples with (sra_accession, fastq_files)
    sra_data = accessions | retrieve_sra

    // Validate samples from retrieved SRA data
    validated_samples = sra_data | receive_samples

    // Prepare host genome
    host_info_channel = receive_host(params.genome_ref)
    host_index = host_info_channel | prepare_host_genome

    // Combine sra_data and host_index channels for alignment
    aligned_data = sra_data.combine(host_index) | align_reads
}
