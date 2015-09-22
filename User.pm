package Alma::User;

$VERSION = "2015.09.02";
sub Version { $VERSION; }

use Carp;
use LWP::UserAgent;
use URI::Escape;
#use JSON;

use XML::Simple;
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

use Data::Dumper;
$Data::Dumper::Indent = 1;

use constant DEBUG => '0';

=head1 NAME

Alma::User.pm

=head1 SYNOPSIS

    use Alma::UserREST;

    my $user = Alma::User->new( '1234567' );


=head1 DESCRIPTION

Get User data using the Alma User Management REST API.

=head1 FUNCTIONS

=over

=item new

Retrieves information related to a given user, using the REST API.

Input Parameters

    user_id : A unique identifier for the user.

    user_id_type : The type of identifier that is being
    searched.  If this is not provided, all unique identifier
    types are used. The values that can be used are user_name or
    any of the values in the User Identifier Type code table.

    view : Special view of User object. Optional.  Possible values:
    full - full User object will be returned.
    brief - only user's core information, emails, identifiers and statistics are returned.
    By default, the full User object will be returned.

    expand : This parameter allows for expanding on some user information.
    Three options are available:
    loans-Include the total number of loans;
    requests-Include the total number of requests;
    fees-Include the balance of fees.
    To have more than one option, use a comma separator.

Output

If the input parameters do not provide a match, an error message
is returned, stating the reason why the information cannot be
retrieved.

    {
	'errorsExist' => 'true',
	'xmlns' => 'http://com/exlibris/urm/general/xmlbeans',
	'errorList' => {
	    'error' => {
		'errorCode' => '401861',
		'errorMessage' => 'User with identifier 7654321 was not found.
		(Tracking ID: E11-0209034323-J1IER-AWAE2004428111)'
	    }
	}
    };

If there is a match, a user data structure is returned. See the APPENDIX for 
an example.

=cut

sub new {
	my $class = shift;
	my $user_id = shift;

	my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );

	my $apikey = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
	my $host = 'api-ap.hosted.exlibrisgroup.com';

	my $url = sprintf "https://%s/almaws/v1/users/%s?%sapikey=%s",
		$host,
		$user_id,
		"view=full&",
		$apikey;
		#'&format=json';

	my $response = $ua->get( $url );

	## $response->status_line will be either 200 or 404
	DEBUG && carp $response->status_line;

	## ... but actually we can ignore it, because data returned will
	## indicate any error
	#unless ( $response->is_success ) { croak $response->status_line; }

	my $xml = $response->decoded_content;
	my $user = XMLin( $xml,
	    ForceArray => [ 'email', 'address', 'phone', 'user_identifier', 'user_statistic' ]
	);

	## Would be nice to have JSON instead of XML, but ...
	## format=json does not work as advertised -- still returns xml :(
	#my $json = $response->decoded_content;
	#my $user = decode_json( $json );

	bless $user, $class;

	return $user;
}

=item error

    if ( $user->error ) { ... }

=cut

sub error {
	my $data = shift;
	if ( $data->{errorsExist} eq 'true' ) {
	    return $data->{errorList}->{error}->{errorMessage};
	} else {
	    return 0;
	}
}

=item firstName lastName middleName fullName

    my $firstName = $user->firstName;
    my $lastName = $user->lastName;
    my $middleName = $user->middleName;
    my $fullName = $user->fullName;

=cut

sub firstName {
    my $user = shift;
    if (ref($user->{first_name}) eq 'HASH') { return '' }
    return $user->{first_name};
}

sub lastName {
    my $user = shift;
    if (ref($user->{last_name}) eq 'HASH') { return '' }
    return $user->{last_name};
}

sub middleName {
    my $user = shift;
    if (ref($user->{middle_name}) eq 'HASH') { return '' }
    return $user->{middle_name};
}

sub fullName {
    my $user = shift;
    if (ref($user->{full_name}) eq 'HASH') { return '' }
    return $user->{full_name};
}

=item username

    my $username = $user->username;

=cut

sub username {
    my $user = shift;
    return $user->{primary_id};
}

=item expiry

    my $expiry = $user->expiry;

=cut

sub expiry {
    my $user = shift;
    my $expiry = '';
    if ( exists $user->{expiry_date} ) {
	$expiry = $user->{expiry_date};
    }
    return $expiry;
}

=item status

    my $status = $user->status;

=cut

sub status {
    my $user = shift;
    return $user->{status}->{content};
}

=item group

    my $group = $user->group;

