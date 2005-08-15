package Text::Identify::BoilerPlate;

use warnings;
use strict;
use Carp;
use base qw{ Exporter };
use Hash::Merge qw{ merge };


our $VERSION = '0.1';

our @EXPORT_OK = qw( rem_boilerplate );


my %config;

my %dupl;

sub rem_boilerplate {

    my ($files,$arg_ref) = @_;

    _get_config($arg_ref);

    my @files = @$files;

    foreach my $file (@files) {
        my @lines;
        open my $FILE_HANDLE, '<', $file
            or croak "Can't open $file";
        while ( my $line = <$FILE_HANDLE> ) {

            $line =~ s/^\s*//g;
            $line =~ s/\s*$//g;
            $line =~ s/\t/ /g;
            $line =~ s/ +/ /g;

            my $line_tmp=$line;
            if ($config{'ignore_digits'}) {
                $line_tmp =~ s/\d+/_D_/g;
            }


            $dupl{$line_tmp}++;
            push @lines, $line;

        }
        $file = [ $file, \@lines ];    # name + content
    }

    # find duplicated lines
    foreach my $file (@files) {

        my $lines = $file->[1];
        my @lines = @$lines;

        @lines = _rem_first_duplicates(@lines);
        @lines = reverse @lines;
        @lines = _rem_first_duplicates(@lines);
        @lines = reverse @lines;

        my $filename     = $file->[0];
        my $new_filename = $filename . "." . $config{'suffix'};
        open my $FILE_HANDLE, '>', $new_filename
            or croak "Can't open $new_filename";
        print {$FILE_HANDLE} join( "\n", @lines );

    }

}




sub _rem_first_duplicates {

    my @input = @_;

  CUT:
    foreach my $line (@input) {

        my $line_tmp = $line;
        if ($config{'ignore_digits'}) {
            $line_tmp =~ s/\d+/_D_/g;
        }

        if ( $line_tmp eq '' ) {
            next CUT;
        }
        elsif ( $dupl{$line_tmp} > $config{'min_dupl'} ) {
            shift @input;
        }
        else {
            last CUT;
        }

    }

    return @input;

}


sub _get_config {

    my %config_default = (
                          min_dupl=>3,
                          suffix=>'content',
                          ignore_digits=>1,
                          html_log=>1
                         );

    my $arg_ref = $_[0];
    my %config_arg = %$arg_ref;

    Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
    %config = %{ merge( \%config_default, \%config_arg ) };
    

}

1;    # End of Text::BoilerPlate

__END__

=head1 NAME

Text::Identify::BoilerPlate - Remove repeated text

=head1 VERSION

Version 0.1


=head1 SYNOPSIS

Finds boilerplate text (lines that are repeated across documents) in a 
list of plain text files. Only sets consecutive lines of repeated text at
the start and end of documents are considered boilerplate text.

    use Text::Identify::BoilerPlate;

    my @files = ('file1', 'file2', 'file3');
    rem_boilerplate(@files);

New files are written, containing everything but the boilerplate text.

=head1 EXPORT

=head1 FUNCTIONS

=head2 rem_boilerplate

=head1 AUTHOR

Lars Nygaard, C<< <lars.nygaard@inl.uio.no> >>

=head1 BUGS

The program should be bug-free, but is still needs extensive testing and tweaking
before the simple algorithm can give consistently high-quality results.

Please report any bugs or feature requests to
C<bug-text-identify-boilerplate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Identify-BoilerPlate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Lars Nygaard, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


