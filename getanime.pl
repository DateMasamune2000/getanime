#!/usr/bin/perl

use DBI;
use JSON;
use Term::ReadKey;
use LWP::Simple;

$json_text = get('http://api.jikan.moe/v4/seasons/upcoming');

die "Failed to get content\n", unless defined $json_text;

my $json = JSON->new;
my $data = $json->decode($json_text);

print 'Enter password:';
ReadMode('noecho');
my $password = ReadLine(0);
chop($password);
ReadMode('restore');

my $dsn = "DBI:MariaDB:database=anime;host=localhost";
my $dbh = DBI->connect($dsn, '<enter username>', $password);

for (@{$data->{data}}) {
	print $_->{url}."\n";

	my $date = "$_->{aired}{prop}{from}{year}"
	."-"."$_->{aired}{prop}{from}{month}"
	."-"."$_->{aired}{prop}{from}{day}";

	print $_->{aired}{from}."\n";

	my $sth = $dbh->prepare('INSERT INTO upcoming VALUES(?, ?, ?, ?);');
	$sth->execute($_->{mal_id}, $_->{url}, $_->{source}, $date);

	my $id = $_->{mal_id};

	for (@{$_->{titles}}) {
		if ($_->{type} eq 'Default') {
			print "\t$_->{title}\n";
			my $sth = $dbh->prepare('INSERT INTO titles VALUES(?, ?);');
			$sth->execute($id, $_->{title});
		}
	}
}

$dbh->disconnect();
