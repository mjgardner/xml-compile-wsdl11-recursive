#!perl

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::Most tests => 6;
use IO::Prompt::Tiny 'prompt';
use CHI;
use Const::Fast;
use Test::TempDir::Tiny;
use WWW::Mechanize::Cached;
use XML::Compile::WSDL11;
use XML::Compile::Transport::SOAPHTTP;
use XML::CompileX::Schema::Loader;

SKIP: {
    skip 'optional NetSuite tests' => 6 if not $ENV{PERL_TEST_NETSUITE};

    #use Log::Report mode => 'DEBUG';

    const my $SUITETALK_WSDL =>
        'https://webservices.netsuite.com/wsdl/v2014_2_0/netsuite.wsdl';

    my $cache_dir  = tempdir;
    my $user_agent = WWW::Mechanize::Cached->new(
        cache => CHI->new( driver => 'File', root_dir => $cache_dir ) );
    my $transport
        = XML::Compile::Transport::SOAPHTTP->new( user_agent => $user_agent );
    my $wsdl = XML::Compile::WSDL11->new(
        $user_agent->get($SUITETALK_WSDL)
            ->decoded_content( ref => 1, raise_error => 1 ),
        allow_undeclared => 1,
    );

    my $loader = new_ok(
        'XML::CompileX::Schema::Loader' => [
            uris       => $SUITETALK_WSDL,
            user_agent => $user_agent,
            wsdl       => $wsdl,
        ] => 'SuiteTalk WSDL',
    );
    lives_and(
        sub {
            isa_ok( $loader->collect_imports,
                'XML::Compile::WSDL11' => 'collect_imports' );
        } => 'collect_imports',
    );
    lives_ok(
        sub { $wsdl->compileCalls( transport => $transport ) } =>
            'compileCalls' );

    cmp_bag(
        [ keys %{ $loader->wsdl->index } ],
        [qw(binding message port portType service)] =>
            'WSDL definition classes',
    );

    cmp_bag(
        [ map { $_->name } $loader->wsdl->operations ],
        [   qw(
                add
                addList
                asyncAddList
                asyncDeleteList
                asyncGetList
                asyncInitializeList
                asyncSearch
                asyncUpdateList
                asyncUpsertList
                attach
                changeEmail
                changePassword
                checkAsyncStatus
                delete
                deleteList
                detach
                get
                getAll
                getAsyncResult
                getBudgetExchangeRate
                getConsolidatedExchangeRate
                getCurrencyRate
                getCustomizationId
                getDataCenterUrls
                getDeleted
                getItemAvailability
                getList
                getPostingTransactionSummary
                getSavedSearch
                getSelectValue
                getServerTime
                initialize
                initializeList
                login
                logout
                mapSso
                search
                searchMore
                searchMoreWithId
                searchNext
                ssoLogin
                update
                updateInviteeStatus
                updateInviteeStatusList
                updateList
                upsert
                upsertList
                ),
        ] => 'WSDL operations',
    );

    cmp_deeply(
        [ map { $_->list } $loader->wsdl->namespaces ],
        superbagof(
            map { re(qr/\A urn: $_ [.]webservices[.]netsuite[.]com \z/xms) }
                qw(
                accounting_\d{4}_\d+.lists
                bank_\d{4}_\d+.transactions
                common_\d{4}_\d+.platform
                communication_\d{4}_\d+.general
                core_\d{4}_\d+.platform
                customers_\d{4}_\d+.transactions
                customization_\d{4}_\d+.setup
                demandplanning_\d{4}_\d+.transactions
                employees_\d{4}_\d+.lists
                employees_\d{4}_\d+.transactions
                faults_\d{4}_\d+.platform
                filecabinet_\d{4}_\d+.documents
                financial_\d{4}_\d+.transactions
                general_\d{4}_\d+.transactions
                inventory_\d{4}_\d+.transactions
                marketing_\d{4}_\d+.lists
                messages_\d{4}_\d+.platform
                purchases_\d{4}_\d+.transactions
                relationships_\d{4}_\d+.lists
                sales_\d{4}_\d+.transactions
                scheduling_\d{4}_\d+.activities
                supplychain_\d{4}_\d+.lists
                support_\d{4}_\d+.lists
                types.accounting_\d{4}_\d+.lists
                types.common_\d{4}_\d+.platform
                types.communication_\d{4}_\d+.general
                types.core_\d{4}_\d+.platform
                types.customers_\d{4}_\d+.transactions
                types.customization_\d{4}_\d+.setup
                types.demandplanning_\d{4}_\d+.transactions
                types.employees_\d{4}_\d+.lists
                types.employees_\d{4}_\d+.transactions
                types.faults_\d{4}_\d+.platform
                types.filecabinet_\d{4}_\d+.documents
                types.financial_\d{4}_\d+.transactions
                types.inventory_\d{4}_\d+.transactions
                types.marketing_\d{4}_\d+.lists
                types.purchases_\d{4}_\d+.transactions
                types.relationships_\d{4}_\d+.lists
                types.sales_\d{4}_\d+.transactions
                types.scheduling_\d{4}_\d+.activities
                types.supplychain_\d{4}_\d+.lists
                types.support_\d{4}_\d+.lists
                website_\d{4}_\d+.lists
                ),
        ) => 'namespaces',
    );
}
