#!perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::Most;
use Test::LWP::UserAgent;
use HTTP::Response;
use HTTP::Status qw(:constants status_message);
use Path::Tiny;
use URI;
use URI::file;
use XML::Compile::WSDL11::Recursive;

my $user_agent = Test::LWP::UserAgent->new( network_fallback => 1 );
$user_agent->map_response( 'example.com' => \&examplecom_responder );

my $wsdl = new_ok(
    'XML::Compile::WSDL11::Recursive' => [
        uri => URI::file->new_abs('t/stockquote/stockquoteservice.wsdl'),
        user_agent => $user_agent,
    ],
    'stockquoteservice WSDL',
);
lives_and(
    sub { isa_ok( $wsdl->proxy => 'XML::Compile::WSDL11', 'WSDL proxy' ) } =>
        'WSDL proxy' );
lives_ok( sub { $wsdl->proxy->compileCalls() } => 'compileCalls' );

done_testing;

sub examplecom_responder {
    my $request = shift;

    my $path = $request->uri->path;
    $path =~ s(^/)();

    my $response = HTTP::Response->new( HTTP_OK => status_message(HTTP_OK) );
    $response->content( path( t => $path )->slurp );
    return $response;
}
