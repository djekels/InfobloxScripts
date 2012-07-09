#!/usr/bin/perl -w

use Infoblox;
use Net::Netrc;
use Getopt::Std;
#use XML::Dumper;
use strict;

my $bloxmaster = 'ryeinfoblox.global.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my %options;
getopts("a:t:c: ", \%options);

my $alias = $options{a} or die;
my $target = $options{t} or die;
my $cname = Infoblox::DNS::Record::CNAME->new(
	'canonical'=>$target,
	'name'=>$alias,
	);

$cname->comment($options{c}) if ($options{c});

$session->add($cname) || die $session->status_detail();
