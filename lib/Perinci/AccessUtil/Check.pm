package Perinci::AccessUtil::Check;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(strip_riap_stuffs_from_res);

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

 use Perinci::AccessUtil::Check qw(strip_riap_stuffs_from_res);
 my $res = strip_riap_stuffs_from_res([200,"OK"]);


=head1 DESCRIPTION


=head1 FUNCTIONS

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
