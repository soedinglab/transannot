use strict;
use warnings;

my ($in_fasta_contig, $out_file_prefix) = @ARGV;
# The Standard Code - avoiding Bio::Tools::CodonTable
my $start_codon = "ATG";
my @stop_codons = ("TAG","TAA","TGA");

# read the first sequence in the file as the contig:
open (my $in, "<", $in_fasta_contig) or die "could not open $in_fasta_contig for reading";
my $contig_seq = "";
my $line = <$in>;
while (defined $line)
{
	chomp $line;
	if ($line =~ m/^>/)
	{
		$line = <$in>;
		while ((defined $line) and ($line !~ m/^>/)) 
		{
			chomp($line);
			$contig_seq .= $line;
			$line = <$in>;
		}
		last;
	}
}
close ($in);
$contig_seq = uc $contig_seq;

my $all_frames_ref = generate_six_frames($contig_seq);

my @all_frags_0 = ();
my @all_frags_1 = ();
my @all_frags_2 = ();

foreach my $frame (@{$all_frames_ref})
{
	my ($frags_0_ref, $frags_1_ref, $frags_2_ref) = get_frags($frame);
	@all_frags_0 = (@all_frags_0,@{$frags_0_ref});
	@all_frags_1 = (@all_frags_1,@{$frags_1_ref});
	@all_frags_2 = (@all_frags_2,@{$frags_2_ref});
}

my $all_frags_0_str = join("\n",(@all_frags_0));
my $all_frags_1_str = join("\n",(@all_frags_1));
my $all_frags_2_str = join("\n",(@all_frags_2));

open (my $out0, ">", ($out_file_prefix . "_mode_0.txt")) or die "could not open $out_file_prefix\_mode_0.txt for writing";
print $out0 "$all_frags_0_str\n";
close ($out0);

open (my $out1, ">", ($out_file_prefix . "_mode_1.txt")) or die "could not open $out_file_prefix\_mode_1.txt for writing";
print $out1 "$all_frags_1_str\n";
close ($out1);

open (my $out2, ">", ($out_file_prefix . "_mode_2.txt")) or die "could not open $out_file_prefix\_mode_2.txt for writing";
print $out2 "$all_frags_2_str\n";
close ($out2);

sub generate_six_frames
{
	my ($in_contig_seq) = @_;
	# break to chars and generate reverse compliment
	my @all_chars = split(//,$in_contig_seq);
	my $rev_comp = join("",(reverse(@all_chars)));
	$rev_comp =~ tr/ACGT/TGCA/;
	my @all_rev_comp_chars = split(//,$rev_comp);
	
	# this will keep all frames, ready for translation
	my @all_frames;
	
	# forward frames
	my @frame_1 = @all_chars;
	push(@all_frames, \@frame_1);
	
	shift @all_chars;
	my @frame_2 = @all_chars;
	push(@all_frames, \@frame_2);
	
	shift @all_chars;
	my @frame_3 = @all_chars;
	push(@all_frames, \@frame_3);
	
	# reverse frames
	my @frame_r1 = @all_rev_comp_chars;
	push(@all_frames, \@frame_r1);
	
	shift @all_rev_comp_chars;
	my @frame_r2 = @all_rev_comp_chars;
	push(@all_frames, \@frame_r2);
	
	shift @all_rev_comp_chars;
	my @frame_r3 = @all_rev_comp_chars;
	push(@all_frames, \@frame_r3);
	
	# if needed, remove 1 or 2 nucleotides from the end so it divides in three
	my @all_frames_scalar;
	for(my $i = 0; $i < @all_frames; $i++)
	{
		my $curr_frame_ref = $all_frames[$i];
		my @curr_frame = @{$curr_frame_ref};
		my $num_to_pop = 0;
		$num_to_pop = scalar(@curr_frame) % 3;
		foreach (1..$num_to_pop)
		{
			pop @curr_frame;
		}
		$all_frames[$i] = \@curr_frame;
		$all_frames_scalar[$i] = join("",@curr_frame);
	}
	return (\@all_frames_scalar);
}

sub get_AA
{
	my ($codon) = @_;
	# we can replace this with:
	# my $codonTable_obj = Bio::Tools::CodonTable->new( -id => $table_code); 
	# my $AA = $codonTable_obj->translate($codon);
	if ($codon eq $start_codon)
	{
		return "M";
	}
	if (($codon eq $stop_codons[0]) or ($codon eq $stop_codons[1]) or ($codon eq $stop_codons[2]))
	{
		return "*";
	}
	else
	{
		return "X";
	}
}

sub get_frags
{
	my ($DNASequence) = @_;
	my $seq_length = length($DNASequence);
	if (($seq_length % 3) != 0) 
	{
		die "not divisible by 3, should not be here\n";
	}
	
	my @raw_frags = ();
	my @curr_frag_codons = ();
	my $i = 0;
	my $AA = "";
	while ( $i < $seq_length - 2 ) 
	{
		my $codon = substr($DNASequence, $i, 3);
		$AA = get_AA($codon);
		if ($AA ne '*')
		{
			push(@curr_frag_codons, $codon);
		}
		else
		{
			if (@curr_frag_codons > 0)
			{
				push(@raw_frags,[@curr_frag_codons]);
			}
			@curr_frag_codons = ();
		}
		$i += 3;
	}
	# push last time of the last codon was not a stop
	if ((@curr_frag_codons > 0) and ($AA ne '*'))
	{
		push(@raw_frags,[@curr_frag_codons]);
	}
	
	my @all_frags_any_start = @raw_frags;
	
	# Met to stop
	my @all_frags_Met_start = shift(@raw_frags); # take first as is
	foreach my $frag_codons_ref (@raw_frags)
	{
		my $saw_Met = "no";
		my @frag_codons_first_is_met = ();
		foreach my $frag_codon (@{$frag_codons_ref})
		{
			if ((get_AA($frag_codon) eq 'M') or ($saw_Met eq "yes"))
			{
				push (@frag_codons_first_is_met, $frag_codon);
				$saw_Met = "yes";
			}
		}
		if (@frag_codons_first_is_met > 0)
		{
			push (@all_frags_Met_start, \@frag_codons_first_is_met);
		}
	}
	
	# Met to stop - no Met in the middle
	my @all_frags_Met_start_no_Met_middle = ();
	foreach my $frag_codons_ref (@all_frags_Met_start)
	{
		my @frag_codons_no_met_in_the_middle = ();
		foreach my $frag_codon (@{$frag_codons_ref})
		{
			if (get_AA($frag_codon) eq 'M')
			{
				@frag_codons_no_met_in_the_middle = ();	
			}
			push (@frag_codons_no_met_in_the_middle, $frag_codon);
		}
		if (@frag_codons_no_met_in_the_middle > 0)
		{
			push (@all_frags_Met_start_no_Met_middle, \@frag_codons_no_met_in_the_middle);
		}
		else
		{
			# this case captures first fragment with no M at all
			push (@all_frags_Met_start_no_Met_middle, $frag_codons_ref);
		}
	}
	
	return(get_str_frags(@all_frags_Met_start), get_str_frags(@all_frags_any_start), get_str_frags(@all_frags_Met_start_no_Met_middle));
}

sub get_str_frags
{
	my (@frags) = @_;
	my @frags_str = ();
	foreach my $frag_codons_ref (@frags)
	{
		my $frag_str = join("",@{$frag_codons_ref});
		push (@frags_str, $frag_str);
	}
	return (\@frags_str);
}
