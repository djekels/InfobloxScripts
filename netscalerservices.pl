#!/usr/bin/perl -w
#
# I wrote this to add an alias to a host record
#
use Infoblox;
use Getopt::Std;
use Net::Netrc;
use XML::Dumper;
use strict;

my @countryprefixes = (
'ae',
'al',
'ba',
'bg',
'ct',
'cy',
'cz',
'de',
'ee',
'eg',
'es',
'fi',
'fr',
'ge',
'gr',
'hr',
'hu',
'ie',
'is',
'it',
'jt',
'kg',
'kz',
'lb',
'lt',
'ma',
'md',
'me',
'mk',
'mt',
'mu',
'om',
'pl',
'pt',
'ro',
'rs',
'ru',
'sa',
'si',
'sk',
'tn',
'tr',
'ua',
'uk',
'za',
);

my @hosts = ('ryelxwebecw2.avon.net', 'ryelxwebecw1.qa.youravon.com');
$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options;
getopts("m: ", \%options);
my $bloxmaster = $options{m};
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

foreach my $host (@hosts)
	{
	(my $num) = $host =~ /(\d)/;
	my @aliases = map{"qaf$_$num.ryenlbqadmz.avon.net"} @countryprefixes;
	my $hostrecord = $session->get(object=>'Infoblox::DNS::Host',
			name=>$host
			);
	unless ($hostrecord) {die ($session->status_detail())}

	local $, = "\n\t";
	print "Current aliases are:\n\t";
	print @{$hostrecord->aliases};
	print "\n\n";

	if (@aliases)
		{
		push (@{$hostrecord->aliases}, @aliases);
		my $result = $session->modify($hostrecord);

		if ($result) { print "Added alias " . @aliases }
			else {warn $session->status_detail()}
		}
	}


sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
        -m Infoblox Grid master
        -h Host Record
	-a Desired Alias\n";
        exit 0;
        }   
