NAME

    Alma::User.pm

SYNOPSIS

        use Alma::UserREST;

        my $user = Alma::User->new( '1234567' );

DESCRIPTION

    Get User data using the Alma User Management REST API.

FUNCTIONS

    new
    
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

        If the input parameters do not provide a match, an error message is
        returned, stating the reason why the information cannot be
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

        If there is a match, a user data structure is returned. See the
        APPENDIX for an example.

    error
            if ( $user->error ) { ... }

    firstName lastName middleName fullName
            my $firstName = $user->firstName;
            my $lastName = $user->lastName;
            my $middleName = $user->middleName;
            my $fullName = $user->fullName;

    username
            my $username = $user->username;

    expiry
            my $expiry = $user->expiry;

    status
            my $status = $user->status;

    group
            my $group = $user->group;

    address
            my $address = $user->address;

        Returns the preferred address of the user, as a hash containing the
        preferred address (if any), or if preferred not indicated, the one
        with type work or school. If neither of those is present, returns
        the last address found.

        The hash has the same fields as the Alma user record address, viz.:
        line1 line2 line3 line4 line5 city stateProvince postalCode country

        Returns undefined if there are no addresses in the record.

    phone
            my $phone = $user->phone;

        Returns a string containing the preferred phone number (if any), or
        if preferred not indicated, the last one found. Returns the null
        string if there are no phone numbers in the record.

    email
        Returns a string containing the preferred email address (if any), or
        if preferred not indicated, the last one found. Returns the null
        string if there are no email addresses in the record.

    categories
        Returns a list (array) of statistical category codes for the user.

    barcode
        Returns the first active barcode number found for the user, or the
        empty string if there are no active barcodes.

APPENDIX

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
              }
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

AUTHOR

    Steve Thomas <stephen.thomas@adelaide.edu.au>

VERSION

    This is version 2015.09.02

