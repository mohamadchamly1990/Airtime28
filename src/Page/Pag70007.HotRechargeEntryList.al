page 70007 "Hot Recharge Entry List"
{
    Caption = 'Hot Recharge Entry List';
    PageType = List;
    ApplicationArea = All;
    Editable = false;
    UsageCategory = Lists;
    ShowFilter = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Hot Recharge Entry";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Created At"; Rec.SystemCreatedAt)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedAt field.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field(Validated; Rec.Validated)
                {
                    ToolTip = 'Specifies the value of the Validated field.', Comment = '%';
                }
                field(Replicated; Rec.Replicated)
                {
                    ToolTip = 'Specifies the value of the Replicated field.';
                }
                field("Log Exist"; Rec."Log Exist")
                {
                    ToolTip = 'Specifies the value of the Log Exist field.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Hot Recharge Entry Logs")
            {
                ApplicationArea = All;
                Image = Log;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "Hot Recharge Entry Logs";
                RunPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
}