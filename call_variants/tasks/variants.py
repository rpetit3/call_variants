#! /usr/bin/env python
""" Ruffus wrappers for SNP related tasks. """
from call_variants.config import BIN
from call_variants.tasks import shared


def bwa_index(fasta):
    """ Align reads (mean length < 70bp) against reference genome. """
    shared.run_command(
        [BIN['bwa'], 'index', fasta],
    )


def bwa_mem(fastq, output_sam, num_cpu, reference, completed_file):
    """ Align reads (mean length < 70bp) against reference genome. """
    shared.run_command(
        [BIN['bwa'], 'mem', '-M', '-t', num_cpu, reference, fastq],
        stdout=output_sam
    )

    if shared.try_to_complete_task(output_sam, completed_file):
        return True
    else:
        raise Exception("bwa mem did not complete successfully.")


def bwa_aln(fastq, sai, output_sam, num_cpu, reference, completed_file):
    """ Align reads (mean length < 70bp) against reference genome. """
    shared.run_command([
        BIN['bwa'], 'aln', '-f', sai, '-t', num_cpu, reference, fastq
    ])

    shared.run_command([
        BIN['bwa'], 'samse', '-f', output_sam, reference, sai, fastq
    ])

    if shared.try_to_complete_task(output_sam, completed_file):
        return True
    else:
        raise Exception("bwa aln/samse did not complete successfully.")


def add_or_replace_read_groups(input_sam, sorted_bam, completed_file):
    """
    Picard Tools - AddOrReplaceReadGroups.

    Places each read into a read group for GATK processing. Really only
    informative if there are multiple samples.
    """
    shared.run_command([
        BIN['java'], '-Xmx8g', '-jar', BIN['picardtools'],
        'AddOrReplaceReadGroups',
        'INPUT=' + input_sam,
        'OUTPUT=' + sorted_bam,
        'SORT_ORDER=coordinate',
        'RGID=GATK',
        'RGLB=GATK',
        'RGPL=Illumina',
        'RGSM=GATK',
        'RGPU=GATK',
        'VALIDATION_STRINGENCY=LENIENT'
    ])

    if shared.try_to_complete_task(sorted_bam, completed_file):
        return True
    else:
        raise Exception("AddOrReplaceReadGroups didn't complete successfully.")


def mark_duplicates(sorted_bam, deduped_bam, completed_file):
    """
    GATK Best Practices - Mark Duplicates.

    Picard Tools - MarkDuplicates: Remove mark identical reads as duplicates
    for GATK to ignore.
    """
    shared.run_command([
        BIN['java'], '-Xmx8g', '-jar', BIN['picardtools'],
        'MarkDuplicates',
        'INPUT=' + sorted_bam,
        'OUTPUT=' + deduped_bam,
        'METRICS_FILE=' + deduped_bam + '_metrics',
        'ASSUME_SORTED=true',
        'REMOVE_DUPLICATES=false',
        'VALIDATION_STRINGENCY=LENIENT'
    ])

    if shared.try_to_complete_task(deduped_bam, completed_file):
        build_bam_index(deduped_bam)
        return True
    else:
        raise Exception("MarkDuplicates didn't complete successfully.")


def build_bam_index(bam):
    shared.run_command([
        BIN['java'], '-Xmx8g', '-jar', BIN['picardtools'],
        'BuildBamIndex',
        'INPUT=' + bam,
    ])


def realigner_target_creator(deduped_bam, intervals, reference,
                             completed_file):
    """
    GATK Best Practices - Realign Indels.

    GATK - RealignerTargetCreator: Create a list of InDel regions to be
    realigned.
    """
    shared.run_command([
        BIN['java'], '-Xmx8g', '-jar', BIN['gatk'],
        '-T', 'RealignerTargetCreator',
        '-R', reference,
        '-I', deduped_bam,
        '-o', intervals
    ])

    if shared.try_to_complete_task(intervals, completed_file):
        return True
    else:
        raise Exception("RealignerTargetCreator didn't complete successfully.")


