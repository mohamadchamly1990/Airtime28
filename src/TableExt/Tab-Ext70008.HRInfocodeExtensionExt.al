tableextension 70008 "HR Infocode Extension Ext" extends "LSC Infocode"
{
    fields
    {
        // Add changes to table fields here
        field(70000; "Hot Recharge Validation"; Boolean)
        {
            Caption = 'Hot Recharge Validation';
            DataClassification = ToBeClassified;
        }
        field(70001; "Hot Recharge Number"; Boolean)
        {
            Caption = 'Hot Recharge Number';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                infocode: Record "LSC Infocode";
            begin
                Infocode.Reset;
                Infocode.SetRange("Hot Recharge Number", true);
                If infocode.FindFirst() then
                    Error('Already Used');
            end;
        }
    }
}