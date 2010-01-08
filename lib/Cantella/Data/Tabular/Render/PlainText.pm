package Cantella::Data::Tabular::Render::PlainText;

use Moose;
use MooseX::Types::Moose qw(Value Str Num Int);
use MooseX::Types::DateTime qw(DateTime);
use MooseX::TypeMap;
use MooseX::TypeMap::Entry;

has table => (
  is => 'ro',
  isa => 'Cantella::Data::Tabular::Table',
  required => 1,
);

has value_type_to_stringifier_map => (
  is => 'rw',
  isa => 'MooseX::TypeMap',
  required => 1,
  default => sub {
    MooseX::TypeMap->new(
      subtype_entries => [
        MooseX::TypeMap::Entry->new(
          data => sub{ return shift },
          type_constraint => Value
        ),
        MooseX::TypeMap::Entry->new(
          data => sub { shift->datetime },
          type_constraint => DateTime
        ),
        MooseX::TypeMap::Entry->new(
          data => sub { return sprintf('%d', shift) },
          type_constraint => Int
        ),
        MooseX::TypeMap::Entry->new(
          data => sub { return sprintf('%.2f', shift) },
          type_constraint => Num
        ),
      ]
    );
  }
);

has value_type_to_format_options => (
  is => 'rw',
  isa => 'MooseX::TypeMap',
  required => 1,
  default => sub {
    return MooseX::TypeMap->new(
      subtype_entries => [
        MooseX::TypeMap::Entry->new(
          data => { pad_format => '%-*2$s'},
          type_constraint => Value,
        ),
        MooseX::TypeMap::Entry->new(
          data => { pad_format => '%*2$s'},
          type_constraint => Num,
        ),
      ]
    );
  }
);

#temp method, obvi
sub print_data {
  my $self = shift;
  my $values = $self->get_formatted_table_data;
  for my $row_values ( @$values ){
    my $row = join('|', '', @$row_values, '');
    print $row."\n";
  }
}

sub get_formatted_table_data {
  my($self) = @_;

  my $table_width = $self->table->width;
  my $value_strings = $self->get_table_data_value_strings;

  #find column widths
  my @col_widths;
  for my $x (0 .. ($table_width - 1) ){
    my($min_col_width, $max_col_width) = (0,0);
    for my $row ( @$value_strings ){
      next unless defined $row->[$x];
      my $cell_width = $self->get_value_width($row->[$x]->[0]);
      $min_col_width = $cell_width if !defined($max_col_width) || $cell_width < $min_col_width;
      $max_col_width = $cell_width if !defined($max_col_width) || $cell_width > $max_col_width;
    }
    push(@col_widths, [$min_col_width, $max_col_width]);
  }

  my @final_values;
  for my $row ( @$value_strings ){
    my @row_values;
    for my $x ( 0 .. ($table_width - 1) ) { #ugly but necessary
      my ($string, $options) = (defined($row->[$x]) ? @{ $row->[$x] } : ('', {}) );
      $options->{pad_to_width} = $col_widths[$x][1] unless defined($options->{pad_to_width});
      push(@row_values, $self->format_value_string($string, $options) );
    }
    push(@final_values, \@row_values);
  }
  return \@final_values;
}

sub format_value_string {
  my($self, $value_string, $options) = @_;

  #I hope to in the future have many more things to do here, but for now,
  # this will have to do.
  my($margin_left, $margin_right) = (0, 0);
  if( defined $options->{margin} ){
    $margin_left = $margin_right = $options->{margin};
  }
  $margin_left = $options->{margin_left} if defined $options->{margin_left};
  $margin_right = $options->{margin_right} if defined $options->{margin_right};

  my $pad_width = $options->{pad_to_width};
  my $pad_format = exists($options->{pad_format}) ? $options->{pad_format} : '%*2$s';
  my $padded_str = sprintf($pad_format, $value_string, $pad_width);
  my $margined_str = join('', (' ' x $margin_left), $padded_str, (' ' x $margin_right));

  return $margined_str;
}

sub get_table_data_value_strings {
  my($self) = @_;

  my @value_strings;
  my $row_count = $self->table->row_count;
  for my $y ( 0 .. ($row_count - 1) ){
    push(@value_strings, $self->get_row_value_strings($y));
  }
  return \@value_strings;
}

sub get_row_value_strings {
  my($self, $y) = @_;
  my @value_strings;
  my $width = $self->table->get_row($y)->width;
  for my $x ( 0 .. ($width - 1) ){
    push(@value_strings, $self->get_cell_value_string($y, $x));
  }
  return \@value_strings;
}

sub get_cell_value_string {
  my($self, $y, $x) = @_;
  my $cell = $self->table->get_cell($y, $x);

  my $value;
  my %format_options;
  if( $cell->has_value ){
    if( $cell->has_constraint ){
      my $type = $cell->get_constraint;
      $value = $self->stringify_value_by_type($cell->get_value, $type);
      if( my $options = $self->value_type_to_format_options->resolve($type) ){
        %format_options = %$options;
      }
    } else {
      $value = $cell->get_value;
    }
  } else {
    $value = '';
  }

  #in the future, here would be where i copied format_options from
  # $cell->metadata->{format_options} to %format_options

  return [ $value, \%format_options];
}

sub stringify_value_by_type {
  my($self, $value, $type) = @_;
  if( my $coderef = $self->value_type_to_stringifier_map->resolve($type) ){
    return $coderef->($value);
  }
  return $value;
}

sub get_value_width {
  my($self, $value) = @_;
  return length($value);
}

1

__END__;
