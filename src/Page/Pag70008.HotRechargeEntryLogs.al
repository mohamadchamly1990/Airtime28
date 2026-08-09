page 70008 "Hot Recharge Entry Logs"
{
    Caption = 'Hot Recharge Entry Log List';
    PageType = List;
    ApplicationArea = All;
    Editable = false;
    ShowFilter = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Hot Recharge Entry Logs";

    layout
    {
        area(Content)
        {
            usercontrol(JsonBeautifier; JsonBeautifier)
            {
                ApplicationArea = All;

                trigger ReceiveBeautifiedJson(FormattedJson: Text)
                begin
                    Message('%1', FormattedJson);
                end;
            }
            repeater(General)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the No. field.';
                    StyleExpr = StyleExprTxt;
                }
                field("Log Date"; Rec."Log Date")
                {
                    ToolTip = 'Specifies the value of the Log Date field.';
                    StyleExpr = StyleExprTxt;
                }
                field("Log Time"; Rec."Log Time")
                {
                    ToolTip = 'Specifies the value of the Log Time field.';
                    StyleExpr = StyleExprTxt;
                }
                field("Log Status"; Rec."Log Status")
                {
                    ToolTip = 'Specifies the value of the Log Status field.';
                    StyleExpr = StyleExprTxt;
                }
            }
        }
        area(FactBoxes)
        {
            part("Hot Recharge Entry Log FactBox"; "Hot Recharge Entry Log FactBox")
            {
                SubPageLink = "Entry No." = field("Entry No."), "Log No." = field("Log No.");
                ApplicationArea = All;
                Caption = '';
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Show Request File Json")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                Image = ImportLog;

                trigger OnAction()
                begin
                    Clear(JsonResponse);
                    GetRequestFile(JsonResponse);
                end;
            }
            action("Show Response File Json")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                Image = ValidateEmailLoggingSetup;

                trigger OnAction()
                begin
                    Clear(JsonRequest);
                    GetResponseFileAsText(JsonRequest);
                end;
            }
        }
    }

    var
        JsonRequest, JsonResponse : JsonObject;
        StyleExprTxt: Text[50];

    trigger OnAfterGetRecord()
    begin
        StyleExprTxt := ChangeCustomerRankColor(Rec);
    end;

    procedure ChangeCustomerRankColor(pHotRechargeEntryLogs: Record "Hot Recharge Entry Logs"): Text[50]
    begin
        case pHotRechargeEntryLogs."Log Status" of
            pHotRechargeEntryLogs."Log Status"::Failed:
                exit('Unfavorable');
            pHotRechargeEntryLogs."Log Status"::Success:
                exit('favorable');
        end;
    end;

    procedure GetRequestFile(var pJsonRequest: JsonObject)
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Request File");
        Rec."Request File".CreateInStream(InStream, TextEncoding::UTF8);
        pJsonRequest.Add('data', (TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Request File"))));
        CurrPage.JsonBeautifier.Beautify(pJsonRequest);
    end;

    procedure GetResponseFileAsText(var pJsonResponse: JsonObject): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Response File");
        Rec."Response File".CreateInStream(InStream, TextEncoding::UTF8);
        pJsonResponse.Add('data', (TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Response File"))));
        CurrPage.JsonBeautifier.Beautify(pJsonResponse);
    end;
}