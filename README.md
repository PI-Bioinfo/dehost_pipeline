# Metagenomic Data Analysis Pipeline  

This Nextflow pipeline is designed for the automated processing of metagenomic data, focusing on downloading, validating, and dehosting sequences from the Sequence Read Archive (SRA). The pipeline is inspired by methodologies used in studies such as the one examining the impact of SARS-CoV-2 on human microbiota, which highlights the importance of understanding microbial communities in health and disease contexts.  

## Background  

The study of microbiomes, particularly in the context of diseases like COVID-19, provides insights into how microbial communities interact with human hosts. The referenced study utilized advanced sequencing and bioinformatics techniques to analyze microbiota from various body sites, emphasizing the need for robust pipelines to handle complex metagenomic data.  

## Pipeline Overview  

The pipeline consists of several key processes:  

1. **Retrieve SRA Data:** Downloads FASTQ files from SRA using accession numbers listed in a specified file. Implements error handling with a retry strategy to ensure data integrity.  

2. **Validate Samples:** Performs checksum validation on downloaded FASTQ files to ensure data quality. Validated files are stored in a designated directory.  

3. **Prepare Host Genome:** Downloads and indexes a specified host genome using `bowtie2-build`, preparing it for alignment processes.  

4. **Dehost:** Aligns reads to the host genome using `bowtie2`, separating host and microbial reads into distinct FASTA files. This step is crucial for isolating microbial sequences for further analysis.  

## Usage  

### Installation  

Ensure that Nextflow and all required tools (`fastq-dump`, `md5sum`, `wget`, `gunzip`, `bowtie2`, `samtools`, `bedtools`, `seqtk`) are installed. Using a containerized environment (e.g., Docker, Singularity) is recommended for reproducibility.  

### Configuration  

- **SRA Accessions File:** Create a file named `SRR_Acc_List.txt` containing SRA accession numbers, one per line.  
- **Genome Reference:** Modify the `params.genome_ref` variable if a different host genome is needed.  

### Execution  

Run the pipeline with the following command:  

```bash  
nextflow run main.nf
```

### Output
-   validated_samples/*: Directory containing validated FASTQ files.
-   host_info: Decompressed host genome file.
-   host_genome_index: Bowtie2 index of the host genome.
-   {sra_accession}_human.fasta: FASTA file of reads aligned to the host genome.
-   {sra_accession}_microbiome.fasta: FASTA file of reads not aligned to the host genome.

### Parameters
-   params.sra_accessions_file: Path to the file with SRA accession numbers (default: SRR_Acc_List.txt).
-   params.genome_ref: URL or path to the host genome reference (default: https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.gz).
-   params.validated_sample: Directory for storing validated samples (default: validated_samples).

### References
Li et al. (2023). Assessment of microbiota in the gut and upper respiratory tract of patients with COVID-19. *Microbiome*, 11:38. Link to article.

### Author
Lisa Thuy Duyen Tran | lisa.ttd@pacificinformatics.com.vn