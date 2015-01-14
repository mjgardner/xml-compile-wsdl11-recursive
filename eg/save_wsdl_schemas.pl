#!perl

use Modern::Perl '2010';
use LWP::UserAgent;
use Path::Tiny 0.018;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::CompileX::Schema::Loader;

my $user_agent = LWP::UserAgent->new;
$user_agent->set_my_handler( response_done => \&response_done_handler );
my $transport
    = XML::Compile::Transport::SOAPHTTP->new( user_agent => $user_agent );
my $wsdl   = XML::Compile::WSDL11->new;
my $loader = XML::CompileX::Schema::Loader->new(
    uris       => \@ARGV,
    user_agent => $user_agent,
    wsdl       => $wsdl,
);
$loader->collect_imports;
$wsdl->compileCalls( transport => $transport );

sub response_done_handler {
    my ( $response, $ua, $h ) = @_;

    my $path = Path::Tiny->cwd->child(
        grep    {$_}
            map { $response->base->canonical->$_ }
            qw(scheme authority path_segments query fragment),
    );

    print STDERR 'Saving ', $response->base, " to $path...";
    $path->parent->mkpath( {} );
    $path->spew( $response->decoded_content );
    say STDERR 'done';

    return;
}
