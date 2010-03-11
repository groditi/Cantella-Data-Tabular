package Cantella::Data::Tabular::Render::PlainText;

use Moose;
use List::Util qw/sum max/;
use MooseX::Types::Moose qw(Value Str Num Int);
use MooseX::Types::DateTime qw(DateTime);
use Cantella::Data::Tabular::Types qw(HeaderStr);
use MooseX::Types::Common::String qw/SimpleStr/;

use MooseX::TypeMap;
use MooseX::TypeMap::Entry;

has newline_string => (
  is => 'rw',
  isa => Str,
  required => 1,
  default => sub { "\n" },
);

has corner_string => (
  is => 'rw',
  isa => SimpleStr,
  required => 1,
  default => sub { "++" },
);

has vertical_divider => (
  is => 'rw',
  isa => SimpleStr,
  required => 1,
  default => sub { "||" },
);

has horizontal_divider => (
  is => 'rw',
  isa => SimpleStr,
  required => 1,
  default => sub { "=" },
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
          data => { align => 'left' },
          type_constraint => Value,
        ),
        MooseX::TypeMap::Entry->new(
          data => { align => 'right' },
          type_constraint => Int,
        ),
        MooseX::TypeMap::Entry->new(
          data => { align => 'left' },
          type_constraint => DateTime,
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

  my $value_opts_grid = $self->prepare_table($table);
  my $dimensions = $self->calculate_table_dimensions($value_opts_grid);

  #eventually, these will be customizable
  my $corner = $self->corner_string;
  my $h_div = $self->horizontal_divider;
  my $v_div = $self->vertical_divider;
  my $h_div_width = $self->get_string_width($h_div);
  my $v_div_width = $self->get_string_width($v_div);
  my $corner_width = $self->get_string_width($corner);

  my @widths = map { $_->[1]} @{ $dimensions->{rows}[0] };
  my $table_width = $v_div_width + sum(map{ $_ + $v_div_width } @widths);
  my $h_rule_line = join(
    '',
    $corner, ($h_div x (($table_width  / $h_div_width ) - ($corner_width * 2)) ), $corner
  );

  my @output_lines;
  push(@output_lines, $h_rule_line);
  if( my $values = delete $value_opts_grid->{headers}){
    my $header_dimensions = delete $dimensions->{headers};
    push(@output_lines, $self->render_row($values, $header_dimensions));
    push(@output_lines, $h_rule_line);
  }
  for my $row_values ( @{$value_opts_grid->{rows}} ){
    my $row_dimensions = shift(@{ $dimensions->{rows} });
    push(@output_lines, $self->render_row($row_values, $row_dimensions));
    push(@output_lines, $h_rule_line);
  }
  return @output_lines;
}

sub render_row {
  my($self, $values, $dimensions) = @_;
  my $divider = $self->vertical_divider;
  my $padded = $self->pad_row_values($values, $dimensions);

  my @output;
  for my $line_num ( 0 .. ( $dimensions->[0][0] - 1 ) ){
    my @lines = map { $_->[ $line_num ] } @$padded;
    push(@output, join($divider, '', @lines, '') );
  }
  return join($self->newline_string, @output);
}

sub calculate_table_dimensions {
  my($self, $values) = @_;

  my @max_widths;
  my $header_height;
  if( defined $values->{headers} ){
    my @header_dimensions;
    for my $header_value ( @{$values->{headers}} ){
      push(@header_dimensions, $self->calc_value_dimensions($header_value) );
    }
    $header_height = max(map { $_->[0] } @header_dimensions);
    @max_widths = map { $_->[1] } @header_dimensions;
  }

  my @max_heights;
  for my $row ( @{$values->{rows}} ){
    my $x = 0;
    my $row_height = 1;
    for my $cell( @$row ){
      my $cell_dimensions = $self->calc_value_dimensions( $cell );
      my ($cell_height, $cell_width) = @$cell_dimensions;
      $max_widths[$x] = $cell_width if !defined($max_widths[$x]) || $cell_width > $max_widths[$x];
      $row_height = $cell_height if $cell_height > $row_height;
      $x++;
    }

    push(@max_heights, $row_height);
  }

  my %dimensions = (rows => []);
  if( defined $header_height ){
    $dimensions{headers} = [ map { [$header_height, $_] } @max_widths ];
  }
  for my $height ( @max_heights ){
    push(@{ $dimensions{rows} }, [ map { [$height, $_] } @max_widths ]);
  }

  return \%dimensions;
}

sub calc_value_dimensions {
  my($self, $value) = @_;
  my $value_dimensions = $self->get_string_dimensions($value->[0]);
  if( defined $value->[1]->{padding_top} ){
    $value_dimensions->[0] += $value->[1]->{padding_top};
  }
  if( defined $value->[1]->{padding_bottom} ){
    $value_dimensions->[0] += $value->[1]->{padding_bottom};
  }
  if( defined $value->[1]->{padding_left} ){
    $value_dimensions->[1] += $value->[1]->{padding_left};
  }
  if( defined $value->[1]->{padding_right} ){
    $value_dimensions->[1] += $value->[1]->{padding_right};
  }
  return $value_dimensions;
}

