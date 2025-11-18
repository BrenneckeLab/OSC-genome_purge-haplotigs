# OSC Genome Purge Haplotigs Pipeline

Scripts for purging haplotigs from the OSC genome assembly to generate a single-copy genome with accurate coverage representation.

Part of the **Handler et al., 2025** publication:

**The Drosophila OSC Genome: A Resource for Studies of Transposon and piRNA Biology**

## Overview

This repository contains the pipeline for identifying and removing haplotig duplications from the raw OSC genome assembly. Haplotigs are alternative haplotype contigs that can inflate assembly size and complicate downstream analyses. This step is essential for generating a high-quality, non-redundant genome assembly.

## Repository Structure

```
├── script-files/      # Core purging scripts
└── purge-genome.sh    # Main submission script for haplotig purging
```

## Pipeline Components

### Haplotig Identification
Scripts for detecting redundant haplotig sequences based on read coverage and sequence similarity.

### Purging and Reassignment
Tools for removing haplotig duplications and reassigning reads to primary contigs.

## Requirements

- Apptainer

## Usage

Run the main purging pipeline using:

```bash
bash purge-genome.sh
```

Adjust coverage thresholds and parameters in the script files based on your specific assembly characteristics and resubmit the analysis to progress through purging. 

## Output

The pipeline produces:
- Purged primary assembly (single-copy representation)
- Haplotig sequences (alternative haplotypes)
- Coverage statistics and diagnostic plots

## Related Resources

### Main Publication Repository
https://github.com/BrenneckeLab/Handler_2025-OSC-genome

### UCSC Genome Browser Hub
https://genome-euro.ucsc.edu/s/Brennecke%2DLab/OSC_r1.01_Handler_et.al._2025

## Citation

Please find the proper citation in https://github.com/BrenneckeLab/Handler_2025-OSC-genome


## Contact

For questions or additional information, please contact:
dominik.handler@imba.oeaw.ac.at

## License

MIT License
