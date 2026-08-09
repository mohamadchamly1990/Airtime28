codeunit 60006 "Hot Recharge Subscriber"
{
    access = Internal;

    var
        gPOSSessionCU: Codeunit "LSC POS Session";
        POSTransaction_CU: Codeunit "LSC POS Transaction";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnAfterStartNewTransaction', '', false, false)]
    internal procedure POSTransactionEvents_OnAfterStartNewTransaction()
    begin
        gPOSSessionCU.DeleteValue('HotRechargeTransIsVoided');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LSC Retail Item", OnAfterValidateEvent, "Keying in Price", false, false)]
    Internal procedure Item_OnAfterValidateEvent(var Rec: Record Item; var xRec: Record Item)
    begin
        If Rec."Is Hot Recharge Product" then
            Rec.TestField(Rec."LSC Keying in Price", Rec."LSC Keying in Price"::"Must Key in New Price");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnAfterItemLineV2, '', false, false)]
    Internal procedure POSTransactionEvents_OnAfterItemLine(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var TransactionContext: Record "LSC POS Transaction Context")
    var
        ItemL: Record Item;
    begin

        If ItemL.Get(TransactionContext.GetCurrInput()) then begin
            POSTransLine."Is Hot Recharge Product" := ItemL."Is Hot Recharge Product";
            POSTransLine."Hot Recharge Product ID" := ItemL."Hot Recharge Product ID";
            POSTransLine."Hot Recharge Product Currency" := ItemL."Hot Recharge Product Currency";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Infocode Utility", OnBeforeIsInputOkV3, '', false, false)]
    local procedure POSInfocodeUtility_OnBeforeIsInputOkV3(InfoCodeRec: Record "LSC Infocode"; Input: Text; var ErrorTxt: Text; var Line: Record "LSC POS Trans. Line"; var Canceled: Boolean; MgrKeyActive: Boolean; Training: Boolean; var TSError: Boolean; Quantity: Decimal; SerialNo: Code[50]; EntryVariantCode: Code[10]; SetPrice: Boolean; NewPrice: Decimal; LinkedLineInserted: Boolean; var EntryLineNo: Integer; var IsHandled: Boolean; var ReturnValue: Boolean)
    var
        HotRechargeSetupL: Record "Hot Recharge Setup";
        PhoneNumber: Integer;
        Prefix: Text[10];
        AllowedPrefixes: Text[250];
        PrefixList: List of [Text];
        IsValid: Boolean;
        I: Integer;
    begin
        if not InfoCodeRec."Hot Recharge Number" then
            exit;

        HotRechargeSetupL.Get();

        HotRechargeSetupL.TestField("Phone Number Length");
        HotRechargeSetupL.TestField("Allowed Phone Number Prefixes");

        AllowedPrefixes := HotRechargeSetupL."Allowed Phone Number Prefixes";

        if StrLen(Input) <> HotRechargeSetupL."Phone Number Length" then begin
            IsHandled := true;
            ReturnValue := false;
            ErrorTxt := StrSubstNo('Phone number must be %1 characters long.', HotRechargeSetupL."Phone Number Length");
            exit;
        end;

        PrefixList := AllowedPrefixes.Split(',');

        Prefix := CopyStr(Input, 1, 3);
        if not PrefixList.Contains(Prefix) then begin
            IsHandled := true;
            ReturnValue := false;
            ErrorTxt := StrSubstNo('Phone number prefix is not valid. Allowed prefixes are: %1.', AllowedPrefixes);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnBeforeValidateChangeQty, '', false, false)]
    internal procedure POSTransactionEvents_OnBeforeValidateChangeQty(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var Proceed: Boolean; var ErrorText: Text[250]; var TransactionContext: Record "LSC POS Transaction Context")
    var
        ItemL: Record Item;
        POSTransLineL: Record "LSC POS Trans. Line";
        POSLINES: Codeunit "LSC POS Trans. Lines";
    begin
        POSLINES.GetCurrentLine(POSTransLineL);

        if ItemL.Get(POSTransLineL.Number) then
            if ItemL."Is Hot Recharge Product" then
                if ItemL."Hot Recharge Rst. Qty Change" then begin
                    Proceed := false;
                    ErrorText := 'Cannot Change Quantity On Hot Recharge Line!';
                end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnBeforeTotalExecuted, '', false, false)]
    local procedure POSTransactionEvents_OnAfterRunCommand(var POSTransaction: Record "LSC POS Transaction")
    var
        InfocodeL: Record "LSC Infocode";
        InformationSubcodeL: Record "LSC Information Subcode";
        POSTransInfocodeEntryL: Record "LSC POS Trans. Infocode Entry";
        HotRechargeSetup: Record "Hot Recharge Setup";
        POSTransLineL: Record "LSC POS Trans. Line";
    begin
        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        POSTransLineL.SetRange("Hot Recharge Validated", false);
        If POSTransLineL.FindFirst() then
            repeat
                HotRechargeSetup.Get();
                POSTransLineL."Hot Recharge Send SMS" := HotRechargeSetup."Send SMS";

                POSTransInfocodeEntryL.Reset();
                POSTransInfocodeEntryL.SetRange("Receipt No.", POSTransLineL."Receipt No.");
                POSTransInfocodeEntryL.SetRange("Transaction Type", POSTransInfocodeEntryL."Transaction Type"::"Sales Entry");
                POSTransInfocodeEntryL.SetRange("Line No.", POSTransLineL."Line No.");
                POSTransInfocodeEntryL.SetRange("Source Code", POSTransLineL.Number);
                POSTransInfocodeEntryL.SetFilter(Information, '<>%1', '');
                If POSTransInfocodeEntryL.FindFirst() then
                    repeat
                        InfocodeL.Reset();
                        InfocodeL.SetRange("Hot Recharge Number", true);
                        InfocodeL.SetRange(Code, POSTransInfocodeEntryL.Infocode);
                        if InfocodeL.FindFirst() then begin
                            POSTransLineL."Is Hot Recharge Product" := true;
                            POSTransLineL."Hot Recharge Phone No." := POSTransInfocodeEntryL.Information;
                        end;
                    until POSTransInfocodeEntryL.Next() = 0;
                POSTransLineL.Modify(false);
            until POSTransLineL.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnAfterTotalExecuted, '', false, false)]
    internal procedure POSTransactionEvents_OnAfterTotalExecuted(var POSTransaction: Record "LSC POS Transaction")
    var
        POSTransLineL: Record "LSC POS Trans. Line";
    begin
        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        POSTransLineL.SetRange("Hot Recharge Validated", false);
        If POSTransLineL.FindFirst() then
            repeat
                if CallRechargeAPI(POSTransaction, POSTransLineL) then begin
                    POSTransLineL."Hot Recharge Validated" := true;
                    POSTransLineL.Modify(false);
                end;
            until POSTransLineL.Next() = 0;
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeRunCommandV2', '', false, false)]
    // internal procedure POSTransactionEvents_OnBeforeRunCommand(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var POSMenuLine: Record "LSC POS Menu Line"; var TransactionContext: Record "LSC POS Transaction Context"; var isHandled: Boolean; TenderType: Record "LSC Tender Type")
    // var
    //     POSMenuLineL: Record "LSC POS Menu Line";
    //     POSMenuProfileL: Record "LSC POS Menu Profile";
    //     JsonBody: Text;
    //     JsonObject: JsonObject;
    //     Error001: Label 'Failed to send the HTTP request, Currency must be equal to: %1 current value is: %2';
    //     POSTransLineL: Record "LSC POS Trans. Line";
    // begin
    //     if POSMenuLine.Command <> Enum::"LSC POS Command".Names.Get(Enum::"LSC POS Command".Ordinals.IndexOf(Enum::"LSC POS Command"::CURR_K.AsInteger())) then
    //         exit;

    //     POSTransLineL.Reset;
    //     POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
    //     POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
    //     POSTransLineL.SetRange("Is Hot Recharge Product", true);
    //     POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
    //     If POSTransLineL.FindFirst() then
    //         repeat
    //             if POSTransLineL."Hot Recharge Product Currency" <> POSMenuLine.Parameter then begin
    //                 POSTransLineL.VoidLine();
    //                 Clear(JsonObject);

    //                 JsonObject.Add('OriginalReference', POSTransLineL."Hot Recharge AgentReference");
    //                 JsonObject.Add('Confirmed', false);
    //                 JsonObject.Add('AgentReference', StrSubstNo('%1F', POSTransLineL."Hot Recharge AgentReference"));

    //                 JsonObject.WriteTo(JsonBody);

    //                 PostHotRechargeRequest(POSTransaction, StrSubstNo('%1%2', POSTransaction."Receipt No.", POSTransLineL."Line No."), JsonBody, StrSubstNo(Error001, POSTransLineL."Hot Recharge Product Currency", POSMenuLine.Parameter), true, false);
    //                 POSTransaction_CU.CancelPressed(true, 0);
    //                 isHandled := true;
    //             end;
    //         until POSTransLineL.Next() = 0;
    // end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeRunCommandV2', '', false, false)]
    internal procedure POSTransactionEvents_OnBeforeRunCommand(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var POSMenuLine: Record "LSC POS Menu Line"; var TransactionContext: Record "LSC POS Transaction Context"; var isHandled: Boolean; TenderType: Record "LSC Tender Type")
    var
        POSMenuLineL: Record "LSC POS Menu Line";
        POSMenuProfileL: Record "LSC POS Menu Profile";
        JsonBody: Text;
        JsonObject: JsonObject;
        Error001: Label 'Failed to send the HTTP request, Currency must be equal to: %1 current value is: %2';
        POSTransLineL: Record "LSC POS Trans. Line";
    begin
        if POSMenuLine.Command <>
           Enum::"LSC POS Command".Names.Get(
               Enum::"LSC POS Command".Ordinals.IndexOf(
                   Enum::"LSC POS Command"::CURR_K.AsInteger()))
        then
            exit;

        POSTransLineL.Reset();
        POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");

        if POSTransLineL.FindFirst() then
            repeat
                if POSTransLineL."Hot Recharge Product Currency" <> POSMenuLine.Parameter then begin
                    POSTransLineL.VoidLine();

                    Clear(JsonObject);
                    Clear(JsonBody);

                    JsonObject.Add('OriginalReference', POSTransLineL."Hot Recharge AgentReference");

                    JsonObject.Add('Confirmed', false);

                    JsonObject.Add('AgentReference', StrSubstNo('%1F', POSTransLineL."Hot Recharge AgentReference"));

                    JsonObject.WriteTo(JsonBody);

                    PostHotRechargeRequest(
                        POSTransaction,
                        StrSubstNo('%1%2', POSTransaction."Receipt No.", POSTransLineL."Line No."), JsonBody, StrSubstNo(Error001, POSTransLineL."Hot Recharge Product Currency", POSMenuLine.Parameter), true, false);

                    POSTransaction_CU.CancelPressed(true, Enum::"LSC POS Trans. Request Infoc.".FromInteger(0));

                    isHandled := true;
                end;
            until POSTransLineL.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", OnBeforeDeleteRelatedEntries, '', false, false)]
    internal procedure POSPostUtility_OnBeforeDeleteRelatedEntries(var POSTransaction: Record "LSC POS Transaction")
    var
        JsonBody: Text;
        JsonObject: JsonObject;
        POSTransLineL: Record "LSC POS Trans. Line";
        Error001: Label 'Failed to send the HTTP request.';
    begin
        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Hot Recharge Validated", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        If POSTransLineL.FindFirst() then
            repeat
                Clear(JsonObject);
                JsonObject.Add('OriginalReference', POSTransLineL."Hot Recharge AgentReference");

                if gPOSSessionCU.GetValue('HotRechargeTransIsVoided') = 'true' then begin
                    JsonObject.Add('Confirmed', false);
                    JsonObject.Add('AgentReference', StrSubstNo('%1F', POSTransLineL."Hot Recharge AgentReference"));
                end else begin
                    JsonObject.Add('Confirmed', true);
                    JsonObject.Add('AgentReference', StrSubstNo('%1C', POSTransLineL."Hot Recharge AgentReference"));
                end;

                JsonObject.WriteTo(JsonBody);
                PostHotRechargeRequest(POSTransaction, StrSubstNo('%1%2', POSTransaction."Receipt No.", POSTransLineL."Line No."), JsonBody, Error001, true, true);
            until POSTransLineL.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnVoidTransaction', '', false, false)]
    internal procedure POSTransactionEvents_OnVoidTransaction(var POSTrans: Record "LSC POS Transaction")
    begin
        gPOSSessionCU.SetValue('HotRechargeTransIsVoided', 'true');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnAfterVoidLine', '', false, false)]
    internal procedure POSTransactionEvents_OnAfterVoidLine(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line")
    var
        JsonBody: Text;
        JsonObject: JsonObject;
        HotRechargeEntry: Record "Hot Recharge Entry";
        Error001: Label 'Failed to send the HTTP request.';
    begin
        if not POSTransLine."Is Hot Recharge Product" then
            exit;

        HotRechargeEntry.Reset();
        HotRechargeEntry.SetRange("Entry No.", StrSubstNo('%1%2', POSTransaction."Receipt No.", POSTransLine."Line No."));
        HotRechargeEntry.SetRange(Validated, true);
        if HotRechargeEntry.FindFirst() then begin
            HotRechargeEntry.Validated := false;
            HotRechargeEntry.Modify();
        end;

        Clear(JsonObject);

        JsonObject.Add('OriginalReference', POSTransLine."Hot Recharge AgentReference");
        JsonObject.Add('Confirmed', false);
        JsonObject.Add('AgentReference', StrSubstNo('%1F', POSTransLine."Hot Recharge AgentReference"));

        JsonObject.WriteTo(JsonBody);

        PostHotRechargeRequest(POSTransaction, StrSubstNo('%1%2', POSTransaction."Receipt No.", POSTransLine."Line No."), JsonBody, Error001, true, false);
    end;

    procedure CallLoginAPI(POSTransaction: Record "LSC POS Transaction"; pPOSTransLine: Record "LSC POS Trans. Line");
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        HttpResponse: HttpResponseMessage;
        JsonBody, ResponseContent, Token, RefreshToken : Text;
        HotRechargeSetupL: Record "Hot Recharge Setup";
        JsonObject, JsonResponse : JsonObject;
        TokenValue: JsonToken;
        RefreshTokenValue: JsonToken;
        LogStatus: Option Success,Failed;
        Error001: Label 'Failed to send the HTTP request.';
    begin
        HotRechargeSetupL.Get();

        // Construct the JSON body for the POST request
        Clear(JsonObject);
        JsonObject.Add('AccessCode', Format(HotRechargeSetupL."Access Code"));
        JsonObject.Add('password', Format(HotRechargeSetupL.Password));

        JsonObject.WriteTo(JsonBody);

        // Set the HttpContent to the JSON body
        HttpContent.WriteFrom(JsonBody);

        HttpHeaders.Clear();
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');

        // Set the necessary headers (Content-Type: application/json)
        HttpHeaders.Add('Content-Type', 'application/json');

        // Send the POST request
        if HttpClient.Post(HotRechargeSetupL."API Login URL", HttpContent, HttpResponse) then
            // Check if the response is successful
            if HttpResponse.IsSuccessStatusCode then begin
                // Read the response content
                HttpResponse.Content.ReadAs(ResponseContent);
                // Parse the JSON response
                if JsonResponse.ReadFrom(ResponseContent) then begin
                    if JsonResponse.Get('token', TokenValue) and JsonResponse.Get('refreshToken', RefreshTokenValue) then begin
                        if TokenValue.IsValue then
                            TokenValue.WriteTo(Token);
                        if RefreshTokenValue.IsValue then
                            RefreshTokenValue.WriteTo(RefreshToken);

                        HotRechargeSetupL."Access Token" := Token;
                        HotRechargeSetupL."Access Refresh Token" := RefreshToken;
                        HotRechargeSetupL.Modify(true);
                        FillHotRechargeEntryErrorRecord(StrSubstNo('%1%2', POSTransaction."Receipt No.", pPOSTransLine."Line No."), JsonBody, ResponseContent, LogStatus::Success, HttpClient.GetBaseAddress, '');
                        exit;
                    end;
                end else begin
                    FillHotRechargeEntryErrorRecord(StrSubstNo('%1%2', POSTransaction."Receipt No.", pPOSTransLine."Line No."), JsonBody, ResponseContent, LogStatus::Failed, HttpClient.GetBaseAddress, '');
                    POSTransaction_CU.MessageBeep(Error001);
                    exit;
                end;
            end;

        FillHotRechargeEntryErrorRecord(StrSubstNo('%1%2', POSTransaction."Receipt No.", pPOSTransLine."Line No."), JsonBody, Format(HttpResponse.IsSuccessStatusCode), LogStatus::Failed, HttpClient.GetBaseAddress, '');
        POSTransaction_CU.MessageBeep(Error001);
    end;

    procedure CallRechargeAPI(pPOSTransaction: Record "LSC POS Transaction"; var pPOSTransLine: Record "LSC POS Trans. Line"): Boolean
    var
        HotRechargeSetupL: Record "Hot Recharge Setup";
        JsonBody: Text;
        JsonObject, JsonObject2 : JsonObject;
        JsonArray: JsonArray;
        Error001: Label 'Failed to send the HTTP request.';
    begin
        CallLoginAPI(pPOSTransaction, pPOSTransLine); // Ensure CallLoginAPI is implemented and works as expected

        HotRechargeSetupL.Get();
        // Define the JSON payload
        pPOSTransLine."Hot Recharge AgentReference" := StrSubstNo('%1-%2-%3-%4-%5-%6', HotRechargeSetupL."HR Division ID", pPOSTransaction."Store No.", pPOSTransaction."POS Terminal No.", pPOSTransaction."Staff ID", pPOSTransaction."Receipt No.", pPOSTransLine."Line No.");

        Clear(JsonObject);
        JsonObject.Add('AgentReference', pPOSTransLine."Hot Recharge AgentReference");
        JsonObject.Add('ProductId', pPOSTransLine."Hot Recharge Product ID");
        JsonObject.Add('Target', pPOSTransLine."Hot Recharge Phone No.");
        JsonObject.Add('Amount', pPOSTransLine.Amount);

        Clear(JsonObject2);
        JsonObject2.Add('Name', 'MakeReservation');
        JsonObject2.Add('ParameterType', 'bool');
        JsonObject2.Add('Value', 'true');

        JsonArray.Add(JsonObject2);

        if pPOSTransLine."Hot Recharge Send SMS" then begin
            Clear(JsonObject2);
            JsonObject2.Add('Name', 'SendReservationSMSToCustomer');
            JsonObject2.Add('ParameterType', 'bool');
            JsonObject2.Add('Value', Format(pPOSTransLine."Hot Recharge Send SMS"));
            JsonArray.Add(JsonObject2);
        end;

        if JsonArray.Count <> 0 then
            JsonObject.Add('RechargeOptions', JsonArray);

        JsonObject.WriteTo(JsonBody);
        if PostHotRechargeRequest(pPOSTransaction, StrSubstNo('%1%2', pPOSTransaction."Receipt No.", pPOSTransLine."Line No."), JsonBody, Error001, false, true) then
            exit(true);
        exit(false);
    end;

    internal procedure PostHotRechargeRequest(pPOSTransaction: Record "LSC POS Transaction"; pEntryNo: Code[100]; pJsonBody: Text; pError: Text; pComplete: Boolean; pSetReplicated: Boolean): Boolean
    var
        HotRechargeSetupL: Record "Hot Recharge Setup";
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        HttpResponseMessage: HttpResponseMessage;
        HttpRequestMessage: HttpRequestMessage;
        ResponseContent, Authorization, URI, headerValueLogs : Text;
        LogStatus: Option Success,Failed;
        AuthToken: Text[2045]; // Token for authorization
    begin
        HotRechargeSetupL.Get();

        // Set the HttpContent to the JSON body
        HttpContent.WriteFrom(pJsonBody);

        // Set up the authorization token
        AuthToken := COPYSTR(HotRechargeSetupL."Access Token", 2, STRLEN(HotRechargeSetupL."Access Token") - 2);
        Authorization := StrSubstNo('Bearer %1', AuthToken);

        // Set the necessary headers (Content-Type: application/json)
        HttpHeaders.Clear();

        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');

        HttpHeaders.Add('content-type', 'application/json');

        if pComplete then
            HttpRequestMessage.SetRequestUri(HotRechargeSetupL."API Comp Recharge Product URL")
        else
            HttpRequestMessage.SetRequestUri(HotRechargeSetupL."API Recharge Product URL");

        HttpRequestMessage.Method := 'POST';
        HttpRequestMessage.Content := HttpContent;
        HttpRequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Remove('accept');
        RequestHeaders.Add('accept', 'application/json');
        RequestHeaders.Remove('authorization');
        RequestHeaders.Add('authorization', Authorization);

        if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            // Send the POST request
            // Check if the response is successful
            if HttpResponseMessage.IsSuccessStatusCode then begin
                // Read the response content
                HttpResponseMessage.Content.ReadAs(ResponseContent);
                // Parse the JSON response
                FillHotRechargeEntryErrorRecord(pEntryNo, pJsonBody, ResponseContent, LogStatus::Success, URI, headerValueLogs);

                SetHotRechargeEntryValidated(pEntryNo, pSetReplicated);
                if pSetReplicated and pComplete then begin
                    SetHotRechargeEntryReplicated(pEntryNo, pSetReplicated);
                    exit(true);
                end;

                if not pSetReplicated then begin
                    VoidHotRechargeLine(pPOSTransaction);
                    exit(false);
                end;

                exit(true);
            end;
        FillHotRechargeEntryErrorRecord(pEntryNo, pJsonBody, Format(HttpResponseMessage.IsSuccessStatusCode), LogStatus::Failed, URI, headerValueLogs);
        POSTransaction_CU.ErrorBeep(pError);

        VoidHotRechargeLine(pPOSTransaction);
        exit(false);
    end;

    // internal procedure VoidHotRechargeLine(pPOSTransaction: Record "LSC POS Transaction")
    // var
    //     POSTransLineL: Record "LSC POS Trans. Line";
    // begin
    //     POSTransaction_CU.SetPOSState('SALES');
    //     POSTransaction_CU.CancelPressed(true,0);

    //     POSTransLineL.Reset;
    //     POSTransLineL.SetRange("Receipt No.", pPOSTransaction."Receipt No.");
    //     POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
    //     POSTransLineL.SetRange("Is Hot Recharge Product", true);
    //     POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
    //     If POSTransLineL.FindFirst() then
    //         POSTransLineL.VoidLine();
    // end;

    internal procedure VoidHotRechargeLine(pPOSTransaction: Record "LSC POS Transaction")
    var
        POSTransLineL: Record "LSC POS Trans. Line";
        RequestInfocL: Enum "LSC POS Trans. Request Infoc.";
    begin
        POSTransaction_CU.SetPOSState('SALES');

        RequestInfocL := Enum::"LSC POS Trans. Request Infoc.".FromInteger(0);
        POSTransaction_CU.CancelPressed(true, RequestInfocL);

        POSTransLineL.Reset();
        POSTransLineL.SetRange("Receipt No.", pPOSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");

        if POSTransLineL.FindFirst() then
            POSTransLineL.VoidLine();
    end;

    internal procedure SetHotRechargeEntryReplicated(pEntryNo: Code[100]; pReplicated: Boolean)
    var
        HotRechargeEntryL: Record "Hot Recharge Entry";
    begin
        if HotRechargeEntryL.Get(pEntryNo) then begin
            HotRechargeEntryL.Replicated := pReplicated;
            HotRechargeEntryL.Modify();
        end;
    end;

    internal procedure SetHotRechargeEntryValidated(pEntryNo: Code[100]; pValidated: Boolean)
    var
        HotRechargeEntryL: Record "Hot Recharge Entry";
    begin
        if HotRechargeEntryL.Get(pEntryNo) then begin
            HotRechargeEntryL.Validated := pValidated;
            HotRechargeEntryL.Modify();
        end;
    end;

    internal procedure FillHotRechargeEntryErrorRecord(pEntryNo: Code[100]; pPayload: Text; pResponse: Text; pLogStatus: Option Success,Failed; pURI: Text; pheader: Text)
    var
        HotRechargeEntryL: Record "Hot Recharge Entry";
        HotRechargeEntryLogsL: Record "Hot Recharge Entry Logs";
        OutStream: OutStream;
    begin
        if not HotRechargeEntryL.Get(pEntryNo) then begin
            Clear(HotRechargeEntryL);
            HotRechargeEntryL.Init();
            HotRechargeEntryL.Validate("Entry No.", pEntryNo);
            HotRechargeEntryL.Insert();
        end;

        Clear(HotRechargeEntryLogsL);
        HotRechargeEntryLogsL.Init();
        HotRechargeEntryLogsL.Validate("Entry No.", HotRechargeEntryL."Entry No.");
        HotRechargeEntryLogsL.Validate("Log No.", GetLastHotRechargeEntryLogNo(HotRechargeEntryL));
        HotRechargeEntryLogsL.Validate("Log Date", DT2Date(CurrentDateTime));
        HotRechargeEntryLogsL.Validate("Log Time", DT2Time(CurrentDateTime));
        HotRechargeEntryLogsL.Validate("Log Status", pLogStatus);
        HotRechargeEntryLogsL.Insert();

        if pPayload <> '' then begin
            HotRechargeEntryLogsL."Request File".CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(pPayload);
        end;

        if pResponse <> '' then begin
            HotRechargeEntryLogsL."Response File".CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(pResponse);
        end;
        HotRechargeEntryLogsL.Validate("Hot Recharge URI", pURI);
        HotRechargeEntryLogsL.Validate("Hot Recharge Headers", pheader);
        HotRechargeEntryLogsL.Modify();
    end;

    internal procedure GetLastHotRechargeEntryLogNo(pHotRechargeEntry: Record "Hot Recharge Entry"): Integer
    var
        HotRechargeEntryLogsL: Record "Hot Recharge Entry Logs";
    begin
        HotRechargeEntryLogsL.Reset();
        HotRechargeEntryLogsL.SetRange("Entry No.", pHotRechargeEntry."Entry No.");
        if HotRechargeEntryLogsL.FindLast() then
            exit(HotRechargeEntryLogsL."Log No." + 1000)
        else
            exit(1000);
    end;
}