=cut

sub group {
    my $user = shift;
    return $user->{user_group}->{content};
}

=item address

    my $address = $user->address;

Returns the preferred address of the user, as a hash containing
the preferred address (if any), or if preferred not indicated,
the one with type work or school. If neither of those is
present, returns the last address found.

The hash has the same fields as the Alma user record address,
viz.:
    line1 line2 line3 line4 line5
    city stateProvince postalCode country

Returns undefined if there are no addresses in the record.

=cut

sub address {
    my $user = shift;
    my $found = {};
    foreach my $a ( @{ $user->{contact_info}->{addresses}->{address} } ) {
	$found = $a;
	last if ( $found->{preferred} eq 'true' );
	last if ( $found->{address_types}->{address_type}->{content} eq 'work' );
	last if ( $found->{address_types}->{address_type}->{content} eq 'school' );
    }

    ## Empty fields are a hash with xsi:nil => true ; replace with null...
    foreach $f ( qw( line1 line2 line3 line4 line5 city state_province postal_code ) ) {
	if ( ref($found->{$f}) eq 'HASH' ) { $found->{$f} = ''; }
    }

    my $address = {};

    foreach $f ( qw( line1 line2 line3 line4 line5 city ) ) {
	$address->{$f} = $found->{$f} if exists $found->{$f};
    }
    if ( exists $found->{state_province} ) {
	$address->{stateProvince} = $found->{state_province};
    };
    if ( exists $found->{postal_code} ) {
	$address->{postalCode} = $found->{postal_code};
    };
    if ( exists $found->{country}->{desc} ) {
	$address->{country} = $found->{country}->{desc};
    };

    return $address;
}

=item phone

    my $phone = $user->phone;

Returns a string containing the preferred phone number (if any), or if
preferred not indicated, the last one found.
Returns the null string if there are no phone numbers in the record.

=cut

sub phone {
    my $user = shift;
    my $phone = ''; # default to empty
    foreach my $e ( @{ $user->{contact_info}->{phones}->{phone} } ) {
	$phone = $e->{phone_number};
	last if ( $e->{preferred} eq 'true' );
    }
    # i.e. if there is an phone number we will use it; if there is a
    # preferred one, we will use that.
    return $phone;
}

=item email

Returns a string containing the preferred email address (if any), or if
preferred not indicated, the last one found.
Returns the null string if there are no email addresses in the record.

=cut

sub email {
    my $user = shift;
    my $email = ''; # default to empty
    foreach my $e ( @{ $user->{contact_info}->{emails}->{email} } ) {
	$email = $e->{email_address};
	last if ( $e->{preferred} eq 'true' );
    }
    # i.e. if there is an email address we will use it; if there is a
    # preferred one, we will use that.
    return $email;
}

=item categories

Returns a list of statistical category codes for the user.

=cut

sub categories {
    my $user = shift;
    my @stats = ();
    foreach my $c ( @{ $user->{user_statistics}->{user_statistic} } ) {
	push @stats, $c->{statistic_category}->{content};
    }
    return @stats;
}

=item barcode

Returns the first active barcode number found for the user,
or the empty string if there are no active barcodes.

=cut

sub barcode {
    my $user = shift;
    my $barcode = '';
    foreach my $id ( @{ $user->{user_identifiers}->{user_identifier} } ) {
	if ( $id->{status} eq 'ACTIVE' and $id->{id_type}->{content} eq 'BARCODE' ) {
	    $barcode = $id->{value};
	    last;
	}
    }
    return $barcode;
}

__END__

=back

=head1 APPENDIX

