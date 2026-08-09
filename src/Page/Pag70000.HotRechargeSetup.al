page 70000 "Hot Recharge Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Hot Recharge Setup";

    layout
    {
        area(Content)
        {
            group("API URL")
            {
                field("API Login URL"; Rec."API Login URL")
                {
                    ToolTip = 'Specifies the value of the API Login Link field.', Comment = '%';
                }
                field("API Recharge Product URL"; Rec."API Recharge Product URL")
                {
                    ToolTip = 'Specifies the value of the API Recharge Product URL field.', Comment = '%';
                }
                field("API Comp Recharge Product URL"; Rec."API Comp Recharge Product URL")
                {
                    ToolTip = 'Specifies the value of the API Complete Recharge Product URL field.', Comment = '%';
                }
                field("HR Division ID"; Rec."HR Division ID")
                {
                    ToolTip = 'Specifies the value of the Hr Division ID field.', Comment = '%';
                }
            }
            group(Parameters)
            {
                field("Access Token"; Rec."Access Token")
                {
                    ToolTip = 'Specifies the value of the Access Token field.', Comment = '%';
                }
                field("Access Refresh Token"; Rec."Access Refresh Token")
                {
                    ToolTip = 'Specifies the value of the Access Refresh Token field.', Comment = '%';
                }
                field("Access Code"; Rec."Access Code")
                {
                    ToolTip = 'Specifies the value of the Access Code field.', Comment = '%';
                }
                field(Password; Rec.Password)
                {
                    ToolTip = 'Specifies the value of the Password field.', Comment = '%';
                }
            }
            group("Validation")
            {
                field("Allowed Phone Number Prefixes"; Rec."Allowed Phone Number Prefixes")
                {
                    ToolTip = 'Specifies the value of the Allowed Prefixes field.', Comment = '%';
                }
                field("Phone Number Length"; Rec."Phone Number Length")
                {
                    ToolTip = 'Specifies the value of the Phone Number Length field.', Comment = '%';
                }
                field("Send SMS"; Rec."Send SMS")
                {
                    ToolTip = 'Specifies the value of the Send SMS field.', Comment = '%';
                }
            }
        }
    }
}