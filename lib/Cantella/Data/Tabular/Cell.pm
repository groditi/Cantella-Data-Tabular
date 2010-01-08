package Cantella::Data::Tabular::Cell;

use Moose;
use Moose::Util::TypeConstraints ();
use Cantella::Data::Tabular::Types qw( CellValue );

has value => (
  isa => CellValue,
  init_arg => undef,
  reader => 'get_value',
  writer => '_set_raw_value',
  clearer => 'clear_value',
  predicate => 'has_value',
);

has constraint => (
  isa => 'Moose::Meta::TypeConstraint',
  reader => 'get_constraint',
  predicate => 'has_constraint',
  initializer => '_initialize_constraint',
);

has should_coerce => (
  is => 'ro',
  isa => 'Bool',
  default => sub { 0 },
);

sub _initialize_constraint {
  my ( $self, $value, $set, $attr ) = @_;
  $set->( Moose::Util::TypeConstraints::find_type_constraint($value) );
}

sub BUILD {
  my($self, $args) = @_;
  return unless exists $args->{value};
  $self->set_value(delete $args->{value});
}

sub set_value {
  my $self = shift;
  $self->_set_raw_value( $self->coerce_value_and_check_constraint(@_) );
}

sub coerce_value_and_check_constraint {
  my ($self, $value) = @_;
  if( $self->has_constraint ){
    my $type_constraint = $self->get_constraint;
    if ($self->should_coerce && $type_constraint->has_coercion) {
      $value = $type_constraint->coerce($value);
    }
    unless ( $type_constraint->check($value) ) {
      die("Type constraint check failed: ".$type_constraint->get_message($value));
    }
  }
  return $value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Cantella::Data::Tabular::Cell - Cell object

=head1 SYNOPSIS

    my $cell = Cantella::Data::Tabular::Cell->new(
      value => 'foo',
      constraint => 'Str', #automatically coerced from name to instance
    );

=head1 ATTRIBUTES

=head2 value

A read/write attribute representing the value of the cell. The value
must, at minimum, pass the constraint of
L<CellValue|Cantella::Data::Tabular::Types/CellValue>. When assigning a value
to the attribute at C<BUILD> time using the C<value> argument in a constructor,
the value will pass through L</coerce_value_and_check_contstraint>.

The following methods are associated with this attribute:

=over 4

=item B<get_value> - reader

=item B<set_value> - public writer, performs constraint checks and coerces values.

=item B<_set_raw_value> - private writer, sets value with no checks or coercions.

=item B<clear_value> - clearer

=item b<has_value> - predicate

=back

=head2 constraint

A read-only attribute containing a L<Moose::Meta::TypeConstraint> object which
will be used to validate value if it is present. If you want to replace the
constraint of an individual cell, the appropriate way to do it is to replace
the cell. When setting the value, you may pass a constraint object, or name
and the initializer will attempt to resolve it using L<Moose::Util::TypeConstraints>.

The following methods are associated with this attribute:

=over 4

=item B<get_constraint> - reader

=item B<has_constraint> - predicate

=item b<_initialize_constraint> - initializer

=back

=head2 should_coerce

A read-only boolean attribute representing whether the value should be coerced
according to the coercion map of the L</constraint>, if applicable. The initial
value defaults to false. If you wish to modify the coercion behavior of an
individual cell, the appropriate way to do it would be to replace the cell.

The following methods are associated with this attribute:

=over 4

=item B<should_coerce> - reader

=back

=head1 METHODS

=head2 new

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Constructor.
Accepts the following keys: C<value>, C<should_coerce> and C<constraint>.

=head2 coerce_and_check_constraint

=over 4

=item B<arguments:> C<$value>

=items B<return value:> C<$possibly_coerced_value>

=back

This method is to be considered a no-op if a L</constraint> is not present.
If the value L</should_coerce>, coercion will be attempted. Then C<$value>
will be checked against the C<constraint> and an exception will be thrown if
the type check fails.

=head2 BUILD

=over 4

=item B<arguments:> C<\%constructior_args>

=items B<return value:> none

=back

Extra tasks at instantiation time.

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut



# We need some kind of metadata slot so we can store information about the cell,
# not the value. Like formatting information / etc so we can eventually roundtrip
# spreadsheets via WriteExcel and ReadExcel. The slots should have no meaning at the
# this level, but should be meaningful only to higher-level layers, at least for now.
# The trick here is to allow for the use-cases of specific modules without letting the
# details of their interfaces or implementations leak in to ours.

use Moosex::AttributeHelpers;

has properties => (
  metaclass => 'Collection::Hash',
  is => 'ro',
  isa => 'HashRef[Defined]',
  default => sub { {} },
  provides => {
    set => 'set_property',
    get => 'get_property',
    exists => 'has_property',
    delete => 'clear_property',

    empty => 'has_properties',
    clear => 'clear_properties',
  }
);
