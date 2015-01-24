# ChIPpip: ChIPseq pipeline for biologists

ChIPpip is a perl/R package that supports the analysis of next generation sequencing (NGS) data as part of the NEAT (NGS easy analysis tools) toolkit.
It is a versatile and easily configurable tool that allows users to go from compressed fastq files to bigwigs using a single command line.
One central feature of ChIPpip is the ability to perform various tasks on many samples while managing batch submissions and cluster queing.
ChIPpip can easily be implemented in any institution with limited to no programming knowledge.
The flow has been designed to efficiently run on a computer cluster running a distributed resource manager such as torque.
ChIPpip has been developped in collaboration with wet-lab scientists as well as bioinformaticiens to insure userfriendliness, management of complicated experimental setups and reproducibility in the big data era.




ChIPpip can run the following tasks using a single command line:

[ 1 ]       Unzip and rename fastq.gz files

[ 2 ]       Quality control of sequencing reads

[ 3 ]       Map reads (bwa)

[ 4 ]       Filter reads

[ 5 ]       Peakcalling (SPP)

[ 6 ]       Clean bigwig files



Once ChIPpip has been run, users are literally two clicks away from metagene analysis using ChIPmE. ChIPmE has been developped as a downstream module for ChIPpip and supports various steps in the process between generating .bam files to obtaining readable data for wet-lab scientists including .pdf graphs (enrichments over features), venn diagrams (overlap of peaks) and count tables. 
