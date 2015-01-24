#!/usr/bin/perl -w

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#************************************************************************
#*                                                                	*
#*                ChIPseq PERL script					*
#*                                                                	*
#************************************************************************

#************************************************************************
#*                                                                	*
#*      Open Targets.txt and start pipeline 				*
#*                                                                	*
#*----------------------------------------------------------------------*

if( $ARGV[0] ) { $path2expFolder = $ARGV[0]; }
else{ die "\n\n----------------------------------------\n\n Provide the path where to your project: </PATH/TO/PROJECT> \n\n--------------------------------------------------------------------------------\n\n"; }

#*----------------------------------------------------------------------*
# Read Targets.txt file

my $Targets = "$path2expFolder/DataStructure/Targets.txt";
open(INPUT, $Targets) || die "Error opening $Targets : $!\n\n\n";

my ($expFolder, $genome, $userFolder, $path2ChIPseqScripts, $path2ChIPseq, $path2fastqgz) 	= ("NA", "NA", "NA", "NA", "NA", "NA");
my ($unzip, $qc, $map, $filter, $peakcalling, $cleanbigwig, $cleanfolders)			= ("FALSE", "FALSE", "FALSE", "FALSE", "FALSE", "FALSE", "FALSE");
my (@sc, @lines2remove)										= ();
# Find paths to different folders in the Targets.txt file
while(<INPUT>) {
	if (/# My_email/) {
                $_ =~ m/"(.+?)"/;
                $email = "$1";	
	}
	if (/# My_project_title/) {
		$_ =~ m/"(.+?)"/;
		$expFolder = "$1";
	}
	if (/# Reference_genome/) {
		$_ =~ m/"(.+?)"/;
		$genome = "$1";
	}
	if (/# Path_to_proj_folder/) {	
		$_ =~ m/"(.+?)"/;
		$userFolder = "$1";
	}
	if (/# Path_to_ChIPpip/) {
		$_ =~ m/"(.+?)"/;
		$path2ChIPseq = "$1";
		$path2ChIPseqScripts = join("", $path2ChIPseq, "/scripts");
	}
	if (/# Path_to_orifastq.gz/) {
		$_ =~ m/"(.+?)"/;
		$path2fastqgz = "$1";
	}
	if (/# Path_to_chrLens.dat/) {
                $_ =~ m/"(.+?)"/;
                $chrlens = "$1";
        }
	if (/# Path_to_RefGen.fa/) {
                $_ =~ m/"(.+?)"/;
                $refGenome = "$1";
        }
	if (/# Paired_end_run/) {
                $_ =~ m/"(.+?)"/;
                $PE = "$1";
        }
	if (/# Steps_to_execute/) {
		$_ =~ m/"(.+?)"/;
        	@steps2execute = ();
		if (grep /\bunzip\b/i, $_ )		{ $unzip 		= "TRUE"; push @steps2execute, "Unzip";		}
		if (grep /\bqc\b/i, $_ )		{ $qc			= "TRUE"; push @steps2execute, "QC";		}
		if (grep /\bmap\b/i, $_ )		{ $map	 		= "TRUE"; push @steps2execute, "Map";		}
		if (grep /\bfilter\b/i, $_ )		{ $filter 		= "TRUE"; push @steps2execute, "Filter";	}
		if (grep /\bpeakcalling\b/i, $_ )	{ $peakcalling		= "TRUE"; push @steps2execute, "Peakcalling";	}
		if (grep /\bcleanbigwig\b/i, $_ )	{ $cleanbigwig		= "TRUE"; push @steps2execute, "Cleanbigwig";	}
        }
	if (/# Remove_from_bigwig/) {
		$_ =~ m/"(.+?)"/;
		my $text = "$1";
		my @var = split(",", $text);
		foreach my $line (@var) {
			$line =~ s/\s+//g;
			push(@lines2remove, $line);
		}
	}

} # end of Targets.txt



my $AdvSettings = "$path2expFolder/DataStructure/AdvancedSettings.txt";
open(INPUT, $AdvSettings) || die "Error opening $AdvSettings : $!\n\n\n";

