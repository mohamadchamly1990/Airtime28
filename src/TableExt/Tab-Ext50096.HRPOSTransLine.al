tableextension 50096 "HR POS Trans. Line" extends "LSC POS Trans. Line"
{
    fields
    {
        // Add changes to table fields here
        field(70000; "Is Hot Recharge Product"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Hot Recharge Product';
        }
        field(70001; "Hot Recharge Send SMS"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge Send SMS';
        }
        field(70002; "Hot Recharge Phone No."; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge Phone No.';
        }
        field(70003; "Hot Recharge Product ID"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge Product ID';
        }
        field(70004; "Hot Recharge Product Currency"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge Product Currency';
        }
        field(70005; "Hot Recharge AgentReference"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge AgentReference';
        }
        field(70006; "Hot Recharge Validated"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge Validated';
        }
    }
}