# NAME

XML::CompileX::Schema::Loader - Recursively compile a web service proxy

# VERSION

version 0.002

# SYNOPSIS

    use XML::CompileX::Schema::Loader;

    my $wsdl = XML::CompileX::Schema::Loader->new(
                uri => 'http://example.com/foo.wsdl' );
    $wsdl->proxy->compileCalls();
    my ( $answer, $trace ) = $wsdl->proxy->call( hello => {name => 'Joe'} );

# DESCRIPTION

From the
[description of XML::Compile::WSDL11](https://metacpan.org/pod/XML::Compile::WSDL11#DESCRIPTION):

> When the \[WSDL\] definitions are spread over multiple files you will need to
> use [addWSDL()](https://metacpan.org/pod/XML::Compile::WSDL11#Extension) (wsdl) or
> [importDefinitions()](https://metacpan.org/pod/XML::Compile::Schema#Administration)
> (additional schema's)
> explicitly. Usually, interreferences between those files are broken.
> Often they reference over networks (you should never trust). So, on
> purpose you **must explicitly load** the files you need from local disk!
> (of course, it is simple to find one-liners as work-arounds, but I will
> to tell you how!)

This module implements that work-around, recursively parsing and compiling a
WSDL specification and any imported definitions and schemas. The wrapped WSDL
is available as a `proxy` attribute.

It also provides a hook to use any [CHI](https://metacpan.org/pod/CHI) driver so that retrieved files
may be cached locally, reducing dependence on network-accessible definitions.

You may also provide your own [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) (sub)class
instance, possibly to correct on-the-fly any broken interreferences between
files as warned above.

# ATTRIBUTES

## cache

A read-only reference to the underlying [CHI::Driver](https://metacpan.org/pod/CHI::Driver) object used
to cache schemas.

## cache\_parameters

A hash reference settable at construction to pass parameters to the [CHI](https://metacpan.org/pod/CHI)
module used to cache schemas.  By default nothing is cached.

## options

Optional hash reference of additional parameters to pass to the
[XML::Compile::WSDL11](https://metacpan.org/pod/XML::Compile::WSDL11) constructor. Defaults to:

    { allow_undeclared => 1 }

## proxy

Retrieves the resulting [XML::Compile::WSDL11](https://metacpan.org/pod/XML::Compile::WSDL11) object.
Any definitions are retrieved and compiled on first access to this attribute.
If there are problems retrieving any files, an
[HTTP::Exception](https://metacpan.org/pod/HTTP::Exception) is thrown with the details.

## uri

Required string or [URI](https://metacpan.org/pod/URI) object pointing to a WSDL file to compile.

## user\_agent

Optional instance of an [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) that will be used to
get all WSDL and XSD content when the proxy cache is built.

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc XML::CompileX::Schema::Loader

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [http://metacpan.org/release/XML-CompileX-Schema-Loader](http://metacpan.org/release/XML-CompileX-Schema-Loader)

- Search CPAN

    The default CPAN search engine, useful to view POD in HTML format.

    [http://search.cpan.org/dist/XML-CompileX-Schema-Loader](http://search.cpan.org/dist/XML-CompileX-Schema-Loader)

- AnnoCPAN

    The AnnoCPAN is a website that allows community annotations of Perl module documentation.

    [http://annocpan.org/dist/XML-CompileX-Schema-Loader](http://annocpan.org/dist/XML-CompileX-Schema-Loader)

- CPAN Ratings

    The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

    [http://cpanratings.perl.org/d/XML-CompileX-Schema-Loader](http://cpanratings.perl.org/d/XML-CompileX-Schema-Loader)

- CPAN Forum

    The CPAN Forum is a web forum for discussing Perl modules.

    [http://cpanforum.com/dist/XML-CompileX-Schema-Loader](http://cpanforum.com/dist/XML-CompileX-Schema-Loader)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/XML-CompileX-Schema-Loader](http://cpants.cpanauthors.org/dist/XML-CompileX-Schema-Loader)

- CPAN Testers

    The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/X/XML-CompileX-Schema-Loader](http://www.cpantesters.org/distro/X/XML-CompileX-Schema-Loader)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=XML-CompileX-Schema-Loader](http://matrix.cpantesters.org/?dist=XML-CompileX-Schema-Loader)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=XML::CompileX::Schema::Loader](http://deps.cpantesters.org/?module=XML::CompileX::Schema::Loader)

## Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
[https://github.com/mjgardner/xml-compile-wsdl11-recursive/issues](https://github.com/mjgardner/xml-compile-wsdl11-recursive/issues).
You will be automatically notified of any progress on the
request by the system.

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/mjgardner/xml-compile-wsdl11-recursive](https://github.com/mjgardner/xml-compile-wsdl11-recursive)

    git clone git://github.com/mjgardner/xml-compile-wsdl11-recursive.git

# AUTHOR

Mark Gardner <mjgardner@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