sub pad_row_values {
  my($self, $row, $dimensions) = @_;
  my @padded;
  my $x = 0;
  for my $cell (  (@$row, ((['', {}]) x (@$dimensions - @$row)) ) ) {
    my ($string, $options) = @$cell;
    push(@padded, $self->pad_string($string, $dimensions->[$x], $options) );
    $x++;
  }
  return \@padded;
}

sub pad_string {
  my($self, $string, $dimensions, $options) = @_;
  my($height, $width) = @$dimensions;
  my $filler_value = $self->pad_string_to_width('', $width, $options);
  my @lines;
  if( index($string, $self->newline_string, 0) > 0){
    @lines = map { defined($_) ? $_ : ''} split($self->newline_string, $string);
  } else {
    @lines = ($string);
  }
  my @padded_lines = map{ $self->pad_string_to_width($_, $width, $options) } @lines;
  if(defined $options->{padding_bottom}){
    push(@padded_lines, ($filler_value) x $options->{padding_bottom});
  }
  if(defined $options->{padding_top}){
    unshift(@padded_lines, ($filler_value) x $options->{padding_top});
  }

  if( my $diff = $height - scalar(@padded_lines) ){
    if( defined($options->{valign}) ){
      if( $options->{valign} eq 'top'){
        push(@padded_lines, ($filler_value) x $diff);
      } elsif( $options->{valign} eq 'bottom'){
        unshift(@padded_lines, ($filler_value) x $diff);
      } elsif( $options->{valign} eq 'middle'){
        my $top = int($diff / 2);
        my $bottom = $top + ( $diff % 2 );
        unshift(@padded_lines, ($filler_value) x $top);
        push(@padded_lines, ($filler_value) x $bottom);
      }
    } else {
      push(@padded_lines, ($filler_value) x $diff); #default to top alignment
    }
  }

  return \@padded_lines;
}

sub pad_string_to_width {
  my($self, $string, $width, $options) = @_;
  if( defined $options->{padding_left} ){
    my $padded_width = $options->{padding_left} + $self->get_string_width($string);
    $string = sprintf('%*2$s',$string, $padded_width);
  }
  if( defined $options->{padding_right} ){
    my $padded_width = $options->{padding_right} + $self->get_string_width($string);
    $string = sprintf('%-*2$s', $string, $padded_width);
  }
  if( defined $options->{pad_format} ){
    return sprintf($options->{pad_format}, $string, $width);
  } elsif( defined $options->{align} ){
    if( $options->{align} eq 'left' ){
      return sprintf('%-*2$s', $string, $width);
    } elsif( $options->{align} eq 'right' ){
      return sprintf('%*2$s', $string, $width);
    } elsif( $options->{align} eq 'center' ){
      my $str_width = $self->get_string_width($string);
      if( $str_width < $width ){
        my $space = $width - $str_width;
        my $left = $space % 2 ? (($space + 1) / 2) : ($space / 2);
        my $left_padded = sprintf('%*2$s', $string, $str_width + $left);
        return sprintf('%-*2$s', $left_padded, $width);
      }
    }
  }
  return sprintf('%*2$s', $string, $width);
}

sub prepare_table {
  my($self, $table) = @_;
  my %values = (
    rows => [ map{ $self->prepare_row($_) } $table->get_rows ],
  );

  $values{headers} = $self->prepare_row($table->get_header_row)
    if $table->has_header_row;

  return \%values;
}

sub prepare_row {
  my($self, $row) = @_;
  my @values = map { $self->prepare_cell($_) } $row->get_cells;
  return \@values;
}

sub prepare_cell {
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
  #my $dimensions = $self->get_string_dimensions( $value );
  #$format_options{height} ||= $dimensions->[0];
  #$format_options{width} ||= $dimensions->[1];

  return [ $value, \%format_options];
}

sub stringify_value_by_type {
  my($self, $value, $type) = @_;
  if( my $coderef = $self->value_type_to_stringifier_map->resolve($type) ){
    return $coderef->($value);
  }
  return $value;
}

sub get_string_width {
  my($self, $value) = @_;
  return length($value);
}

sub get_string_dimensions {
  my($self, $value) = @_;
  my $pos = 0;
  my $width = 0;
  my $height = 1;
  my $found = index($value, $self->newline_string, $pos);
  while( $found > 0 ){
    my $substr_width = $self->get_string_width(substr($value, $pos, ($found - $pos)));
    $width = $substr_width > $width ? $substr_width : $width;
    $height++;
    $pos = $found + length( $self->newline_string ); #not a bug.
    $found = index($value, $self->newline_string, $pos);
  }
  $width = $self->get_string_width($value) if $height == 1;

  return [ $height, $width ];
}

1;

__END__;
