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
    constraint => Str,
    value => 'Column A'
  )
);

$table->set_header_cell(
  1,
  Cantella::Data::Tabular::Cell->new(
    constraint => Str,
    value => 'Column B is cool'
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
    constraint => Str,
    value => 'xyx'
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

my $renderer = Cantella::Data::Tabular::Render::PlainText->new;
my @lines = $renderer->render($table);

print "\n";
print "${_}\n" for @lines;
print "\n";
