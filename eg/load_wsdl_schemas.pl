#!perl

use Modern::Perl '2010';
use List::Util 1.33 'any';
use XML::Compile::SOAP11;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::SOAP::Util 'WSDL11';
use XML::Compile::Util ':constants';
use XML::LibXML 1.70;

my $wsdl = XML::Compile::WSDL11->new;
for my $document ( map { XML::LibXML->load_xml( location => $_ ) } @ARGV ) {
    my $namespace = $document->documentElement->namespaceURI;
    if ( $namespace eq WSDL11 ) { $wsdl->addWSDL($document) }
    elsif ( any { $namespace eq $_ } ( SCHEMA1999, SCHEMA2000, SCHEMA2001 ) )
    {
        $wsdl->importDefinitions($document);
    }
}

$wsdl->compileCalls;
say for OPERATIONS => sort map { $_->name } $wsdl->operations;
say for NAMESPACES => sort map { $_->list } $wsdl->namespaces;
