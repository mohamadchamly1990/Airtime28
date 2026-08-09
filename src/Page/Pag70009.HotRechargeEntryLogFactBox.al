page 70009 "Hot Recharge Entry Log FactBox"
{
    Caption = 'Hot Recharge Status';
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "Hot Recharge Entry Logs";

    layout
    {
        area(Content)
        {
            usercontrol(JsonBeautifier; JsonBeautifier)
            {
                ApplicationArea = All;
            }
            group(gRequest)
            {
                Caption = 'Request';

                usercontrol(Request; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                {
                    ApplicationArea = All;
                }
            }
            group(gResponse)
            {
                Caption = 'Response';

                usercontrol(Response; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        TRequest, TResponse : Text;
        JsonRequest, JsonResponse : JsonObject;
        InStream: InStream;
        TypeHelper: Codeunit "Type Helper";
    begin
        Rec.CalcFields("Request File", "Response File");
        if Rec."Request File".HasValue then begin
            Rec."Request File".CreateInStream(InStream, TextEncoding::UTF8);
            JsonRequest.Add('data', (TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Request File"))));
            CurrPage.JsonBeautifier.Beautify(JsonRequest);
            JsonRequest.WriteTo(TRequest);
            CurrPage.Request.SetContent(TRequest);
        end;

        if Rec."Response File".HasValue then begin
            Rec."Response File".CreateInStream(InStream, TextEncoding::UTF8);
            JsonResponse.Add('data', TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Response File")));
            CurrPage.JsonBeautifier.Beautify(JsonResponse);
            JsonResponse.WriteTo(TResponse);
            CurrPage.Response.SetContent(TResponse);
        end;
    end;
}