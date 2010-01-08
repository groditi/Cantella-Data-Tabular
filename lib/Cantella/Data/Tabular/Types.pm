package Cantella::Data::Tabular::Types;

use MooseX::Types -declare => [qw(CellValue Cell Row)];
use MooseX::Types::Moose qw(Defined);

subtype CellValue, as Defined;

class_type Cell, { class => 'Cantella::Data::Tabular::Cell' };

class_type Row, { class => 'Cantella::Data::Tabular::Row' };

1;

__END__;

=head1 NAME

Cantella::Data::Tabular::Types - Types library

=head1 SYNOPSIS

    use Cantella::Data::Tabular::Types qw( Cell );
    has cell => ( isa => Cell,  ...);

=head1 TYPES

=head2 CellValue

Subtype of 'Defined'

=head2 Cell

Class type for Cantella::Data::Tabular::Cell

=head2 Row

Class type for Cantella::Data::Tabular::Row

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

coerce Cell, from Defined,
  via { Cantella::Data::Tabular::Cell->new(value => $_) };

coerce Cell, from HashRef,
  via { Cantella::Data::Tabular::Cell->new( %$_ ) };


coerce Row, from ArrayRef,
  via {
  my $row = Cantella::Data::Row->new;
  $row->pad( $#{ $_ } );
  for my $x ( 0 .. $#{ $_ } ){
    next unless defined $_->[$x];
    $row->set_value($x, $_->[$x]);
  }
  return row;
};


subtype RowCells, as ArrayRef[Cell];

subtype TableRows, as ArrayRef[Row];
