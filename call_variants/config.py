#! /usr/bin/env python
"""
Static variables used throughout the analysis pipeline.

Please note, the Makefile should update BASE_DIR, but if not you will need to.
"""
BASE_DIR = CHANGE_ME"

# PATH
PATH = BASE_DIR + '/bin'
THIRD_PARTY_PATH = PATH + '/third-party'
TOOL_DATA = BASE_DIR + '/tool-data'

# Programs
BIN = {
    'samtools': THIRD_PARTY_PATH + '/samtools',
    'bwa': THIRD_PARTY_PATH + '/bwa',
    'java': THIRD_PARTY_PATH + '/java',
    'picardtools': '{0}/picard.jar'.format(
        THIRD_PARTY_PATH
    ),
    'gatk': THIRD_PARTY_PATH + '/GenomeAnalysisTK.jar',
    'vcf_annotator': THIRD_PARTY_PATH + '/vcf-annotator',

    # Pipelines
    'call_variants': PATH + '/call_variants',
}
