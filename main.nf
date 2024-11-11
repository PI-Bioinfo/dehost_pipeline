#!/usr/bin/env nextflow   

nextflow.enable.dsl=2  

params.sra_accessions_file = 'SRR_Acc_List.txt'  
params.genome_ref = 'https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.gz'  
params.validated_sample = 'validated_samples'  

// Most of the process need resource allocation 
//    memory '4 GB'
//    cpus 2

process retrieve_sra {  
    input:  
    val sra_accession  // Input parameter for a single SRA accession  

    output:
    // path "data/${sra_accession}*.fastq", emit: sample_files  // Emits the FASTQ files with just the path
    tuple val(sra_accession), path("data/${sra_accession}*.fastq") , emit: sample_files 

    errorStrategy 'retry' // Continue to the next accession on error  

// this section need some sort of input validation ;)
// Something like if (!params.sra_accessions_file) {
//    error "Please provide SRA accessions --sra_accessions_file"
// }
// Perhaps also make sure that list are only 1 column only ?

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
// This is very thoughtful, I didn't think of this at the beginning :) 
process receive_samples {  
    input:  
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
// This probably can be done only one - say we build the host_genome once, then attached it in the step
// if host_genome already built, then use existing, if not, then prepare host genome.

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
// output should be bgzip ;) 
process dehost {
    input:
    tuple val(sra_accession), path(fastq_files), path(host_genome_index) 

    output:
    tuple val(sra_accession), path("${sra_accession}_human.fasta"), path("${sra_accession}_microbiome.fasta")

    script:
    """
    bowtie2 -x ${host_genome_index}/host_genome \
        -1 ${fastq_files[0]} -2 ${fastq_files[1]} | samtools view -bS - > ${sra_accession}_aligned.bam
    
    samtools view -b -F 4 ${sra_accession}_aligned.bam | \
    bedtools bamtofastq -i stdin | \
    seqtk seq -A - > ${sra_accession}_human.fasta
    
    samtools view -b -f 4 ${sra_accession}_aligned.bam | \
    bedtools bamtofastq -i stdin | \
    seqtk seq -A - > ${sra_accession}_microbiome.fasta
    """
} 

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
    dehost_data = sra_data.combine(host_index) | dehost
}




