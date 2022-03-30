use strict;
use warnings;

my ($in_perl_frags, $in_mmseqs2_frags) = @ARGV;

open (my $in, "<", $in_perl_frags) or die "could not open $in_perl_frags for reading";
my @perl_frags = <$in>;
chomp (@perl_frags);
close ($in);
my %perl_frags_hash;
my $num_perl_frags = @perl_frags;
foreach my $perl_frag (@perl_frags)
{
	$perl_frags_hash{$perl_frag} = 1;
}

my %mmseqs2_frags_hash;
my $num_mmseqs2_frags = parse_mmseqs2_orfs($in_mmseqs2_frags, \%mmseqs2_frags_hash);

if ($num_perl_frags != $num_mmseqs2_frags)
{
	die "Disagreement in number of fragments between $in_perl_frags and $in_mmseqs2_frags: Perl: $num_perl_frags, MMseqs2: $num_mmseqs2_frags\n";
}
else
{
	print "Both have $num_perl_frags fragments - that's good, continuing to compare frags\n";
}

print "comparing Perl to MMseqs2:\n";
compare_unique_frags(\%perl_frags_hash, \%mmseqs2_frags_hash);
print "ALL OK there!\n";

print "comparing MMseqs2 to Perl:\n";
compare_unique_frags(\%mmseqs2_frags_hash, \%perl_frags_hash);
print "ALL OK there!\n";
print "Done checking\n";

sub compare_unique_frags
{
	my ($hash_ref1, $hash_ref_2) = @_;
	foreach my $frag (keys %{$hash_ref1})
	{
		if (! exists $hash_ref_2->{$frag})
		{
			die "Missing $frag\n";
		}
	}
}



sub parse_mmseqs2_orfs
{
	my ($in_mmseqs2_frags, $mmseqs2_frags_hash_ref) = @_;
	open (my $in, "<", $in_mmseqs2_frags) or die "could not open $in_mmseqs2_frags for reading";
	my $line = <$in>;
	my $num_records = 0;
	while (defined $line)
	{
		$line =~ s/\x00//; # remove null byte
		chomp($line);
		if ($line ne '')
		{
			$line = uc $line;
			# remove invisible chars:
			if ($line =~ m/([A-Z]+)/)
			{
				$line = $1;
			}
			if ((length($line) % 3) != 0)
			{
				die "MMseqs2 produced a fragment that is not divisible by 3: '$line'\n";
			}
			$mmseqs2_frags_hash_ref->{$line} = 1;
			$num_records++;
		}
		$line = <$in>;

	}
	close ($in);
	return ($num_records);
}