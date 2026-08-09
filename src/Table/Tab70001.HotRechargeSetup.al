table 70001 "Hot Recharge Setup"
{
    Access = Internal;
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "API Login URL"; Text[2045])
        {
            Caption = 'API Login Link';
            DataClassification = ToBeClassified;
        }
        field(4; "API Recharge Product URL"; Text[2045])
        {
            Caption = 'API Recharge Product URL';
            DataClassification = ToBeClassified;
        }
        field(5; "Access Token"; Text[2045])
        {
            Caption = 'Access Token';
            DataClassification = ToBeClassified;
        }
        field(6; "Access Refresh Token"; Text[2045])
        {
            Caption = 'Access Refresh Token';
            DataClassification = ToBeClassified;
        }
        field(7; "Access Code"; Text[2045])
        {
            Caption = 'Access Code';
            DataClassification = ToBeClassified;
        }
        field(8; Password; Text[2045])
        {
            Caption = 'Password';
            DataClassification = ToBeClassified;
            ExtendedDatatype = Masked;
        }
        field(9; "HR Division ID"; Text[100])
        {
            Caption = 'Hr Division ID';
            DataClassification = ToBeClassified;
        }
        field(10; "API Comp Recharge Product URL"; Text[2045])
        {
            Caption = 'API Complete Recharge Product URL';
            DataClassification = ToBeClassified;
        }
        field(11; "Phone Number Length"; Integer)
        {
            DataClassification = ToBeClassified;
        }

        field(12; "Allowed Phone Number Prefixes"; Text[2045])
        {
            DataClassification = ToBeClassified;
            Caption = 'Allowed Prefixes';
        }
        field(13; "Send SMS"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Send SMS';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

}