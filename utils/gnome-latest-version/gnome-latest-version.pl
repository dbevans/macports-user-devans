#!/opt/local/bin/perl

use Getopt::Long;
use Net::FTP;

my $ftp_host   = "ftp.gnome.org";
my $ftp_user   = "anonymous";
my $ftp_passwd = "devans\@macports.org";
my $ftp_base   = "/pub/gnome/sources";
my $branch     = "";
my $debug      = 0;
my $names_only = 0;

my $result = GetOptions(
	"host=s"     => \$ftp_host,
	"user=s"     => \$ftp_user,
	"password=s" => \$ftp_passwd,
	"base=s"     => \$ftp_base,
	"branch=s"   => \$branch,
	"debug"      => \$debug,
	"names_only" => \$names_only
);

my $nargs  = scalar(@ARGV);
my @gnames = @ARGV;

my $ftp = Net::FTP->new( $ftp_host, Debug => $debug );
$ftp->login( $ftp_user, $ftp_passwd );

if ( $nargs < 1 ) {
	$ftp->cwd($ftp_base);
	@gnames = $ftp->ls;
	$nargs  = scalar(@gnames);
}

if ($debug) {
	print "$nargs arguments:";
	if ( $nargs > 0 ) {
		foreach my $gname (@gnames) { print "    $gname\n"; }
	}
	if ( $branch ne "" ) { print "Print branch $branch only.\n"; }
}

foreach my $gname (@gnames) {
	$ftp->cwd("$ftp_base/$gname") or next;
	my @lines = $ftp->ls;

	my $major = -1;
	my $minor = -1;

	foreach my $line (@lines) {
		if ( $line =~ m/^(\d+)\.(\d+)$/ ) {
			if ( $branch ne "$major.$minor" ) {
				if ( $1 > $major ) {
					$major = $1;
					$minor = $2;
				}
				elsif ( ( $1 == $major ) && ( $2 > $minor ) ) {
					$minor = $2;
				}
			}
		}
	}

	undef @lines;

	if ($debug) { print "Latest branch for $gname is $major.$minor\n"; }

	if ( ( $major >= 0 ) && ( $minor >= 0 ) ) {

		if ( ( $branch eq "" ) || ( $branch eq "$major.$minor" ) ) {

			$ftp->cwd("$ftp_base/$gname/$major.$minor")
			  or die
			  "$gname: cannot change to working directory $major.$minor: ",
			  $ftp->message;

			my @lines = $ftp->ls;

			$version = "$major.$minor";

			foreach my $line (@lines) {
				if ( $line =~ m/^LATEST-IS-(.*)$/ ) {
					$version = $1;
				}
			}

			if ($debug) {
				print "Latest version for $gname is $version\n";
			}
			elsif ($names_only) {
				print "$gname\n";
			}
			else {
				print "$gname $version\n";
			}

		}

	}

}

$ftp->quit;

