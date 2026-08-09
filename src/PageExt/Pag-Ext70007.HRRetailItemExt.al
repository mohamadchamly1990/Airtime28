pageextension 70007 "HR Retail Item Ext" extends "LSC Retail Item Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(POS)
        {
            group("Hot Recharge")
            {
                field("Is Hot Recharge Product"; Rec."Is Hot Recharge Product")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Is Hot Recharge Product field.', Comment = '%';
                }
                field("Hot Recharge Product ID"; Rec."Hot Recharge Product ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Hot Recharge Product ID field.', Comment = '%';
                }
                field("Hot Recharge Product Currency"; Rec."Hot Recharge Product Currency")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Hot Recharge Product Currency field.', Comment = '%';
                }
                field("Hot Recharge Rst. Qty Change"; Rec."Hot Recharge Rst. Qty Change")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Hot Recharge Restrict Quantity Change field.', Comment = '%';
                }
            }
        }
    }
}