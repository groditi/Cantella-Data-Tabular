package Cantella::Data::Tabular::Table;

use Moose;
use List::Util ();

has _header_row => (
  isa => 'Cantella::Data::Tabular::Row',
  reader => 'get_header_row',
  writer => 'set_header_row',
  predicate => 'has_header_row',
);

has rows => (
  is => 'ro',
  isa => 'ArrayRef[Cantella::Data::Tabular::Row]',
  required => 1,
  default => sub { [] },
);

sub height {
  my $self = shift;
  return ($self->has_header_row ? 1 : 0) + $self->row_count;
}

sub width {
  my $self = shift;
  return List::Util::max( 0, map { $_->width } @{ $self->rows } );
}

sub row_count {
  return scalar @{ shift->rows };
}

sub pad {
  my($self, $y, $x) = @_;
  return if $y < $self->row_count;
  for my $i ( $self->row_count .. $y ){
    $self->rows->[$i] = Cantella::Data::Tabular::Row->new;
  }
  return unless defined $x;
  map{ $_->pad($x) } @{ $self->rows };
}


sub get_row {
  my($self, $y) = @_;
  die("OUT OF RANGE: row ${y}") unless $self->row_count > $y;
  return $self->rows->[ $y ];
}

sub get_cell {
  my($self, $y, $x) = @_;
  return $self->get_row($y)->get_cell($x);
}

sub set_cell {
  my($self, $y, $x, $cell) = @_;
  $self->pad($y) if $self->row_count < $y;
  return $self->get_row($y)->set_cell($x, $cell);
}

sub has_value {
  my($self, $y, $x) = @_;
  $self->get_row($y)->has_value($x);
}

sub get_value {
  my($self, $y, $x) = @_;
  $self->get_row($y)->get_value($x);
}

sub set_value {
  my($self, $y, $x, $value) = @_;
  $self->pad($y) if $self->row_count < $y;
  return $self->get_row($y)->set_value($x, $value);
}

around get_header_row => sub {
  my $orig = shift;
  my $self = shift;
  die('OUT OF RANGE: No header row') unless $self->has_header_row;
  return $self->$orig(@_);
};

sub _build_header_row {
  return Cantella::Data::Tabular::Row->new;
}

sub get_header_cell {
  my($self, $x) = @_;
  return $self->get_header_row->get_cell($x);
}

sub set_header_cell {
  my($self, $x, $cell) = @_;
  $self->set_header_row( $self->_build_header_row ) if ! $self->has_header_row;
  return $self->get_header_row->set_cell($x, $cell);
}

sub has_header_value {
  my($self, $x) = @_;
  $self->get_header_cell($x)->has_value($x);
}

sub get_header_value {
  my($self, $x) = @_;
  $self->get_header_row->get_value($x);
}

sub set_header_value {
  my($self, $x, $value) = @_;
  $self->set_header_row( $self->_build_header_row ) if ! $self->has_header_row;
  return $self->get_header_row->set_value($x, $value);
}


__PACKAGE__->meta->make_immutable;

1;

__END__;

# I'm not sure this belongs in this layer, but I'd like to have this somewhere.
# This is most likely a part of a renderer. The idea being that you can size columns
# to a set width, for which to need to find out the widest item in each column.

#sample ...

sub col_width {
  my ($self, $x);
  my $find_width = sub { return length(shift) };

  my @widths;
  for my $row ( ($self->has_header_row ? $self->header_row : () ), @{ $self->_rows } ){
    next unless $row->width > $x;
    next unless $row->has_value($x);
    push(@widths, $find_width->($row->get_value($x)));
  }

  return List::Util::max(@widths);
}

