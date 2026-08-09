table 70003 "Hot Recharge Entry Logs"
{
    Access = Internal;
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Text[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(2; "Log No."; Integer)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(3; "Log Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Log Time"; Time)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Request File"; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Response File"; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Log Status"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = Success,Failed;
            Editable = false;
        }
        field(8; "Hot Recharge URI"; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Hot Recharge Headers"; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Log No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

}