table 70002 "Hot Recharge Entry"
{
    Access = Internal;
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Code[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(2; Validated; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(3; Replicated; Boolean)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(4; "Log Exist"; Boolean)
        {
            Caption = 'Log Exist';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = exist("Hot Recharge Entry Logs" where("Entry No." = field("Entry No.")));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

}