package XML::Compile::WSDL11::Recursive;

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use utf8;
use Moo;
use MooX::Types::MooseLike::Base qw(HashRef InstanceOf);
use CHI;
use HTTP::Exception;
use LWP::UserAgent;
use URI;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::Util 'SCHEMA2001';
use XML::Compile::SOAP::Util 'WSDL11';
use XML::LibXML;

has cache => (
    is       => 'lazy',
    isa      => InstanceOf('CHI::Driver'),
    init_arg => undef,
    default  => sub { CHI->new( %{ shift->cache_parameters } ) },
);

has cache_parameters => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { { driver => 'Null' } },
);

has options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { { allow_undeclared => 1 } },
);

has proxy => (
    is       => 'lazy',
    isa      => InstanceOf('XML::Compile::WSDL11'),
    init_arg => undef,
);

sub _build_proxy {
    my $self = shift;

    my $uri   = $self->uri;
    my $cache = $self->cache;

    my $proxy = $self->_build_proxy_cache(
        XML::Compile::WSDL11->new(
            $self->_get_uri_content_ref($uri),
            %{ $self->options },
        ),
        $uri,
    );
    $proxy->importDefinitions(
        $cache->get_multi_arrayref(
            [ grep { $cache->is_valid($_) } $cache->get_keys ],
        ),
    );
    return $proxy;
}

sub _build_proxy_cache {
    my ( $self, $proxy, @locations ) = @_;

    my $cache = $self->cache;

    for my $uri ( grep { not $cache->is_valid( $_->as_string ) } @locations )
    {
        my $content_ref = $self->_get_uri_content_ref($uri);
        my $document = XML::LibXML->load_xml( string => $content_ref );
        $cache->set( $uri->as_string => $document->toString );

        if ( 'definitions' eq $document->documentElement->getName ) {
            $proxy->addWSDL($content_ref);
        }
        $proxy->importDefinitions($content_ref);

        if ( my @imports
            = map { URI->new_abs( $_->getAttribute('schemaLocation'), $uri ) }
            $document->getElementsByTagNameNS( (SCHEMA2001) => 'import' ) )
        {
            $proxy = $self->_build_proxy_cache( $proxy, @imports );
        }
        if ( my @imports
            = map { URI->new_abs( $_->getAttribute('location'), $uri ) }
            $document->getElementsByTagNameNS( (WSDL11) => 'import' ) )
        {
            $proxy = $self->_build_proxy_cache( $proxy, @imports );
        }
        undef $document;
    }
    return $proxy;
}

has uri => (
    is       => 'ro',
    isa      => InstanceOf('URI'),
    required => 1,
    coerce   => sub { URI->new( $_[0] ) },
);

has user_agent => (
    is      => 'lazy',
    isa     => InstanceOf('LWP::UserAgent'),
    default => sub { LWP::UserAgent->new() },
);

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

# ABSTRACT: Recursively compile a web service proxy

__END__

=head1 SYNOPSIS

    use XML::Compile::WSDL11::Recursive;

    my $wsdl = XML::Compile::WSDL11::Recursive->new(
                uri => 'http://example.com/foo.wsdl' );
    $wsdl->proxy->compileCalls();
    my ( $answer, $trace ) = $wsdl->proxy->call( hello => {name => 'Joe'} );

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
is available as a C<proxy> attribute.

It also provides a hook to use any L<CHI|CHI> driver so that retrieved files
may be cached locally, reducing dependence on network-accessible definitions.

You may also provide your own L<LWP::UserAgent|LWP::UserAgent> (sub)class
instance, possibly to correct on-the-fly any broken interreferences between
files as warned above.

=attr cache

A read-only reference to the underlying L<CHI::Driver|CHI::Driver> object used
to cache schemas.

=attr cache_parameters

A hash reference settable at construction to pass parameters to the L<CHI|CHI>
module used to cache schemas.  By default nothing is cached.

=attr options

Optional hash reference of additional parameters to pass to the
L<XML::Compile::WSDL11|XML::Compile::WSDL11> constructor. Defaults to:

    { allow_undeclared => 1 }
 
=attr proxy

Retrieves the resulting L<XML::Compile::WSDL11|XML::Compile::WSDL11> object.

=attr uri

Required string or L<URI|URI> object pointing to a WSDL file to compile.

=attr user_agent

Optional instance of an L<LWP::UserAgent|LWP::UserAgent> that will be used to
get all WSDL and XSD content when the proxy cache is built.