my ($removepcrdup, $makeunique, $ndiff, $fdr, $posopt, $densityopt, $enforceisize)	= ("NA", "NA", "NA", "NA", "NA", "NA", "NA");

while(<INPUT>) {

	if (/# Bwa.removePCRdup/) {
		$_ =~ m/"(.+?)"/;
		$removepcr = "$1";
	}
	if (/# Bwa.makeUniqueRead/) {
		$_ =~ m/"(.+?)"/;
		$makeunique = "$1";
	}
	if (/# Bwa.maxEditDist/) {
		$_ =~ m/"(.+?)"/;
		$ndiff = "$1";
	}
	if (/# Filter.splitbychr/) {
		$_ =~ m/"(.+?)"/;
		$splitbychr = "$1";
	}
	if (/# Filter.enforceinssize/) {
		$_ =~ m/"(.+?)"/;
		$enforceisize = "$1";
	}
	if (/# Filter.minisize/) {
		$_ =~ m/"(.+?)"/;
		$minisize = "$1";
	}
	if (/# Filter.maxisize/) {
		$_ =~ m/"(.+?)"/;
		$maxisize = "$1";
	}
	if (/# PeakCaller.fdr/) {
		$_ =~ m/"(.+?)"/;
		$fdr = "$1";
	}
	if (/# PeakCaller.posopt/) {
		$_ =~ m/"(.+?)"/;
		$posopt = "$1";
	}
	if (/# PeakCaller.densityopt/) {
		$_ =~ m/"(.+?)"/;
		$densityopt = "$1";
	}

} # end of AdvancedSettings.txt




#*----------------------------------------------------------------------*
# Define paths

my $path2expFolder = "$userFolder/$expFolder";
$Targets = "$path2expFolder/DataStructure/Targets.txt";

#*----------------------------------------------------------------------*

chdir "$path2expFolder";

print "\n##################################################################################################";
print "\n# ";
print "\n#	The pipeline will run the following tasks:\t\t";
print join("  -  ", @steps2execute);
print "\n# ";
print "\n##################################################################################################\n\n";
print "\n";
print "\n My email:\t\t $email";
print "\n";
print "\n expFolder:\t\t $expFolder";
print "\n genome:\t\t $genome";
print "\n userFolder:\t\t $userFolder";
print "\n path2ChIPpip:\t\t $path2ChIPseq";
print "\n path2expFolder:\t $path2expFolder";
print "\n path2fastq.gz:\t\t $path2fastqgz";
print "\n Targets:\t\t $path2expFolder/DataStructure/Targets.txt";
print "\n chrlens:\t\t $chrlens";
print "\n Paired end sequencing:\t $PE";
print "\n refGenome:\t\t $refGenome";
print "\n Remove pcr dupl:\t $removepcr";
print "\n Make unique reads:\t $makeunique";
print "\n PeakCaller.fdr:\t $fdr";
print "\n";
print "\n Current working dir:\t $path2expFolder";
print "\n";
print "\n .........................................";
print "\n Performing following tasks:";
print "\n .........................................";
print "\n unzip:\t\t\t $unzip";
print "\n qc:\t\t\t $qc";
print "\n map:\t\t\t $map";
print "\n filter:\t\t $filter";
print "\n peakcalling:\t\t $peakcalling";
print "\n cleanbigwig:\t\t $cleanbigwig \t (remove: @lines2remove)";
print "\n .........................................";
#print "\n";
#print "\n----------------------------------------\n";


#*----------------------------------------------------------------------*
# Parse the Targets.txt file and find unique sample names of FileName and InpName

my @Targets1 = `cut -f1 $Targets`;
	chomp(@Targets1);
my @Targets2 = `cut -f2 $Targets`;
	chomp(@Targets2);
my @Targets3 = `cut -f3 $Targets`;
	chomp(@Targets3);
my @Targets4 = `cut -f4 $Targets`;
        chomp(@Targets4);

# Store original file names in orisamples

