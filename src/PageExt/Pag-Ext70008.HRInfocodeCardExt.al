pageextension 70008 "HR Infocode Card Ext" extends "LSC Infocode Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Printing")
        {
            group("Hot Recharge")
            {
                field("Hot Recharge Validation"; Rec."Hot Recharge Validation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Hot Recharge Validation field.', Comment = '%';
                }
                field("Hot Recharge Number"; Rec."Hot Recharge Number")
                {
                    Editable = Rec."Hot Recharge Validation";
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Hot Recharge Number field.', Comment = '%';
                }
            }
        }
    }
}