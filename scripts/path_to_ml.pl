#!/usr/bin/perl -w
use strict;
use XML::Writer;
use IO::File;

my $output = IO::File->new(">-");

my $writer = XML::Writer->new(OUTPUT => $output);

$writer->xmlDecl("UTF-8", "no");
$writer->startTag("graphml", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns" => "http://graphml.graphdrawing.org/xmlns");
$writer->startTag("graph");

$writer->startTag("node", "id" => "A0");
	$writer->startTag("data", "key" => "entry");
		$writer->characters("true");
	$writer->endTag("data");
$writer->endTag("node");

my $nid = 0;

while (<>) {
	chomp;
	/^[01] .* ([0-9]+)$/;
	my $line = $1;

	$writer->startTag("node", "id" => "A" . ($nid + 1));
	if (eof()) {
		$writer->startTag("data", "key" => "violation");
			$writer->characters("true");
		$writer->endTag("data");
	}
	$writer->endTag("node");

	$writer->startTag("edge", "source" => "A$nid",
			"target" => "A" . ($nid + 1));
		$writer->startTag("data", "key" => "startline");
			$writer->characters($line);
		$writer->endTag("data");
	$writer->endTag("edge");

	$nid++;
}

$writer->endTag("graph");
$writer->endTag("graphml");
$writer->end();
$output->close();

1;