my @orisamples;
foreach $line (@Targets1) {
	$line =~ /^$/ and die "Targets 1: Blank line detected at $.\n\n";
	$line =~ /^[# = " OriFileName FileName OriInpName InpName]/ and next;
	push(@orisamples, $line);
}

# Store original file names in samples
my @samples;
foreach $line (@Targets2) {
	$line =~ /^$/ and die "Targets 1: Blank line detected at $.\n\n";
	$line =~ /^[# = " OriFileName FileName OriInpName InpName]/ and next;
	push(@samples, $line);
}
my @oriinputs;
foreach $line (@Targets3) {
	$line =~ /^$/ and die "Targets 3: Blank line detected at $.\n\n";
	$line =~ /^[# = " OriFileName FileName OriInpName InpName]/ and next;
	push(@oriinputs, $line);
}
my @inputs;
foreach $line (@Targets4) {
        $line =~ /^$/ and next;
	$line =~ /^[# = " OriFileName FileName OriInpName InpName]/ and next;
        push(@inputs, $line);
}


#*----------------------------------------------------------------------*
# Remove duplicated elements in the list @samples and @inputs
%seen		= ();
@samples	= grep { ! $seen{$_} ++ } @samples;
@allinputs	= @inputs;
%seen		= ();
@inputs		= grep { ! $seen{$_} ++ } @inputs;
@samplesInputs	= @samples;
push (@samplesInputs, @inputs);

#*----------------------------------------------------------------------*
# Store variables into @samples
my $cutoff	= 0.0;
my @chrs	= `cut -f1 $chrlens`;
chomp(@chrs);

#*----------------------------------------------------------------------*
# Set different paths

my $tmpscr 			= "$path2expFolder/scripts";
my $path2fastq			= "$path2expFolder/fastq";
my $path2QC			= "$path2expFolder/QC";
my $bamdir			= "$path2expFolder/bwa_sam";
my $samdir			= "$path2expFolder/bwa_sam";
my $safdir			= "$path2expFolder/bwa_saf";
my $saidir			= "$path2expFolder/bwa_sai";
my $path2peakcalling            = "$path2expFolder/peakcalling";
my $scrhead 			= "$path2ChIPseqScripts/QSUB_header.sh";
my $path2iterate		= "$tmpscr/iterate/";
my $ChIPseqMainIterative	= "$path2iterate/ChIPseq.sh";
my $IterateSH			= "$path2iterate/IterateSH.sh";


#************************************************************************
#									*
# 			START tasks					*
#								   	*
#*----------------------------------------------------------------------*

#*----------------------------------------------------------------------*
# Unzipping and renaming fastq.gz files

if( $unzip =~ "TRUE" ){

	print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*- \n";
	print "\n Unzipping and renaming files using Targets.txt \n";

	my $iterateJobName	= "Iterate_unzip";
	my $myJobName		= "unzip";
	my $path2qsub		= "$tmpscr/$myJobName/qsub";

	# Create file to store jobs in
	unless( -d "$tmpscr/$myJobName" )	{ `mkdir $tmpscr/$myJobName`; }
	unless( -d "$path2qsub" )		{ `mkdir $path2qsub`; }
	my $QSUB	= "$tmpscr/$myJobName/$myJobName\.sh";
	open $QSUB, ">", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "#!/bin/bash\n";
	close $QSUB;
	`chmod 777 $QSUB`;
        print "\n Store all of the following '$myJobName' jobs in $QSUB \n";
        my @myJobs;

	foreach my $i (0 .. $#samples) {

		# Prepare a personal qsub script
		my $QSUBint  = "$tmpscr/$myJobName/$samples[$i]\_$myJobName\.sh";
		`cp $scrhead $QSUBint`;

		my $cmd		= "gunzip -c $path2fastqgz/$orisamples[$i]\.fastq\.gz > $path2fastq/$samples[$i]\.fastq";
		`echo "$cmd" >> $QSUBint`;
	
		#---------------------------------------------
		# Keep track of the jobs in @myJobs
		my $jobName	= "Sample_$myJobName$i";
		push(@myJobs, $jobName);
		$cmd		= "$jobName=`qsub -o $path2qsub -e $path2qsub $QSUBint`";
		open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
		print $QSUB "$cmd\n";
		close $QSUB;     
	}

	foreach my $i (0 .. $#inputs) {

		# Prepare a personal qsub script
		my $QSUBint  = "$tmpscr/$myJobName/$inputs[$i]\_$myJobName\.sh";
		`cp $scrhead $QSUBint`;

		#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		my $cmd         = "gunzip -c $path2fastqgz/$oriinputs[$i]\.fastq\.gz > $path2fastq/$inputs[$i]\.fastq";
		`echo "$cmd" >> $QSUBint`;
		#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--

		#---------------------------------------------
		# Keep track of the jobs in @myJobs
		my $jobName     = "Input_$myJobName$i";
		push(@myJobs, $jobName);
		$cmd            = "$jobName=`qsub -o $path2qsub -e $path2qsub $QSUBint`";
		open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
		print $QSUB "$cmd\n";
		close $QSUB;
	}

	#*----------------------------------------------------------------------*
	# Change Targets.txt file for next iteration
	print "\n--------------------------------------------------------------------------------------------------\n";
	print "\n Changing '$myJobName' variable to FALSE and proceed";
	`/usr/bin/perl -p -i -e "s/$myJobName/$myJobName\_DONE/gi" $Targets`;

	#*----------------------------------------------------------------------*
	# Prepar file containing the jobs to run

	# Add the next job line to the $mapQSUB
	foreach( @myJobs ){ $_ = "\$".$_ ; }
	my $myJobsVec	= join(":", @myJobs);
	my $finalcmd    = "FINAL=\`qsub -N $iterateJobName -o $path2qsub -e $path2qsub -W depend=afterok\:$myJobsVec $IterateSH`";

	open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "$finalcmd\n";
	close $QSUB;

	#*----------------------------------------------------------------------*
	# Submit jobs to run

	print "\n\n--------------------------------------------------------------------------------------------------\n";
	print "\n Submitting job to cluster: \t `sh $QSUB` \n";
	`sh $QSUB`;

	#*----------------------------------------------------------------------*
	# Exit script

	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
	print "\n Exiting $myJobName section with no known error \n";
	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n";

	exit 0;
} 


#*----------------------------------------------------------------------*
# Quality Control

if( $qc =~ "TRUE" ) {

	print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*- \n";
	print "\n QC fastq files \n";

	my $iterateJobName	= "Iterate_QC";
	my $myJobName		= "QC";
	my $path2qsub		= "$tmpscr/$myJobName/qsub";

	# Create file to store jobs in
	unless( -d "$tmpscr/$myJobName" )	{ `mkdir $tmpscr/$myJobName`; }
	unless( -d "$path2qsub" )		{ `mkdir $path2qsub`; }
	my $QSUB        = "$tmpscr/$myJobName/$myJobName\.sh";
	open $QSUB, ">", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "#!/bin/bash\n";
	close $QSUB;	
	`chmod 777 $QSUB`;
	print "\n Store all of the following '$myJobName' jobs in $QSUB \n";
	my @myJobs;

	unless( -d "$path2QC" ) { `mkdir $path2QC`; }
	`cp $path2ChIPseqScripts/QC.R $tmpscr`;

	#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	my $code 	= "$tmpscr/QC.R" ;
	my $cmd		= "Rscript $code $path2expFolder &>> $path2qsub/QCReport.log";
	`echo "$cmd" >> $QSUB`;
	#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--


	#*----------------------------------------------------------------------*
        # Change Targets.txt file for next iteration
        print "\n--------------------------------------------------------------------------------------------------\n";
        print "\n Changing '$myJobName' variable to FALSE and proceed";
        `/usr/bin/perl -p -i -e "s/$myJobName/$myJobName\_DONE/gi" $Targets`;

	#*----------------------------------------------------------------------*
	# Prepar file containing the jobs to run

	# Add the next job iteration
	my $finalcmd    = "FINAL=\`qsub -N $iterateJobName -o $path2qsub -e $path2qsub $IterateSH`";

	open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "$finalcmd\n";
	close $QSUB;

	#*----------------------------------------------------------------------*
	# Submit jobs to run

	print "\n\n--------------------------------------------------------------------------------------------------\n";
	print "\n Submitting job to cluster: \t `sh $QSUB` \n";
	`sh $QSUB`;

	#*----------------------------------------------------------------------*
	# Exit script

	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
	print "\n Exiting $myJobName section with no known error \n";
	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n";

	exit 0;
}



#*----------------------------------------------------------------------*
# Mapping sequences with bwa

if( $map =~ "TRUE" ){	

	print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
	print "\n Mapping fastq files\n";

	my $iterateJobName	= "Iterate_map";
	my $myJobName		= "map";
	my $path2qsub		= "$tmpscr/$myJobName/qsub";

	# Create file to store jobs in
	unless( -d "$tmpscr/$myJobName" )	{ `mkdir $tmpscr/$myJobName`; }
	unless( -d "$path2qsub" )		{ `mkdir $path2qsub`; }
	my $QSUB        = "$tmpscr/$myJobName/$myJobName\.sh";
	open $QSUB, ">", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "#!/bin/bash\n";
	close $QSUB;
	`chmod 777 $QSUB`;
	print "\n Store all of the following '$myJobName' jobs in $QSUB \n";
	my @myJobs;


	#*----------------------------------------------------------------------*
	# Create a folder named * mysample * within each bwa_sam, bwa_saf and bwa_sai folders
	foreach $sample( @samples ){
		unless( -d "$safdir/$sample" )	{ `mkdir $safdir/$sample`; }
	}
	foreach $input( @inputs ){
		unless( -d "$safdir/$input" )	{ `mkdir $safdir/$input`; }
	}

	foreach my $i (0 .. $#samplesInputs) {
		
		# Prepare a personal qsub script
		my $QSUBint	= "$tmpscr/$myJobName/$samplesInputs[$i]\_$myJobName\.sh";
		`cp $scrhead $QSUBint`;
		
		if( $PE ) {
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			my $cmd		= "bwa aln -n $ndiff $refGenome $path2fastq/$samplesInputs[$i]\_1.fastq > $saidir/$samplesInputs[$i]\_1.sai";
			`echo "$cmd" >> $QSUBint`;
			$cmd         = "bwa aln -n $ndiff $refGenome $path2fastq/$samplesInputs[$i]\_2.fastq > $saidir/$samplesInputs[$i]\_2.sai";
			`echo "$cmd" >> $QSUBint`;
			$cmd		= "bwa sampe $refGenome $saidir/$samplesInputs[$i]\_1.sai $saidir/$samplesInputs[$i]\_2.sai $path2fastq/$samplesInputs\_1.fastq $path2fastq/$samplesInputs[$i]\_2.fastq > $samdir/$samplesInputs[$i]\.sam";
			`echo "$cmd" >> $QSUBint`;
			#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--			

		} else {
			
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			my $cmd		= "bwa aln -n $ndiff $refGenome $path2fastq/$samplesInputs[$i]\.fastq > $saidir/$samplesInputs[$i]\.sai"; 
			`echo "$cmd" >> $QSUBint`;
			my $cmd2	= "bwa samse $refGenome $saidir/$samplesInputs[$i]\.sai $path2fastq/$samplesInputs[$i]\.fastq > $samdir/$samplesInputs[$i]\.sam";
			`echo "$cmd2" >> $QSUBint`;
			#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--

		}

		#---------------------------------------------
		# Keep track of the jobs in @myJobs
		my $jobName     = "$myJobName$i";
		push(@myJobs, $jobName);
		$cmd		= "$jobName=`qsub -o $path2qsub -e $path2qsub $QSUBint`";
		open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
		print $QSUB "$cmd\n";
		close $QSUB;

	}

	#*----------------------------------------------------------------------*
	# Change Targets.txt file for next iteration
	print "\n--------------------------------------------------------------------------------------------------\n";
	print "\n Changing '$myJobName' variable to FALSE and proceed";
	`/usr/bin/perl -p -i -e "s/$myJobName/$myJobName\_DONE/gi" $Targets`;

	#*----------------------------------------------------------------------*
	# Prepar file containing the jobs to run

	# Add the next job line to the $mapQSUB
	foreach( @myJobs ){ $_ = "\$".$_ ; }
	my $myJobsVec	= join(":", @myJobs);
	my $finalcmd	= "FINAL=\`qsub -N $iterateJobName -o $path2qsub -e $path2qsub -W depend=afterok\:$myJobsVec $IterateSH`";
	open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "$finalcmd\n";
	close $QSUB;

	#*----------------------------------------------------------------------*
	# Submit jobs to run
	
	print "\n\n--------------------------------------------------------------------------------------------------\n";
	print "\n Submitting job to cluster: \t `sh $QSUB` \n";
	`sh $QSUB`;

	#*----------------------------------------------------------------------*
	# Exit script

	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
	print "\n Exiting $myJobName section with no known error \n";
	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n";

	exit 0;

} 



#*----------------------------------------------------------------*
# Filtering reads

if( $filter =~ "TRUE" ){
	
	my %hChrs		= ();

 	print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
        print "\n Filtering reads\n";

	my $iterateJobName	= "Iterate_filter";
	my $myJobName		= "filter";
	my $path2qsub		= "$tmpscr/$myJobName/qsub";

	# Create file to store jobs in
	unless( -d "$tmpscr/$myJobName" )	{ `mkdir $tmpscr/$myJobName`; }
	unless( -d "$path2qsub" )		{ `mkdir $path2qsub`; }
	my $QSUB	= "$tmpscr/$myJobName/$myJobName\.sh";
	open $QSUB, ">", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "#!/bin/bash\n";
	close $QSUB;
	`chmod 777 $QSUB`;
	print "\n Store all of the following '$myJobName' jobs in $QSUB \n";
	my @myJobs;

	foreach my $i (0 .. $#samplesInputs) {

		# Prepare a personal qsub script
		my $QSUBint	= "$tmpscr/$myJobName/$samplesInputs[$i]\_$myJobName\.sh";
		`cp $scrhead $QSUBint`;
				
		my $j=0;
		
		# -----------------------------------------		
		# Get unique matches only
		my $samplep = $samplesInputs[$i];
		if( $makeunique && ($enforceisize==0) ){

			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			# print "\n\n Getting uniquely mapped reads for $samdir/$samplesInputs[$i]\.sam";
			my $cmd		= "grep -E '\\sX0:i:1\\s' $samdir/$samplesInputs[$i]\.sam > $samdir/$samplesInputs[$i]\.u.sam";
                        `echo "$cmd" >> $QSUBint`;
			#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--

		}			



		#------------------------------------------------------------   Start Ayla's stuff    ---------------------------------------------------------------
		# Not sure exactly what this is...
		
		# enforce insert size rules 
		if( $enforceisize ) {
			print "\n Enforcing size rules for $samdir/$samplesInputs[$i]\.sam \n";
			open( F1,"< $samdir/$samplesInputs[$i]\.sam" );
			open( F2,"> $samdir/$samplesInputs[$i]\.i\.sam" );
			my $lastname = "";
			my $lastline = "";
			my %seen=();
			while( my $line=<F1> ) {
				if( ($makeunique and $line=~/\sX0:i:1\s/) or $makeunique==0 ){
					my @a = split( /\t/,$line );
					my $isize = abs($a[8]);
			
					if( $isize > $maxisize or $isize < $minisize ){ next; }
					if( ($a[8]>0 and $a[3]>$a[7]) or ($a[8]<0 and $a[3]<$a[7]) ){ next; } 
					# I think I am trying to throw away non-paired reads. 
					# Because I dumped non-uniquely mapping reads, there could be unpaired guys here...
					# Use a hash to store, hope the pair is close enough that hash doens't grow to big.
					if( exists $seen{$a[0]} ) {
						print F2 "$seen{$a[0]}";
						print F2 "$line";
						delete $seen{$a[0]};
					} else {
						$seen{$a[0]} = $line;
					}
			
				}
			}
			$prefixp = "$prefixp\.i";
		}

		# remove pcr stacks
		if( 0 and $removepcr ){

			# first sort to remove stacks
			my $cmd = "/usr/local/bin/IGVTools/igvtools sort $samdir/$samplesInputs[$i]\.sam $samdir/$samplesInputs[$i]\.sorted.sam";
			print "\n $cmd \n";
			`$cmd`;

			open( F1,"< $samdir/$samplesInputs[$i]\.sorted.sam" );
			open( F2,"> $samdir/$samplesInputs[$i]\.p.sam" );
			my $lastn = 'chrname';
			my $lastp = -1;
			my $lastr = 'readseq';
			while( my $line=<F1> ) {
				if( $line=~/^@/ ){ print F2 $line; }
				else {
					my @a= split( /\t/,$line );
					if( $a[2]=~/^$lastn$/ and $a[3]==$lastp and $a[9]=~/^$lastr$/ ){ next; }
					else {
						$hChrs{$a[2]}=1;
						print F2 $line;
						$lastn = $a[2];
						$lastp = $a[3];
						$lastr = $a[9];
					}
				}
			}
			close F1;
			close F2;
			$prefixp = "$prefixp\.p";
		}
		#------------------------------------------------------------	End Ayla's stuff    ---------------------------------------------------------------

		
		# .sam to .bam		
		#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		# sam to bam
		$cmd		= "samtools view -b $samdir/$samplesInputs[$i]\.u.sam -T $refGenome -o $samdir/$samplesInputs[$i]\.u.unsorted\.bam";
		`echo "$cmd" >> $QSUBint`;
		#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--
	
		# -----------------------------------------
		if( $removepcr ) {
			
			# .bam to sorted .bam (with removed pcr dup)
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			my $cmd		= "samtools sort  $samdir/$samplesInputs[$i]\.u.unsorted\.bam $samdir/$samplesInputs[$i]\.u.sortedwpcr";
			`echo "$cmd" >> $QSUBint`;
			$cmd		= "samtools rmdup -s $samdir/$samplesInputs[$i]\.u.sortedwpcr\.bam $safdir/$samplesInputs[$i]/$samplesInputs[$i]\.bam";
			`echo "$cmd" >> $QSUBint`;
			#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--

		} else {

			# .bam to sorted .bam
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
			# bam to sorted bam
			$cmd		= "samtools sort  $samdir/$samplesInputs[$i]\.u.unsorted\.bam $safdir/$samplesInputs[$i]/$samplesInputs[$i]\.bam";
			`echo "$cmd" >> $QSUBint`;
			#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--	
	
		}

		# -----------------------------------------
		# Sorted .bam to .bai
		my $cmdf		= "samtools index $safdir/$samplesInputs[$i]/$samplesInputs[$i]\.bam $safdir/$samplesInputs[$i]/$samplesInputs[$i]\.bai";
		`echo "$cmdf" >> $QSUBint`;

		# -----------------------------------------
		# Split indexed .bam by chr
		if( $splitbychr ) {
			unless( -d "$safdir/$samplesInputs[$i]/splitbychr" )	{ `mkdir $safdir/$samplesInputs[$i]/splitbychr`; }
			foreach my $chr( keys %hChrs ) {
				print "\n\n Entered split by chromosome \n\n";
				#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
				#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+	
				# .bam to sorted .bam by chr
				$cmd		= "samtools view -b $safdir/$samplesInputs[$i]/$samplesInputs[$i]\.bam $chr > $safdir/$samplesInputs[$i]/splitbychr/$samplesInputs[$i]\.$chr\.bam";
				`echo "$cmd" >> $QSUBint`;
				$cmd		= "samtools index $safdir/$samplesInputs[$i]/splitbychr/$samplesInputs[$i]\.$chr\.bam $safdir/$samplesInputs[$i]/splitbychr/$samplesInputs[$i]\.$chr\.bai";
				`echo "$cmd" >> $QSUBint`;
				#--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--

			}
		}

		print "\n\n Samtools processing for $samplesInputs[$i] done. \n\n";
		
		#---------------------------------------------
		# Keep track of the jobs in @myJobs
		my $jobName	= "$myJobName$i";
		push(@myJobs, "$jobName");
		$cmd        	= "$jobName=`qsub -o $path2qsub -e $path2qsub $QSUBint`";
		open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
		print $QSUB "$cmd\n";
		close $QSUB;

	}

	#*----------------------------------------------------------------------*
	# Change Targets.txt file for next iteration
	print "\n--------------------------------------------------------------------------------------------------\n";
	print "\n Changing '$myJobName' variable to FALSE and proceed";
	`/usr/bin/perl -p -i -e "s/$myJobName/$myJobName\_DONE/gi" $Targets`;

	#*----------------------------------------------------------------------*
	# Prepar file containing the jobs to run
	
	# Add the next job line to the $QSUB
	foreach( @myJobs ){ $_ = "\$".$_ ; }
	my $myJobsVec   = join(":", @myJobs);
	my $finalcmd    = "FINAL=\`qsub -N $iterateJobName -o $path2qsub -e $path2qsub -W depend=afterok\:$myJobsVec $IterateSH`";
	open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "$finalcmd\n";
	close $QSUB;

	#*----------------------------------------------------------------------*
	# Submit jobs to run

	print "\n\n--------------------------------------------------------------------------------------------------\n";
	print "\n Submitting job to cluster: \t `sh $QSUB` \n";
	`sh $QSUB`;

	#*----------------------------------------------------------------------*
	# Exit script

	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
	print "\n Exiting $myJobName section with no known error \n";
	print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n";

	exit 0;
}


#*----------------------------------------------------------------------*
# Running PeakCaller

if( $peakcalling =~ "TRUE" ){

	print "\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-\n";
	print "\n Run PeakCaller (SPP)\n";

	my $iterateJobName	= "Iterate_peakcalling";
	my $myJobName		= "peakcalling";
	my $path2qsub		= "$tmpscr/$myJobName/qsub";

	# Create file to store jobs in
	unless( -d "$tmpscr/$myJobName" )	{ `mkdir $tmpscr/$myJobName`; }
	unless( -d "$path2qsub" )		{ `mkdir $path2qsub`; }
	my $QSUB	= "$tmpscr/$myJobName/$myJobName\.sh";

	open $QSUB, ">", "$QSUB" or die "Can't open '$QSUB'";
	print $QSUB "#!/bin/bash\n";
	close $QSUB;
	`chmod 777 $QSUB`;
	print "\n Store all of the following '$myJobName' jobs in $QSUB \n";
	my @myJobsInputs;
	my @myJobsSamples;

	# Copy script and rreate folder
	`cp $path2ChIPseqScripts/PeakCalling.R $tmpscr`;

	foreach my $i (0 .. $#samples) {

		my $sample	= $samples[$i];
		my $input	= $allinputs[$i];
		unless( -d "$path2peakcalling/$sample\_fdr\_$fdr" )	{ `mkdir $path2peakcalling/$sample\_fdr\_$fdr`; }
		unless( -d "$path2peakcalling/$input\_fdr\_$fdr" )	{ `mkdir $path2peakcalling/$input\_fdr\_$fdr`; }		

		#-----------------------------------------------------------
		# Prepare a personal qsub script
		my $QSUBint  = "$tmpscr/$myJobName/$sample\_$myJobName\.sh";
		`cp $scrhead $QSUBint`;

		#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+		
		#-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+          IMPORTANT CODE HERE         -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
		my $code	= "$tmpscr/PeakCalling.R";
		my $cmd		= "Rscript $code $path2expFolder $sample $input $fdr $posopt $densityopt &>> $path2qsub/$sample\_peakcalling.log";
		`echo "$cmd" >> $QSUBint`;
                #--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--++--

		#---------------------------------------------
		# Keep track of the jobs in @myJobs
		my $jobName	= "$myJobName$i";
		push(@myJobsSamples, "$jobName");
		$cmd		= "$jobName=`qsub -o $path2qsub -e $path2qsub $QSUBint`";
		open $QSUB, ">>", "$QSUB" or die "Can't open '$QSUB'";
		print $QSUB "$cmd\n";
		close $QSUB;
	}


	#*----------------------------------------------------------------------*
        # Change Targets.txt file for next iteration
        print "\n--------------------------------------------------------------------------------------------------\n";
        print "\n Changing '$myJobName' variable to FALSE and proceed";
        `/usr/bin/perl -p -i -e "s/$myJobName/$myJobName\_DONE/gi" $Targets`;

        #*----------------------------------------------------------------------*
        # Prepar file containing the jobs to run

        # Add the next job line to the $filterQSUB
        foreach( @myJobsSamples ){ $_ = "\$".$_ ; }
        my $myJobsVec   = join(":", @myJobsSamples);
        my $finalcmd    = "FINA                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  