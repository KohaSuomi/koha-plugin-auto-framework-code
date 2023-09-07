package Koha::Plugin::Fi::KohaSuomi::AutoFrameworkCode;

use Modern::Perl;
use base qw(Koha::Plugins::Base);
use YAML qw(Load);
use MARC::Record;
use XML::LibXML;
use Storable;

use C4::Languages qw(getlanguage);
use Koha::Caches;

our $metadata = {
    name            => 'Auto Framework Code',
    author          => 'Pasi Kallinen',
    date_authored   => '2023-09-07',
    date_updated    => "2023-09-07",
    minimum_version => '21.05.00.000',
    maximum_version => undef,
    version         => '0.0.1',
    description     => 'Automatically figure out what framework code should be used for a record',
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub install {
    my ( $self, $args ) = @_;

    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    return 1;
}

sub uninstall {
    my ( $self, $args ) = @_;

    return 1;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            framework_autoconvert_rules => $self->retrieve_data('framework_autoconvert_rules'),
        );

        $self->output_html( $template->output() );
    }
    else {
        my $fwcoderules;
        my $yaml = $cgi->param('framework_autoconvert_rules') || '';
        $yaml = "$yaml\n\n";
        eval {
            $fwcoderules = YAML::Load($yaml);
        };
        if ($@) {
            warn "Unable to parse framework_autoconvert_rules: $@";
            # TODO: return to configure.tt and show the YAML has an error
            return '';
        }
        if (ref($fwcoderules) ne 'ARRAY') {
            warn "framework_autoconvert_rules YAML root element is not array";
            # TODO: return to configure.tt and show the YAML has an error
            return '';
        }
        foreach my $elem (@$fwcoderules) {
            if (ref($elem) ne 'HASH') {
                warn "framework_autoconvert_rules 2nd level YAML element not a hash";
                # TODO: return to configure.tt and show the YAML has an error
                #$cache->clear_from_cache($cache_key);
                return '';
            }
        }

        $self->store_data(
            {
                framework_autoconvert_rules => scalar $cgi->param('framework_autoconvert_rules'),
            }
        );
        $self->go_home();
    }
}


=head2 _matchRecordFieldspec

 $language = _matchRecordFieldspec($record, '008/35-37');

Returns field value from record. Fieldspec is a string of the following type:
'003', '100$a', '000/07', '008/35-37', or any of those types joined with plus sign.
If a matching field has been repeated in the record, the value from the first one is returned.

=cut

sub _matchRecordFieldspec {
    my ($record, $fieldstr) = @_;

    $fieldstr =~ s/^\s+//;
    $fieldstr =~ s/\s+$//;

    if ($fieldstr =~ /^(\d\d\d)$/) {
        my $fld = $1;
        my $data = '';
        if ($fld eq '000') {
            $data = $record->leader();
        } else {
            my $field = $record->field($fld);
            $data = $field->data() if ($field && $field->is_control_field());
        }
        return $data;
    } elsif ($fieldstr =~ /^(\d\d\d)\$(\S)$/) {
        my ($fld, $subfld) = ($1, $2);
        my $data = '';
        my @fields = $record->field($fld);
        foreach my $field (@fields) {
            if ($field && !$field->is_control_field() && $field->subfield($subfld)) {
                return $field->subfield($subfld);
            }
        }
        return $data;
    } elsif ($fieldstr =~ /^(\d\d\d)\/(\d+)$/) {
        my ($fld, $pos) = ($1, int($2));
        my $data = '';
        if ($fld eq '000') {
            $data = $record->leader();
        } else {
            my $field = $record->field($fld);
            $data = $field->data() if ($field && $field->is_control_field());
        }
        return substr($data, $pos, 1);
    } elsif ($fieldstr =~ /^(\d\d\d)\/(\d+)-(\d+)$/) {
        my ($fld, $spos, $epos) = ($1, int($2), int($3));
        my $data = '';
        if ($fld eq '000') {
            $data = $record->leader();
        } else {
            my $field = $record->field($fld);
            $data = $field->data() if ($field && $field->is_control_field());
        }
        return substr($data, $spos, ($epos-$spos)+1);
    } elsif ($fieldstr =~ /^(.+)\+(.+)$/) {
        my ($fld1, $fld2) = ($1, $2);
        return _matchRecordFieldspec($record, $fld1) . '+' . _matchRecordFieldspec($record, $fld2);
    } else {
        warn "_matchRecordFieldspec: unknown fieldspec '$fieldstr'";
    }
    return '';
}



sub _automatic_frameworkcode_core {
    my ($self, $args) = @_;

    my $record = $args->{'record'};
    my $fwcode_ref = $args->{'frameworkcode'};
    my $fwcode = '';

    $fwcode = $$fwcode_ref if (defined $fwcode_ref);

    return $fwcode if (defined $fwcode && $fwcode ne '');

    my $fwcoderules = '';
    my $yaml = $self->retrieve_data('framework_autoconvert_rules') || '';

    return '' if ($yaml !~ /\S/);

    $yaml = "$yaml\n\n";
    eval {
        $fwcoderules = YAML::Load($yaml);
    };
    if ($@) {
        warn "Unable to parse framework_autoconvert_rules: $@";
        return '';
    }

    if (ref($fwcoderules) ne 'ARRAY') {
        warn "framework_autoconvert_rules YAML root element is not array";
        return '';
    }

    foreach my $elem (@$fwcoderules) {
        if (ref($elem) ne 'HASH') {
            warn "framework_autoconvert_rules 2nd level YAML element not a hash";
            #$cache->clear_from_cache($cache_key);
            return '';
        }
        foreach my $ekey (keys(%{$elem})) {
            my $matchvalue = _matchRecordFieldspec($record, $ekey) || '';
            if (defined($elem->{$ekey})) {
                my $matches = $elem->{$ekey};
                if (ref($elem->{$ekey}) ne 'HASH') {
                    warn "framework_autoconvert_rules 3rd level YAML element not a hash";
                    #$cache->clear_from_cache($cache_key);
                    return '';
                }
                my %hmatches = %{$matches};
                foreach my $elm (keys(%hmatches)) {
                    return $hmatches{$elm} if ($elm eq $matchvalue);
                }
            }
        }
    }
    return '';
}

#
# Calling this plugin:
# Koha::Plugins->call('automatic_frameworkcode', { 'frameworkcode' => \$frameworkcode, 'record' => $record });
#
sub automatic_frameworkcode {
    my ($self, $args) = @_;

    my $tmp = _automatic_frameworkcode_core($self, $args);
    ${$args->{'frameworkcode'}} = $tmp if (defined $tmp && $tmp ne '');
}

1;