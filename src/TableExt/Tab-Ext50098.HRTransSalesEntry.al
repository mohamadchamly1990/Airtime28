tableextension 50098 "HR Trans. Sales Entry" extends "LSC Trans. Sales Entry"
{
    fields
    {
        // Add changes to table fields here
        field(70000; "Is Hot Recharge Product"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Hot Recharge Product';
        }
        field(70001; "HotRechargeSendSMS"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(70002; "HotRechargePhoneNo"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(70003; "HotRechargeProductID"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70004; "HotRechargeProductCurrency"; Code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(70005; "HotRechargeAgentReference"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(70006; "HotRechargeValidated"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
}