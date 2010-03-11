#!/usr/bin/perl -w

use strict;
use warnings;

use MooseX::Types::Moose qw(Num Int Str);
use MooseX::Types::DateTime qw(DateTime);
use Cantella::Data::Tabular::Types qw(HeaderStr);

use Cantella::Data::Tabular::Cell;
use Cantella::Data::Tabular::Table;

use Cantella::Data::Tabular::Render::PlainText;

my $table = Cantella::Data::Tabular::Table->new;
$table->set_header_cell(
  0,
  Cantella::Data::Tabular::Cell->new(
    constraint => HeaderStr,
    value => 'Column A'
  )
);

$table->set_header_cell(
  1,
  Cantella::Data::Tabular::Cell->new(
    constraint => HeaderStr,
    value => "Column B has a\nlong name"
  )
);

$table->set_header_cell(
  3,
  Cantella::Data::Tabular::Cell->new(
    constraint => HeaderStr,
    value => 'x'
  )
);

$table->set_cell(
  (0,0),
  Cantella::Data::Tabular::Cell->new(
    constraint => Num,
    value => 123456
  )
);

$table->set_cell(
  (0,1),
  Cantella::Data::Tabular::Cell->new(
    constraint => Num,
    value => 123456.789
  )
);
$table->set_cell(
  (0,2),
  Cantella::Data::Tabular::Cell->new(
    constraint => Int,
    value => 123456
  )
);
$table->set_cell(
  (1,0),
  Cantella::Data::Tabular::Cell->new(
    constraint => Int,
    value => 123
  )
);

$table->set_cell(
  (1,1),
  Cantella::Data::Tabular::Cell->new(
    value => 'foo'
  )
);
$table->set_cell(
  (1,2),
  Cantella::Data::Tabular::Cell->new(
    constraint => Str,
    value => 'a really long value'
  )
);

$table->set_cell(
  (1,3),
  Cantella::Data::Tabular::Cell->new(
    constraint => DateTime,
    value => 'DateTime'->now
  )
);

$table->set_cell(
  (1,4),
  Cantella::Data::Tabular::Cell->new(
    constraint => Str,
    value => "A long\nmulti\nline\nvalue\n"
  )
);

my $renderer = Cantella::Data::Tabular::Render::PlainText->new;
my $type_map = $renderer->value_type_to_format_options;
if( my $type = $type_map->find_matching_entry(DateTime) ){
  $type->data->{valign} = 'middle';
}

if( my $type = $type_map->find_matching_entry(Int) ){
  $type->data->{valign} = 'bottom';
  $type->data->{padding_bottom} = 2;
}

if( my $type = $type_map->find_matching_entry(HeaderStr) ){
  $type->data->{valign} = 'bottom';
  $type->data->{padding_right} = 5;
  $type->data->{padding_top} = 2;
}

my @lines = $renderer->render($table);

print "\n";
print "${_}\n" for @lines;
print "\n";
