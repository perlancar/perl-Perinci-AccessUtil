package Perinci::AccessUtil;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(insert_riap_stuffs_to_res strip_riap_stuffs_from_res);

sub insert_riap_stuffs_to_res {
    my ($res, $def_ver, $nmeta) = @_;

    $res->[3]{'riap.v'} //= $def_ver // 1.1;
    if ($res->[3]{'riap.v'} >= 1.2) {
        # do we need to base64-encode?
        {
            last if $res->[3]{'riap.result_encoding'};
            if ($nmeta) {
                last unless $nmeta->{result}{schema} &&
                    $nmeta->{result}{schema}[0] eq 'buf';
            }
            last unless defined($res->[2]) && !ref($res->[2]) &&
                $res->[2] =~ /[^\x20-\x7f]/;
            require MIME::Base64;
            $res->[2] = MIME::Base64::encode_base64($res->[2]);
            $res->[3]{'riap.result_encoding'} = 'base64';
        }
    }
    $res;
}

sub strip_riap_stuffs_from_res {
    my $res = shift;

    my $ver = $res->[3]{'riap.v'} // 1.1;
    return [501, "Riap version returned by server ($ver) is not supported, ".
                "only recognize v1.1 and v1.2"]
        unless $ver == 1.1 || $ver == 1.2;

    if ($ver >= 1.2) {
        # check and strip riap.*
        for my $k (keys %{$res->[3]}) {
            next unless $k =~ /\Ariap\./;
            my $val = $res->[3]{$k};
            if ($k eq 'riap.v') {
            } elsif ($k eq 'riap.result_encoding') {
                return [501, "Unknown result_encoding returned by server ".
                            "($val), only base64 is supported"]
                    unless $val eq 'base64';
                require MIME::Base64;
                $res->[2] = MIME::Base64::decode_base64($res->[2]//'');
            } else {
                return [501, "Unknown Riap attribute in result metadata ".
                            "returned by server ($k)"];
            }
            delete $res->[3]{$k};
        }
    }

    $res;
}

1;
# ABSTRACT: Utility module for Riap client/server

=head1 SYNOPSIS

 use Perinci::AccessUtil qw(strip_riap_stuffs_from_res);
 my $res = strip_riap_stuffs_from_res([200,"OK"]);


=head1 DESCRIPTION


=head1 FUNCTIONS

=head2 insert_riap_stuffs_to_res($envres[, $def_ver, $nmeta]) => array

Starting in Riap protocol v1.2, server is required to return C<riap.v> in result
metadata. This routine does just that. In addition to that, this routine also
encodes result with base64 when necessary.

This routine is used by Riap network server libraries, e.g.
L<Perinci::Access::HTTP::Server> and L<Perinci::Access::Simple::Server>.

=head2 strip_riap_stuffs_from_res($envres) => array

Starting in Riap protocol v1.2, client is required to check and strip all
C<riap.*> keys in result metadata (C<< $envres->[3] >>). This routine does just
that. In addition, this routine also decode result if C<riap.result_encoding> is
set, so the user already gets the decoded content.

This routine is used by Riap client libraries, e.g. L<Perinci::Access::Lite>,
L<Perinci::Access::Perl>, and L<Perinci::Access::HTTP::Client>,
L<Perinci::Access::Simple::Client>.

If there is no error, will return C<$envres> with all C<riap.*> keys already
stripped. If there is an error, an error response will be returned instead.
Either way, you can use the response returned by this function to user.


=head1 SEE ALSO

L<Riap>, L<Perinci::Access>.

=cut