The structure returned by UserREST.pm:

    {
      'primary_id' => '1234567',
      'last_name' => 'Smith',
      'first_name' => 'John',
      'middle_name' => 'William',
      'full_name' => 'John William Smith',
      'expiry_date' => '2016-02-28Z',
      'purge_date' => '2016-05-28Z',
      'user_identifiers' => {
	'user_identifier' => [
	  {
	    'value' => 'a1234567',
	    'segment_type' => 'External',
	    'id_type' => {
	      'desc' => 'University ID',
	      'content' => 'ID'
	    },
	    'status' => 'ACTIVE'
	  },
	  {
	    'segment_type' => 'External',
	    'value' => '1505234567',
	    'id_type' => {
	      'desc' => 'Barcode',
	      'content' => 'BARCODE'
	    },
	    'status' => 'ACTIVE'
	  }
	]
      },
      'user_group' => {
	'desc' => 'Undergraduate Student',
	'content' => 'UND'
      },
      'contact_info' => {
	'phones' => {
	  'phone' => [
	    {
	      'preferred' => 'true',
	      'segment_type' => 'External',
	      'phone_types' => {
		'phone_type' => {
		  'desc' => 'Mobile',
		  'content' => 'mobile'
		}
	      },
	      'phone_number' => '0401234567',
	      'preferred_sms' => 'true'
	    }
	  ]
	},
	'addresses' => {
	  'address' => [
	    {
	      'start_date' => '2015-08-28Z',
	      'address_types' => {
		'address_type' => {
		  'desc' => 'School',
		  'content' => 'school'
		}
	      },
	      'address_note' => {},
	      'country' => {},
	      'line1' => 'North Terrace Campus;',
	      'line2' => 'North Tce;',
	      'postal_code' => {},
	      'state_province' => {},
	      'city' => {},
	      'segment_type' => 'External',
	      'preferred' => 'true'
	    },
	    {
	      'address_types' => {
		'address_type' => {
		  'desc' => 'Home',
		  'content' => 'home'
		}
	      },
	      'line1' => 'unit 4 / 1 Smiths Street',
	      'line2' => 'Seaton',
	      'city' => 'Seaton',
	      'state_province' => 'SA',
	      'postal_code' => '5023',
	      'country' => {
		'content' => 'AUS',
		'desc' => 'Australia'
	      },
	      'address_note' => {},
	      'start_date' => '2015-08-28Z',
	      'segment_type' => 'External',
	      'preferred' => 'false'
	    },
	    {
	      'address_note' => {},
	      'address_types' => {
		'address_type' => {
		  'desc' => 'Alternative',
		  'content' => 'alternative'
		}
	      },
	      'start_date' => '2015-08-28Z',
	      'segment_type' => 'External',
	      'preferred' => 'false',
	      'postal_code' => '5023',
	      'line1' => 'unit 4 / 1 Smiths Street',
	      'country' => {
		'content' => 'AUS',
		'desc' => 'Australia'
	      },
	      'line2' => 'Seaton',
	      'state_province' => 'SA',
	      'city' => 'SEATON'
	    }
	  ]
	},
	'emails' => {
	  'email' => [
	    {
	      'segment_type' => 'External',
	      'preferred' => 'true',
	      'email_types' => {
		'email_type' => {
		  'content' => 'work',
		  'desc' => 'Work'
		}
	      },
	      'email_address' => 'john.w.smith@student.adelaide.edu.au'
	    }
	  ]
	}
      },
      'user_statistics' => {
	'user_statistic' => {
	  'statistic_category' => {
	    'content' => 'UND',
	    'desc' => 'Undergraduate 1-3yr'
	  },
	  'segment_type' => 'External',
	  'category_type' => {
	    'content' => 'USERTYPES',
	    'desc' => 'All non-admin user categories'
	  }
	}
      },
      'job_description' => 'B.Science',
      'user_notes' => {},
      'user_roles' => {
	'user_role' => {
	  'role_type' => {
	    'desc' => 'Patron',
	    'content' => '200'
	  },
	  'status' => {
	    'desc' => 'Active',
	    'content' => 'ACTIVE'
	  },
	  'parameters' => {},
	  'scope' => {
	    'content' => '61ADELAIDE_INST',
	    'desc' => 'The University of Adelaide'
	  }
	}
      },
      'user_title' => {
	'desc' => ''
      },
      'record_type' => {
	'desc' => 'Public',
	'content' => 'PUBLIC'
      },
      'preferred_language' => {
	'content' => 'en',
	'desc' => 'English'
      },
      'external_id' => 'SIS',
      'birth_date' => '1983-01-28Z',
      'gender' => {
	'desc' => 'Male',
	'content' => 'MALE'
      },
      'campus_code' => {
	'content' => 'NTRCE',
	'desc' => 'North Terrace Campus student'
      },
      'account_type' => {
	'desc' => 'External',
	'content' => 'EXTERNAL'
      },
      'user_blocks' => {},
      'status' => {
	'desc' => 'Active',
	'content' => 'ACTIVE'
      },
      'job_category' => {
	'desc' => ''
      },
      'cataloger_level' => {
	'content' => '00',
	'desc' => '[00] Default Level'
      },
      'pin_number' => {},
      'web_site_url' => {},
      'force_password_change' => {},
      'password' => {},
      'proxy_for_users' => {}
    }

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 VERSION

This is version 2015.09.02

=cut

