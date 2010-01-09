package Cantella::Data::Tabular::Render::PlainText;

use Moose;
use List::Util 'sum';
use MooseX::Types::Moose qw(Value Str Num Int);
use MooseX::Types::DateTime qw(DateTime);
use Cantella::Data::Tabular::Types qw(HeaderStr);

use MooseX::TypeMap;
use MooseX::TypeMap::Entry;

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
          data => { align => 'left' },
          type_constraint => Value,
        ),
        MooseX::TypeMap::Entry->new(
          data => { align => 'center' },
          type_constraint => HeaderStr,
        ),
        MooseX::TypeMap::Entry->new(
          data => { align => 'right' },
          type_constraint => Num,
        ),
      ]
    );
  }
);

#temp method, obvi
sub render {
  my ($self, $table) = @_;

  my $raw = $self->get_table_value_strings($table);
  my $widths = $self->calc_col_widths($raw);
  my $padded = $self->pad_values_to_column_widths($raw, $widths);

  my $corner = '++';
  my $vertical = '|';
  my $horizontal = '-';

  my $div_width = $self->get_value_width($vertical);
  my $table_width = $div_width + sum(map{ $_ + $div_width } @$widths);
  my $horiz_count = $table_width - ($self->get_value_width($corner) * 2);
  my $horizontal_rule = join('', $corner, ($horizontal x $horiz_count), $corner);

  my @output_lines;
  push(@output_lines, $horizontal_rule);
  if( defined $padded->{headers}){
    my $row = join('|', '', @{$padded->{headers}}, '');
    push(@output_lines, $row);
    push(@output_lines, $horizontal_rule);
  }
  for my $row_values ( @{$padded->{rows}} ){
    #TODO: make divider configurable;
    #TODO: Possibly add margin support in here somewhere
    my $row = join('|', '', @$row_values, '');
    push(@output_lines, $row)
  }
  push(@output_lines, $horizontal_rule);
  return @output_lines;
}

sub pad_values_to_column_widths {
  my($self, $values, $widths) = @_;

  my %values = ( rows => [] );
  if( defined $values->{headers} ){
    my @padded;
    my $x = 0;
    for my $cell ( @{ $values->{headers} } ) {
      my ($string, $options) = ($cell->[0], { align => 'center', %{$cell->[1]} } );
      push(@padded, $self->pad_string_to_width($string, $widths->[$x], $options) );
      $x++;
    }
    #add in empty cells;
    push(@padded, join('',(' ' x $widths->[$_]))) for $x .. $#$widths;
    $values{headers} = \@padded;
  }

  for my $row ( @{ $values->{rows}} ){
    my @padded;
    my $x = 0;
    for my $cell ( @$row ) {
      my ($string, $options) = @$cell;
      push(@padded, $self->pad_string_to_width($string, $widths->[$x], $options) );
      $x++;
    }
    #add in empty cells;
    push(@padded, join('',(' ' x $widths->[$_]))) for $x .. $#$widths;
    push(@{ $values{rows} }, \@padded);
  }

  return \%values;
}

sub calc_col_widths {
  my($self, $values) = @_;
  my @max_widths;
  if( defined $values->{headers} ){
    @max_widths = map { $self->get_value_width($_->[0]) } @{$values->{headers}};
  }
  for my $row ( @{$values->{rows}} ){
    my $x = 0;
    for my $cell( @$row ){
      my $width = $self->get_value_width( $cell->[0] );
      $max_widths[$x] = $width if !defined($max_widths[$x]) || $width > $max_widths[$x];
      $x++;
    }
  }
  return \@max_widths;
}

sub pad_string_to_width {
  my($self, $value_string, $width, $options) = @_;
  if( defined $options->{pad_format}) {
    return sprintf($options->{pad_format}, $value_string, $width);
  } elsif( defined $options->{align} ){
    if( $options->{align} eq 'left' ){
      return sprintf('%-*2$s', $value_string, $width);
    } elsif( $options->{align} eq 'right' ){
      return sprintf('%*2$s', $value_string, $width);
    } elsif( $options->{align} eq 'center' ){
      my $str_width = $self->get_value_width($value_string);
      if( $str_width < $width ){
        my $space = $width - $str_width;
        my $left = $space % 2 ? (($space + 1) / 2) : ($space / 2);
        my $left_padded = sprintf('%*2$s', $value_string, $str_width + $left);
        return sprintf('%-*2$s', $left_padded, $width);
      }
    }
  }
  return sprintf('%*2$s', $value_string, $width);
}

sub get_table_value_strings {
  my($self, $table) = @_;
  my %values = (
    rows => [ map{ $self->get_row_value_strings($_) } $table->get_rows ],
  );

  $values{headers} = $self->get_row_value_strings($table->get_header_row)
    if $table->has_header_row;

  return \%values;
}

sub get_row_value_strings {
  my($self, $row) = @_;
  my @value_strings = map { $self->get_cell_value_string($_) } $row->get_cells;
  return \@value_strings;
}

sub get_cell_value_string {
  my($self, $cell) = @_;

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

  #I hope to in the future have many more things to do here, but for now,
  # this will have to do.
  my($margin_left, $margin_right) = (0, 0);
  if( defined $options->{margin} ){
    $margin_left = $margin_right = $options->{margin};
  }
  $margin_left = $options->{margin_left} if defined $options->{margin_left};
  $margin_right = $options->{margin_right} if defined $options->{margin_right};

  my $margined_str = join('', (' ' x $margin_left), $padded_str, (' ' x $margin_right));

  return $margined_str;
