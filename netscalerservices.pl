#!/usr/bin/perl -w
#
# I wrote this to add an alias to a host record
#
use Infoblox;
use Net::Netrc;
use XML::Dumper;
use strict;

my @countryprefixes = qw/
za
jt
cy
lb
mt
mu
ct
om
ae
is
/;

my %hostorder = ('avonmsqweb1.avon.net'=>1, 'avonmsqweb2.avon.net'=>2, 'avonmsqweb3.rye.avon.com'=>3);
my $bloxmaster = 'ryeinfoblox.global.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

while ((my $host, my $num) = each %hostorder)
	{
	my @aliases = map{"qapshopapi$_$num.ryenlbqadmz.avon.net"} @countryprefixes;
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

		if ($result) { print "Added alias "; print @aliases; print "\n\n" }
			else {warn $session->status_detail()}
		}
	}
