package XML::CompileX::Schema::Loader;

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use utf8;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef InstanceOf);
use HTTP::Exception;
use List::MoreUtils 'uniq';
use LWP::UserAgent;
use URI;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Util 'SCHEMA2001';
use XML::Compile::SOAP::Util 'WSDL11';
use XML::LibXML;

has uris => (
    is       => 'rwp',
    isa      => ArrayRef [ InstanceOf ['URI'] ],
    required => 1,
    coerce   => sub {
        'ARRAY' eq ref $_[0]
            ? [ map { URI->new($_) } @{ $_[0] } ]
            : [ URI->new( $_[0] ) ];
    },
);

has user_agent => (
    is      => 'lazy',
    isa     => InstanceOf ['LWP::UserAgent'],
    default => sub { LWP::UserAgent->new },
);

has wsdl => ( is => 'lazy', isa => InstanceOf ['XML::Compile::WSDL11'] );

sub _build_wsdl {
    my $self = shift;
    my $wsdl = XML::Compile::WSDL11->new(
        $self->_get_uri_content_ref( $self->uris->[0] ) );
    for ( $self->uris->[ 1 .. $#{ $self->uris } ] ) {
        $wsdl->addWSDL( $self->_get_uri_content_ref($_) );
    }
    return $wsdl;
}

sub collect_imports {
    my ( $self, @uri ) = @_;
    my $wsdl = $self->wsdl;
    $self->_set_uris(
        [ @uri = uniq @uri, map { $_->as_string } @{ $self->uris } ] );
    for my $uri ( @{ $self->uris } ) {
        $wsdl->addWSDL( $self->_get_uri_content_ref($uri) );
        $wsdl = $self->_do_imports( $wsdl, $uri );
    }
    $wsdl->importDefinitions( [ values %{ $self->_imports } ] );
    return $wsdl;
}

has _imports => ( is => 'rw', isa => HashRef, default => sub { {} } );

sub _do_imports {
    my ( $self, $wsdl, @locations ) = @_;

    for my $uri ( grep { not exists $self->_imports->{ $_->as_string } }
        @locations )
    {
        my $content_ref = $self->_get_uri_content_ref($uri);
        my $doc = XML::LibXML->load_xml( string => $content_ref );
        $self->_imports(
            +{ %{ $self->_imports }, $uri->as_string => $content_ref } );

        if ( 'definitions' eq $doc->documentElement->getName ) {
            $wsdl->addWSDL($content_ref);
        }
        $wsdl->importDefinitions($content_ref);

        my @imports = (
            _collect( 'location', $uri, $doc, WSDL11, 'import' ),
            map { _collect( 'schemaLocation', $uri, $doc, SCHEMA2001, $_ ) }
                qw(import include),
        );
        if (@imports) { $wsdl = $self->_do_imports( $wsdl, @imports ) }
        undef $doc;
    }
    return $wsdl;
}

sub _collect {
    my ( $attr, $uri, $document, $ns, $element ) = @_;
    return
        map { URI->new_abs( $_->getAttribute($attr), $uri ) }
        $document->getElementsByTagNameNS( $ns => $element );
}

sub _get_uri_content_ref {
    my ( $self, $uri ) = @_;
    my $response = $self->user_agent->get($uri);
    if ( $response->is_error ) {
        HTTP::Exception->throw( $response->code,
            status_message => sprintf '"%s": %s' =>
                ( $uri->as_string, $response->message // q{} ) );
    }
    return $response->decoded_content( ref => 1, raise_error => 1 );
}

1;

# ABSTRACT: Load a web service and its dependencies for XML::Compile::WSDL11

__END__

=head1 SYNOPSIS

    use XML::Compile::WSDL11;
    use XML::CompileX::Schema::Loader;
    use LWP::Simple 'get';

    my $wsdl   = XML::Compile::WSDL11->new(get('http://example.com/foo.wsdl'));
    my $loader = XML::CompileX::Schema::Loader->new(
        wsdl => $wsdl,
        uris => 'http://example.com/foo.wsdl',
    );
    $loader->collect_imports;
    $wsdl->compileCalls;
    my ( $answer, $trace ) = $wsdl->call( hello => {name => 'Joe'} );

=head1 DESCRIPTION

From the
L<description of XML::Compile::WSDL11|XML::Compile::WSDL11/DESCRIPTION>:

=over

When the [WSDL] definitions are spread over multiple files you will need to
use L<addWSDL()|XML::Compile::WSDL11/"Extension"> (wsdl) or
L<importDefinitions()|XML::Compile::Schema/"Administration">
(additional schema's)
explicitly. Usually, interreferences between those files are broken.
Often they reference over networks (you should never trust). So, on
purpose you B<must explicitly load> the files you need from local disk!
(of course, it is simple to find one-liners as work-arounds, but I will
to tell you how!)

=back

This module implements that work-around, recursively parsing and compiling a
WSDL specification and any imported definitions and schemas. The wrapped WSDL
is available as a C<wsdl> attribute.

You may also provide your own L<LWP::UserAgent|LWP::UserAgent> (sub)class
instance, possibly to correct on-the-fly any broken interreferences between
files as warned above.  You can also provide a caching layer, as with
L<WWW::Mechanize::Cached|WWW::Mechanize::Cached> which is a sub-class of
L<WWW::Mechanize|WWW::Mechanize> and L<LWP::UserAgent|LWP::UserAgent>.

=attr wsdl

An L<XML::Compile::WSDL11|XML::Compile::WSDL11> instance. If you do not set
this, a generic instance will be created with the XML from the URIs in C<uris>
added. If there are problems retrieving any files, an
L<HTTP::Exception|HTTP::Exception> is thrown with the details.

=attr uris

Required string or L<URI|URI> object, or a reference to an array of the same,
that points to WSDL file(s) to compile.

=attr user_agent

Optional instance of an L<LWP::UserAgent|LWP::UserAgent> that will be used to
get all WSDL and XSD content.

=method collect_imports

Loops through all C<uris>, adding them as WSDL documents to C<wsdl> and then
importing all definitions, schemas, included and imported definition and schema
locations.  You should call this before calling any of the L<compilers in
XML::Compile::WSDL11|XML::Compile::WSDL11/Compilers> to ensure that any
dependencies have been imported.
