tableextension 70007 "HR Item Ext" extends Item
{
    fields
    {
        // Add changes to table fields here
        field(70000; "Is Hot Recharge Product"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Hot Recharge Product';

            trigger OnValidate()
            begin
                Rec.TestField("LSC Keying in Price", Rec."LSC Keying in Price"::"Must Key in New Price");
            end;
        }
        field(70001; "Hot Recharge Product ID"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge Product ID';
        }
        field(70002; "Hot Recharge Product Currency"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Hot Recharge Product Currency';
            TableRelation = Currency.Code;
        }
        field(70003; "Hot Recharge Rst. Qty Change"; Boolean)
        {
            Caption = 'Hot Recharge Restrict Quantity Change';
            DataClassification = ToBeClassified;
        }
    }
}