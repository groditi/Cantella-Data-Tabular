package Cantella::Data::Tabular::Types;

use MooseX::Types -declare => [qw(CellValue Cell Row)];
use MooseX::Types::Moose qw(Defined);

subtype CellValue, as Defined;

class_type Cell, { class => 'Cantella::Data::Tabular::Cell' };

class_type Row, { class => 'Cantella::Data::Tabular::Row' };

1;

__END__;

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