def indel_realigner(intervals, deduped_bam, realigned_bam, reference,
                    completed_file):
    """
    GATK Best Practices - Realign Indels.

    GATK - IndelRealigner: Realign InDel regions.
    """
    shared.run_command([
        BIN['java'], '-Xmx8g', '-jar', BIN['gatk'],
        '-T', 'IndelRealigner',
        '-R', reference,
        '-I', deduped_bam,
        '-o', realigned_bam,
        '-targetIntervals', intervals
    ])

    if shared.try_to_complete_task(realigned_bam, completed_file):
        return True
    else:
        raise Exception("IndelRealigner did not complete successfully.")


def haplotype_caller(realigned_bam, output_vcf, reference, completed_file):
    """
    GATK Best Practices - Call Variants.

    GATK - HaplotypeCaller: Call variants (SNPs and InDels)
    """
    shared.run_command([
        BIN['java'], '-Xmx8g', '-jar', BIN['gatk'],
        '-T', 'HaplotypeCaller',
        '-R', reference,
        '-I', realigned_bam,
        '-o', output_vcf,
        '-ploidy', '1',
        '-stand_call_conf', '30.0',
        '-stand_emit_conf', '10.0',
        '-rf', 'BadCigar',
    ])
    if shared.try_to_complete_task(output_vcf, completed_file):
        return True
    else:
        raise Exception("HaplotypeCaller did not complete successfully.")


def variant_filtration(input_vcf, filtered_vcf, reference, completed_file):
    """ See Tauqeer's protocol. """
    shared.run_command([
        BIN['java'], '-Xmx8g', '-jar', BIN['gatk'],
        '-T', 'VariantFiltration',
        '-R', reference,
        '-V', input_vcf,
        '-o', filtered_vcf,
        '--clusterSize', '3',
        '--clusterWindowSize', '10',
        '--filterExpression', 'DP < 9 && AF < 0.7',
        '--filterName', 'Fail',
        '--filterExpression', 'DP > 9 && AF >= 0.95',
        '--filterName', 'SuperPass',
        '--filterExpression', 'GQ < 20',
        '--filterName', 'LowGQ',
    ])

    if shared.try_to_complete_task(filtered_vcf, completed_file):
        return True
    else:
        raise Exception("VariantFiltration did not complete successfully.")


def vcf_annotator(filtered_vcf, annotated_vcf, genbank, completed_file):
    """ Annotate called SNPs/InDel. """
    shared.run_command(
        [BIN['vcf_annotator'],
         '--gb', genbank,
         '--vcf', filtered_vcf],
        stdout=annotated_vcf
    )

    if shared.try_to_complete_task(annotated_vcf, completed_file):
        return True
    else:
        raise Exception("vcf-annotator did not complete successfully.")


def move_final_vcf(annotated_vcf, compressed_vcf, completed_file):
    """ Move the final VCF to the project root. """
    shared.run_command(
        ['gzip', '-c', annotated_vcf],
        stdout=compressed_vcf
    )

    if shared.try_to_complete_task(compressed_vcf, completed_file):
        return True
    else:
        raise Exception("final vcf gzip did not complete successfully.")


def cleanup(base_dir, tar_gz, completed_file):
    """ Clean up all the intermediate files. """
    remove_these = ['*.bam', '*.bai', '*.intervals', '*.sam', '*.sai']
    for name in remove_these:
        shared.find_and_remove_files(base_dir, name)

    gatk_files = shared.find_files(base_dir, '*', '1', '1')
    if shared.compress_and_remove(tar_gz, gatk_files):
        if shared.try_to_complete_task(tar_gz, completed_file):
            return True
        else:
            raise Exception("Unable to complete GATK clean up.")
    else:
        raise Exception("Cannot compress GATK output, please check.")
