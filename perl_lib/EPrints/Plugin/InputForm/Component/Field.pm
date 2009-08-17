package EPrints::Plugin::InputForm::Component::Field;

use EPrints::Plugin::InputForm::Component;

@ISA = ( "EPrints::Plugin::InputForm::Component" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Field";
	$self->{visible} = "all";

	return $self;
}

sub parse_config
{
	my( $self, $config_dom ) = @_;

	my @fields = $config_dom->getElementsByTagName( "field" );

	if( scalar @fields != 1 )
	{
		EPrints::abort( "Bad configuration for Field Component\n".$config_dom->toString );
	}
	else
	{
		$self->{config}->{field} = $self->xml_to_metafield( $fields[0] );
	}
}

=pod

=item $fieldcomponent->update_from_form($processor)

Set the values of the object we are working with from the submitted form.

=cut

sub update_from_form
{
	my( $self, $processor ) = @_;
	my $field = $self->{config}->{field};
	my $value = $field->form_value( $self->{handle}, $self->{dataobj}, $self->{prefix} );
	$self->{dataobj}->set_value( $field->{name}, $value );
}

sub get_state_params
{
	my( $self ) = @_;

	my $field = $self->{config}->{field};

	return $field->get_state_params( 
			$self->{handle},  
			$self->{prefix}, );
}

=pod

=item @problems = $fieldcomponent->validate()

Returns a set of problems (DOM objects) if the component is unable to validate.

=cut

sub validate
{
	my( $self ) = @_;

	my $field = $self->{config}->{field};
	
	my $for_archive = 0;
	
	if( $field->{required} eq "for_archive" )
	{
		$for_archive = 1;
	}
	
	my @problems;

	if( $self->is_required() && !$self->{dataobj}->is_set( $field->{name} ) )
	{
		my $fieldname = $self->{handle}->make_element( "span", class=>"ep_problem_field:".$field->{name} );
		$fieldname->appendChild( $field->render_name( $self->{handle} ) );
		my $problem = $self->{handle}->html_phrase(
			"lib/eprint:not_done_field" ,
			fieldname=>$fieldname );
		push @problems, $problem;
	}
	
	push @problems, $self->{dataobj}->validate_field( $field->{name} );

	$self->{problems} = \@problems;

	return @problems;
}

=pod

=item $bool = $component->is_required()

returns true if this component is required to be completed before the
workflow may proceed

=cut

sub is_required
{
	my( $self ) = @_;

	my $req = $self->{config}->{field}->{required};
	# my $staff_mode = $self->{workflow}->get_parameter( "STAFF_MODE" );
	
	return( $req == 1 );
	
	# || ( $req eq "for_archive" && $staff_mode ) );
}

sub get_fields_handled
{
	my( $self ) = @_;

	return ( $self->{config}->{field}->{name} );
}

=pod

=item $boolean = $component->has_help()

Returns true if this component has help available.

=cut

sub has_help
{
	my( $self ) = @_;

	my $dom = $self->{config}->{field}->render_help(
		$self->{handle},
		$self->{config}->{field}->get_type() );

	if( EPrints::XML::is_empty( $dom ) )
	{
		return 0;
	}

	EPrints::XML::dispose( $dom );
	return 1;
}

=pod

=item $help = $component->render_help()

Returns DOM containing the help text for this component.

=cut

sub render_help
{
	my( $self, $surround ) = @_;

	return $self->{config}->{field}->render_help( 
			$self->{handle}, 
			$self->{config}->{field}->get_type() );
}

=pod

=item $name = $component->get_name()

Returns the unique name of this field (for prefixes, etc).

=cut

sub get_name
{
	my( $self ) = @_;

	return $self->{config}->{field}->{name};
}

=pod

=item $title = $component->render_title()

Returns the title of this component as a DOM object.

=cut

sub render_title
{
	my( $self, $surround ) = @_;

	return $self->{config}->{field}->render_name( $self->{handle} );
}

=pod

=item $content = $component->render_content( $surround )

Returns the DOM for the content of this component.

=cut

sub render_content
{
	my( $self, $surround ) = @_;
	
	my $value;
	if( $self->{dataobj} )
	{
		$value = $self->{dataobj}->get_value( $self->{config}->{field}->{name} );
	}
	else
	{
		$value = $self->{default};
	}

	return $self->{config}->{field}->render_input_field( 
			$self->{handle}, 
			$value, 
			$self->{dataobj}->get_dataset,
			0, # staff mode should be detected from workflow
			undef,
			$self->{dataobj},
			$self->{prefix},
 	);
}

sub could_collapse
{
	my( $self ) = @_;

	return !$self->{dataobj}->is_set( $self->{config}->{field}->{name} );
}

sub get_field
{
	my( $self ) = @_;

	return $self->{config}->{field};
}	

######################################################################
1;
