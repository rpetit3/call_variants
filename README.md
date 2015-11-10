# Overview
*call_variants*, as the name might suggest, is a variant (SNP and InDel) calling pipeline for bacterial sequences. With input FASTQ sequences and a reference (FASTA & GenBank) you can quickly determine the variants. *call_variants* makes use of a few programs (listed below), but the variants are determined by [GATK](https://www.broadinstitute.org/gatk/) developed by the [Broad Institute](http://www.broadinstitute.org). We have based our implementation of this pipeline on the [GATK Best Practices](https://www.broadinstitute.org/gatk/guide/best-practices) workflows, with the exceptions of a few modifications (base recalibration).

### Programs used in the Variant Calling pipeline.
- [samtools 1.2](https://github.com/samtools/samtools/releases/tag/1.2)
    - faidx
- [BWA v0.7.12](https://github.com/lh3/bwa/releases/tag/0.7.12)
    - index
    - mem
    - aln/samse
- [Picard Tools v1.140](https://github.com/broadinstitute/picard/releases/tag/1.140)
    - CreateSequenceDictionary
    - BuildBamIndex
    - AddOrReplaceReadGroups
    - MarkDuplicates
- [GATK v3.4](https://github.com/broadgsa/gatk/releases/tag/3.4)
    - RealignerTargetCreator
    - IndelRealigner
    - HaplotypeCaller
    - VariantFiltration
- [vcf-annotator](https://github.com/rpetit3/vcf-annotator)

# Installation
At the moment *call_variants* has only been tested on Ubuntu 14.04, but I assume it will work on most UNIX environments. The installation instructions are based on Ubuntu 14.04.

### Prerequisites
At the moment, I am assuming all development type programs have been installed (make, gcc, git, etc...). Below are some you may need. If you find somethings are missing, please submit an issue.
```
sudo apt-get install python-dev
sudo apt-get install python-pip
sudo apt-get install python-numpy
sudo pip install pysqlite
```

### Building
All programs required to execute the pipeline will be downloaded and built.
```
cd ~/
git clone git@github.com:rpetit3-science/call_variants.git
cd call_variants
make
make test
```

If everything checks out with *make test* you should be all set. Please report any uncaught errors. Towards the end of the output, you will have probably notice something like to the following. Be sure to add this to your profile (.bashrc for example). 
```
*******************************************************************
*******************************************************************
*******************************************************************
Please add the following to your profile (.profile, .bashrc, .bash_profile, etc...).

export PYTHONPATH=/home/rpetit/call_variants:/home/rpetit/call_variants/src/third-party/python:/home/rpetit/call_variants/src/third-party/python/vcf-annotator:/home/rpetit/call_variants:/home/rpetit/call_variants/src/third-party/python:/home/rpetit/call_variants/src/third-party/python/vcf-annotator:$PYTHONPATH

*******************************************************************
*******************************************************************
*******************************************************************
```

# Running *call_variants*
With your PYTHONPATH updated, you should now be able to run *call_variants*. If you don't see the following, make sure you updated your PYTHONPATH.
```
cd ~/call_variants
bin/call_variants --help

usage: call_variants [-h] [--verbose [VERBOSE]] [--version] [-L FILE]
                     [-T JOBNAME] [-j N] [--use_threads] [-n]
                     [--touch_files_only] [--recreate_database]
                     [--checksum_file_name FILE] [--flowchart FILE]
                     [--key_legend_in_graph] [--draw_graph_horizontally]
                     [--flowchart_format FORMAT] [--forced_tasks JOBNAME]
                     [-o STR] [-r INT] [-p INT] [--tag TAG] [--log_times]
                     INPUT_FASTQ REFERENCE_FASTA REFERENCE_GENBANK

Call variants from input FASTQ.

positional arguments:
  INPUT_FASTQ           Input FASTQ file
  REFERENCE_FASTA       Input reference FASTA file.
  REFERENCE_GENBANK     Input reference GenBank file.

optional arguments:
  -h, --help            show this help message and exit
  -o STR, --output STR  Output directory. (Default: ./)
  -r INT, --read_length INT
                        Mean read length of input FASTQ file
  -p INT, --processors INT
                        Number of processors to use. (Default 1)
  --tag TAG             Prefix for final VCF. (Default variants)
  --log_times           Write task run times to file (Default: STDERR).

```

### Input
*call_variants* only requires three inputs to be executed.
```
INPUT_FASTQ ---> Your DNA sequences in FASTQ format.
REFERENCE_FASTA ---> Your reference strain in FASTA format.
REFERENCE_GENBANK ---> Your reference strain in GenBank format.
```

### Example Execution
```
cd ~/call_variants
/bin/call_variants test_pipeline/test.fastq.gz test_pipeline/test.fasta test_pipeline/test.gb -p 1 --log_times -r 100 -o test_pipeline
```

# A little more about the pipeline

### Step 1: Alignment against your reference
Reads from the input FASTQ file are aligned to a BWA index of your reference. Depending on the average read length of the input sequences either *bwa mem* (>70bp) or *bwa aln* (<=70bp) is used. In both cases the reads are mapped as single-end reads, as paired-end has not been implemented into *call_variants* yet.

##### Mean Read Length > 70bp: bwa mem
```
bwa mem -M -t {NUM_CPUS} {REFERENCE} {INPUT_FASTQ} > {OUTPUT_SAM}
    -M        Mark shorter split hits as secondary (for Picard compatibility).
    -t INT    Number of threads
```

##### Mean Read Length <= 70bp: bwa aln/samse
```
bwa aln -f {OUTPUT_SAI} -t {NUM_CPUS} {REFERENCE} {INPUT_FASTQ}
    -f FILE   File to write output to instead of stdout 
    -t INT    Number of threads

bwa samse -f OUTPUT_SAM {REFERENCE} {INPUT_SAI} {INPUT_FASTQ}
```

### Step 2: Mark Duplicates
##### [Picard Tools - AddOrReplaceReadGroups](http://broadinstitute.github.io/picard/command-line-overview.html#AddOrReplaceReadGroups)
```
java -Xmx4g -jar AddOrReplaceReadGroups \
    INPUT={INPUT_SAM} \
    OUTPUT={SORTED_BAM} \
    SORT_ORDER=coordinate \
    RGID='GATK' \
    RGLB='GATK' \
    RGPL='Illumina' \
    RGSM='GATK' \
    RGPU='GATK' \
    VALIDATION_STRINGENCY=LENIENT
```
##### [Picard Tools - MarkDuplicates](http://broadinstitute.github.io/picard/command-line-overview.html#MarkDuplicates)
```
java -Xmx4g -jar MarkDuplicates \
    INPUT={SORTED_BAM} \
    OUTPUT={DEDUPED_BAM} \
    METRICS_FILE={METRICS_FILE} \
    ASSUME_SORTED=true \
    REMOVE_DUPLICATES=false \
    VALIDATION_STRINGENCY=LENIENT
```

### Step 3: Realign InDels
##### [GATK - RealignerTargetCreator](https://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_gatk_tools_walkers_indels_RealignerTargetCreator.php)
```
java -Xmx4g -jar GenomeAnalysisTK.jar -T RealignerTargetCreator \
    -R {REFERENCE} \
    -I {DEDUPED_BAM} \
    -o intervals.list
```

##### [GATK - IndelRealigner](https://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_gatk_tools_walkers_indels_IndelRealigner.php)
```
java -Xmx4g -jar GenomeAnalysisTK.jar -T IndelRealigner \
    -R {REFERENCE} \
    -I {DEDUPED_BAM} \
    -o {REALIGNED_BAM} \
    -targetIntervals intervals.list                             
```

### Step 4: Recalibrate Bases
Due to a few requirements (known variant sites and minimum number of base pairs) we have opted to skip this step in the GATK Best Practices workflow.

### Step 5: Call Variants
##### [GATK - HaplotypeCaller](https://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_gatk_tools_walkers_haplotypecaller_HaplotypeCaller.php)
```
java -Xmx4g -jar GenomeAnalysisTK.jar -T HaplotypeCaller \
    -R {REFERENCE} \
    -I {REALIGNED_BAM} \
    -o {OUTPUT_VCF} \
    -ploidy 1 \
    -stand_call_conf 30.0 \
    -stand_emit_conf 10.0 \
    -rf BadCigar 
```

### Step 6: Filter Variants
##### [GATK - VariantFiltration](https://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_gatk_tools_walkers_filters_VariantFiltration.php)
```
java -Xmx4g -jar GenomeAnalysisTK.jar -T VariantFiltration \
    -R {REFERENCE} \
    -V {INPUT_VCF} \
    -o {FILTERED_VCF} \
    --clusterSize 3 \
    --clusterWindowSize 10 \
    --filterExpression 'DP < 9 && AF < 0.7' \
    --filterName 'Fail' \
    --filterExpression 'DP > 9 && AF >= 0.7 && AF < 0.95' \
    --filterName 'Pass' \
    --filterExpression 'DP > 9 && AF >= 0.95' \
    --filterName 'SuperPass' \
    --filterExpression 'QUAL < 20' \
    --filterName 'Low Quality' \
    --filterExpression 'GQ < 20' \
    --filterName 'Low GQ' 
```

### Step 7: Annotate Variants
##### [VCF-Annotator](https://github.com/rpetit3/vcf-annotator)
```
vcf_annotator --gb {REFERENCE_GENBANK} --vcf {FILTERED_VCF} > {ANNOTATED_VCF}
```
