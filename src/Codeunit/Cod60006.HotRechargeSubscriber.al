/*codeunit 60006 "Hot Recharge Subscriber"
{
    access = Internal;

    var
        gPOSSessionCU: Codeunit "LSC POS Session";
        POSTransaction_CU: Codeunit "LSC POS Transaction";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnAfterStartNewTransaction', '', false, false)]
    internal procedure POSTransactionEvents_OnAfterStartNewTransaction()
    begin
        gPOSSessionCU.DeleteValue('HotRechargeSendSMS');
        gPOSSessionCU.DeleteValue('IsHotRecharge');
        gPOSSessionCU.DeleteValue('HotRechargePhoneNo');
        gPOSSessionCU.DeleteValue('HotRechargeLineNo');
        gPOSSessionCU.DeleteValue('HotRechargeProductID');
        gPOSSessionCU.DeleteValue('HotRechargeProductCurrency');
        gPOSSessionCU.DeleteValue('HotRechargeTransIsVoided');
        gPOSSessionCU.DeleteValue('HotRechargeAgentReference');
    end;

    [EventSubscriber(ObjectType::Page, Page::"lsc Retail Item Card", OnAfterValidateEvent, "Keying in Price", false, false)]
    Internal procedure Item_OnAfterValidateEvent(var Rec: Record Item; var xRec: Record Item)
    begin
        If Rec."Is Hot Recharge Product" then
            Rec.TestField(Rec."LSC Keying in Price", Rec."LSC Keying in Price"::"Must Key in New Price");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnAfterValidateItemLine, '', false, false)]
    Internal procedure POSTransactionEvents_OnAfterValidateItemLine(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var Proceed: Boolean)
    var
        ItemL: Record Item;
        Barcode: Record "LSC Barcodes";
        ItemNo: Code[20];
        POSTransLineL: Record "LSC POS Trans. Line";
        Text001: Label 'Please void the previous Hot Recharge';
    begin
        If CurrInput = '' then
            exit;

        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        If not POSTransLineL.FindFirst() then
            exit;

        ItemNo := CurrInput;

        Barcode.Reset();
        Barcode.SetRange("Item No.", CurrInput);
        If Barcode.FindFirst() then
            ItemNo := Barcode."Item No.";

        ItemL.Reset();
        ItemL.SetRange("No.", ItemNo);
        ItemL.SetRange("Is Hot Recharge Product", true);
        If ItemL.FindFirst() then begin
            POSTransaction_CU.ErrorBeep(Text001);
            Proceed := true;
            exit;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnAfterItemLine, '', false, false)]
    Internal procedure POSTransactionEvents_OnAfterItemLine(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text)
    var
        ItemL: Record Item;
    begin
        If ItemL.Get(CurrInput) then begin
            POSTransLine."Is Hot Recharge Product" := ItemL."Is Hot Recharge Product";
            gPOSSessionCU.SetValue('HotRechargeProductID', Format(ItemL."Hot Recharge Product ID"));
            gPOSSessionCU.SetValue('HotRechargeProductCurrency', Format(ItemL."Hot Recharge Product Currency"));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Infocode Utility", OnBeforeIsInputOkV2, '', false, false)]
    local procedure POSInfocodeUtility_OnBeforeIsInputOkV2(InfoCodeRec: Record "LSC Infocode"; Input: Text; var ErrorTxt: Text; var Line: Record "LSC POS Trans. Line"; var Canceled: Boolean; MgrKeyActive: Boolean; Training: Boolean; var TSError: Boolean; Quantity: Decimal; SerialNo: Code[50]; EntryVariantCode: Code[10]; SetPrice: Boolean; NewPrice: Decimal; LinkedLineInserted: Boolean; var EntryLineNo: Integer; var IsHandled: Boolean; var ReturnValue: Boolean)
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction", OnBeforeValidateChangeQty, '', false, false)]
    internal procedure POSTransactionEvents_OnBeforeValidateChangeQty(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var Proceed: Boolean; var ErrorText: Text[250])
    var
        ItemL: Record Item;
    begin
        if ItemL.Get(POSTransLine.Number) then
            if ItemL."Is Hot Recharge Product" then
                if ItemL."Hot Recharge Rst. Qty Change" then begin
                    Proceed := false;
                    ErrorText := 'Cannot Change Quantity On Hot Recharge Item!';
                end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnBeforeTotalPressed, '', false, false)]
    Internal procedure POSTransactionEvents_OnBeforeTotalPressed(var POSTransaction: Record "LSC POS Transaction"; var IsHandled: Boolean)
    var
        ItemL: Record Item;
        InfocodeL: Record "LSC Infocode";
        InformationSubcodeL: Record "LSC Information Subcode";
        POSTransInfocodeEntryL: Record "LSC POS Trans. Infocode Entry";
        POSTransLineL: Record "LSC POS Trans. Line";
        HotRechargeProductID, HotRechargeProductCurrency, HotRechargeSendSMS, IsHotRecharge, HotRechargePhoneNo, HotRechargeLineNo : Text;
    begin
        // Check if it is a Hot Recharge product
        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        If not POSTransLineL.FindFirst() then
            exit;

        If ItemL.Get(POSTransLineL.Number) then begin
            gPOSSessionCU.SetValue('HotRechargeProductID', Format(ItemL."Hot Recharge Product ID"));
            gPOSSessionCU.SetValue('HotRechargeProductCurrency', Format(ItemL."Hot Recharge Product Currency"));

            HotRechargeProductID := gPOSSessionCU.GetValue('HotRechargeProductID');
            HotRechargeProductCurrency := gPOSSessionCU.GetValue('HotRechargeProductCurrency');
        end;

        POSTransInfocodeEntryL.Reset();
        POSTransInfocodeEntryL.SetRange("Receipt No.", POSTransLineL."Receipt No.");
        POSTransInfocodeEntryL.SetRange("Transaction Type", POSTransInfocodeEntryL."Transaction Type"::"Sales Entry");
        POSTransInfocodeEntryL.SetRange("Line No.", POSTransLineL."Line No.");
        POSTransInfocodeEntryL.SetRange("Source Code", POSTransLineL.Number);
        POSTransInfocodeEntryL.SetFilter(Information, '<>%1', '');
        If POSTransInfocodeEntryL.FindFirst() then begin
            repeat
                InfocodeL.Reset();
                InfocodeL.SetRange(Code, POSTransInfocodeEntryL.Infocode);
                if InfocodeL.FindFirst() then begin
                    if InfocodeL."Hot Recharge Send SMS" then begin
                        if InformationSubcodeL.Get(POSTransInfocodeEntryL.Infocode, POSTransInfocodeEntryL.Subcode) then begin
                            case InformationSubcodeL.Subcode of
                                '01':
                                    gPOSSessionCU.SetValue('HotRechargeSendSMS', 'true');
                                '02':
                                    gPOSSessionCU.SetValue('HotRechargeSendSMS', 'false');
                            end;
                        end;
                    end;
                    if InfocodeL."Hot Recharge Number" then begin
                        gPOSSessionCU.SetValue('IsHotRecharge', Format(True));
                        gPOSSessionCU.SetValue('HotRechargePhoneNo', POSTransInfocodeEntryL.Information);
                        gPOSSessionCU.SetValue('HotRechargeLineNo', Format(POSTransLineL."Line No."));
                    end;
                end;
            until POSTransInfocodeEntryL.Next() = 0;
            HotRechargeSendSMS := gPOSSessionCU.GetValue('HotRechargeSendSMS');
            IsHotRecharge := gPOSSessionCU.GetValue('IsHotRecharge');
            HotRechargePhoneNo := gPOSSessionCU.GetValue('HotRechargePhoneNo');
            HotRechargeLineNo := gPOSSessionCU.GetValue('HotRechargeLineNo');
        end;

        if (HotRechargeProductID = '') or (HotRechargeProductCurrency = '') or (HotRechargeSendSMS = '') or (IsHotRecharge = '') or (HotRechargePhoneNo = '') or (HotRechargeLineNo = '') then begin
            POSTransaction_CU.CancelPressed(true, 0);
            POSTransLineL.VoidLine();
            POSTransaction_CU.ErrorBeep('Phone Number Must Be Fill');
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", OnAfterTotalExecuted, '', false, false)]
    internal procedure POSTransactionEvents_OnAfterTotalExecuted(var POSTransaction: Record "LSC POS Transaction")
    var
        Balance: Decimal;
        PhoneNo: Code[20];
        POSTransLineL: Record "LSC POS Trans. Line";
        HotRechargeProductID: Integer;
    begin
        if gPOSSessionCU.GetValue('IsHotRecharge') = '' then
            exit;

        if gPOSSessionCU.GetValue('HotRechargePhoneNo') = '' then
            exit;

        if gPOSSessionCU.GetValue('HotRechargeProductID') = '' then
            exit;

        Evaluate(HotRechargeProductID, gPOSSessionCU.GetValue('HotRechargeProductID'));
        PhoneNo := gPOSSessionCU.GetValue('HotRechargePhoneNo');

        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", POSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        If POSTransLineL.FindFirst() then
            Balance := POSTransLineL.Amount;

        CallRechargeAPI(POSTransaction, HotRechargeProductID, PhoneNo, Balance);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnAfterTenderKeyPressedEx', '', false, false)]
    internal procedure OnAfterTenderKeyPressedEx(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var TenderTypeCode: Code[10]; var TenderAmountText: Text; var IsHandled: Boolean)
    begin
        CheckIfHotRechargeValueAreValid(POSTransaction, IsHandled);
    end;

    internal procedure CheckIfHotRechargeValueAreValid(pPOSTransaction: Record "LSC POS Transaction"; pisHandled: Boolean): Boolean
    var
        HotRechargePhoneNo, HotRechargeProductCurrency, HotRechargeSendSMS, IsHotRecharge, HotRechargeLineNo, HotRechargeProductID : text;
        POSTransLineL: Record "LSC POS Trans. Line";
    begin
        HotRechargePhoneNo := gPOSSessionCU.GetValue('HotRechargePhoneNo');
        HotRechargeSendSMS := gPOSSessionCU.GetValue('HotRechargeSendSMS');
        IsHotRecharge := gPOSSessionCU.GetValue('IsHotRecharge');
        HotRechargeLineNo := gPOSSessionCU.GetValue('HotRechargeLineNo');
        HotRechargeProductID := gPOSSessionCU.GetValue('HotRechargeProductID');
        HotRechargeProductCurrency := gPOSSessionCU.GetValue('HotRechargeProductCurrency');

        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", pPOSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        If POSTransLineL.FindFirst() then
            if (HotRechargePhoneNo = '') or
                (HotRechargeSendSMS = '') or
                (IsHotRecharge = '') or
                (HotRechargeLineNo = '') or
                (HotRechargeProductID = '') or
                (HotRechargeProductCurrency = '') then begin
                pisHandled := true;
                POSTransaction_CU.CancelPressed(true, 0);
                POSTransLineL.VoidLine();
                exit(true);
            end;

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Transaction Events", 'OnBeforeRunCommand', '', false, false)]
    internal procedure POSTransactionEvents_OnBeforeRunCommand(var POSTransaction: Record "LSC POS Transaction"; var POSTransLine: Record "LSC POS Trans. Line"; var CurrInput: Text; var POSMenuLine: Record "LSC POS Menu Line"; var isHandled: Boolean; TenderType: Record "LSC Tender Type"; var CusomterOrCardNo: Code[20])
    var
        POSMenuLineL: Record "LSC POS Menu Line";
        POSMenuProfileL: Record "LSC POS Menu Profile";
        HotRechargeCurr: Code[10];
        JsonBody, AgentReference : Text;
        JsonObject: JsonObject;
        Error001: Label 'Failed to send the HTTP request, Currency must be equal to: %1 current value is: %2';
    begin
        if gPOSSessionCU.GetValue('IsHotRecharge') = '' then
            exit;

        if POSMenuLine.Command <> Enum::"LSC POS Command".Names.Get(Enum::"LSC POS Command".Ordinals.IndexOf(Enum::"LSC POS Command"::CURR_K.AsInteger())) then
            exit;

        HotRechargeCurr := gPOSSessionCU.GetValue('HotRechargeProductCurrency');
        if HotRechargeCurr = POSMenuLine.Parameter then
            exit;

        if CheckIfHotRechargeValueAreValid(POSTransaction, IsHandled) then
            exit;

        Clear(JsonObject);

        AgentReference := gPOSSessionCU.GetValue('HotRechargeAgentReference');
        JsonObject.Add('OriginalReference', AgentReference);
        JsonObject.Add('Confirmed', false);
        JsonObject.Add('AgentReference', StrSubstNo('%1F', AgentReference));

        JsonObject.WriteTo(JsonBody);

        PostHotRechargeRequest(POSTransaction, JsonBody, StrSubstNo(Error001, HotRechargeCurr, POSMenuLine.Parameter), true, false);

        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LSC POS Post Utility", OnBeforeDeleteRelatedEntries, '', false, false)]
    internal procedure POSPostUtility_OnBeforeDeleteRelatedEntries(var POSTransaction: Record "LSC POS Transaction")
    var
        JsonBody, AgentReference : Text;
        JsonObject: JsonObject;

        Error001: Label 'Failed to send the HTTP request.';
    begin
        if gPOSSessionCU.GetValue('IsHotRecharge') = '' then
            exit;

        Clear(JsonObject);

        AgentReference := gPOSSessionCU.GetValue('HotRechargeAgentReference');
        JsonObject.Add('OriginalReference', AgentReference);

        if gPOSSessionCU.GetValue('HotRechargeTransIsVoided') = 'true' then begin
            JsonObject.Add('Confirmed', false);
            JsonObject.Add('AgentReference', StrSubstNo('%1F', AgentReference));
        end else begin
            JsonObject.Add('Confirmed', true);
            JsonObject.Add('AgentReference', StrSubstNo('%1C', AgentReference));
        end;

        JsonObject.WriteTo(JsonBody);
        PostHotRechargeRequest(POSTransaction, JsonBody, Error001, true, true);
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
        AgentReference: Text;
        HotRechargeEntry: Record "Hot Recharge Entry";
        Error001: Label 'Failed to send the HTTP request.';
    begin
        if not POSTransLine."Is Hot Recharge Product" then
            exit;

        HotRechargeEntry.Reset();
        HotRechargeEntry.SetRange("Entry No.", POSTransaction."Receipt No.");
        HotRechargeEntry.SetRange(Validated, true);
        if HotRechargeEntry.FindFirst() then begin
            HotRechargeEntry.Validated := false;
            HotRechargeEntry.Modify();
        end;

        Clear(JsonObject);

        AgentReference := gPOSSessionCU.GetValue('HotRechargeAgentReference');
        JsonObject.Add('OriginalReference', AgentReference);
        JsonObject.Add('Confirmed', false);
        JsonObject.Add('AgentReference', StrSubstNo('%1F', AgentReference));

        JsonObject.WriteTo(JsonBody);

        PostHotRechargeRequest(POSTransaction, JsonBody, Error001, true, false);
    end;

    procedure CallLoginAPI(POSTransaction: Record "LSC POS Transaction");
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
                        FillHotRechargeEntryErrorRecord(POSTransaction, JsonBody, ResponseContent, LogStatus::Success, HttpClient.GetBaseAddress, '');
                        exit;
                    end;
                end else begin
                    FillHotRechargeEntryErrorRecord(POSTransaction, JsonBody, ResponseContent, LogStatus::Failed, HttpClient.GetBaseAddress, '');
                    POSTransaction_CU.MessageBeep(Error001);
                    exit;
                end;
            end;

        FillHotRechargeEntryErrorRecord(POSTransaction, JsonBody, Format(HttpResponse.IsSuccessStatusCode), LogStatus::Failed, HttpClient.GetBaseAddress, '');
        POSTransaction_CU.MessageBeep(Error001);
    end;

    procedure CallRechargeAPI(POSTransaction: Record "LSC POS Transaction"; ProductID: Integer; PhoneNumber: Text[100]; Amount: Decimal)
    var
        HotRechargeSetupL: Record "Hot Recharge Setup";
        AgentReference, JsonBody : Text;
        JsonObject, JsonObject2 : JsonObject;

        JsonArray: JsonArray;
        Error001: Label 'Failed to send the HTTP request.';
    begin
        CallLoginAPI(POSTransaction); // Ensure CallLoginAPI is implemented and works as expected

        HotRechargeSetupL.Get();
        // Define the JSON payload
        AgentReference := StrSubstNo('%1-%2-%3-%4-%5-%6', HotRechargeSetupL."HR Division ID", POSTransaction."Store No.", POSTransaction."POS Terminal No.", POSTransaction."Staff ID", POSTransaction."Receipt No.", gPOSSessionCU.GetValue('HotRechargeLineNo'));

        gPOSSessionCU.SetValue('HotRechargeAgentReference', AgentReference);

        Clear(JsonObject);
        JsonObject.Add('AgentReference', AgentReference);
        JsonObject.Add('ProductId', ProductID);
        JsonObject.Add('Target', Format(PhoneNumber));
        JsonObject.Add('Amount', Amount);

        Clear(JsonObject2);
        JsonObject2.Add('Name', 'MakeReservation');
        JsonObject2.Add('ParameterType', 'bool');
        JsonObject2.Add('Value', 'true');

        JsonArray.Add(JsonObject2);

        if gPOSSessionCU.GetValue('HotRechargeSendSMS') <> '' then begin
            Clear(JsonObject2);
            JsonObject2.Add('Name', 'SendReservationSMSToCustomer');
            JsonObject2.Add('ParameterType', 'bool');
            JsonObject2.Add('Value', gPOSSessionCU.GetValue('HotRechargeSendSMS'));
            JsonArray.Add(JsonObject2);
        end;

        if JsonArray.Count <> 0 then
            JsonObject.Add('RechargeOptions', JsonArray);

        JsonObject.WriteTo(JsonBody);
        PostHotRechargeRequest(POSTransaction, JsonBody, Error001, false, true);
    end;

    internal procedure PostHotRechargeRequest(pPOSTransaction: Record "LSC POS Transaction"; pJsonBody: Text; pError: Text; pComplete: Boolean; pSetReplicated: Boolean)
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
                FillHotRechargeEntryErrorRecord(pPOSTransaction, pJsonBody, ResponseContent, LogStatus::Success, URI, headerValueLogs);

                SetHotRechargeEntryValidated(pPOSTransaction, pSetReplicated);
                if pSetReplicated and pComplete then
                    SetHotRechargeEntryReplicated(pPOSTransaction, pSetReplicated);

                if not pSetReplicated then begin
                    VoidHotRechargeLine(pPOSTransaction);
                end;
                exit;
            end;
        FillHotRechargeEntryErrorRecord(pPOSTransaction, pJsonBody, Format(HttpResponseMessage.IsSuccessStatusCode), LogStatus::Failed, URI, headerValueLogs);
        POSTransaction_CU.ErrorBeep(pError);

        VoidHotRechargeLine(pPOSTransaction);
    end;

    internal procedure VoidHotRechargeLine(pPOSTransaction: Record "LSC POS Transaction")
    var
        POSTransLineL: Record "LSC POS Trans. Line";
    begin
        POSTransaction_CU.SetPOSState('SALES');
        POSTransaction_CU.CancelPressed(true, 0);

        POSTransLineL.Reset;
        POSTransLineL.SetRange("Receipt No.", pPOSTransaction."Receipt No.");
        POSTransLineL.SetRange("Entry Type", POSTransLineL."Entry Type"::Item);
        POSTransLineL.SetRange("Is Hot Recharge Product", true);
        POSTransLineL.SetRange("Entry Status", POSTransLineL."Entry Status"::" ");
        If POSTransLineL.FindFirst() then
            POSTransLineL.VoidLine();
    end;

    internal procedure SetHotRechargeEntryReplicated(pPOSTransaction: Record "LSC POS Transaction"; pReplicated: Boolean)
    var
        HotRechargeEntryL: Record "Hot Recharge Entry";
    begin
        if HotRechargeEntryL.Get(pPOSTransaction."Receipt No.") then begin
            HotRechargeEntryL.Replicated := pReplicated;
            HotRechargeEntryL.Modify();
        end;
    end;

    internal procedure SetHotRechargeEntryValidated(pPOSTransaction: Record "LSC POS Transaction"; pValidated: Boolean)
    var
        HotRechargeEntryL: Record "Hot Recharge Entry";
    begin
        if HotRechargeEntryL.Get(pPOSTransaction."Receipt No.") then begin
            HotRechargeEntryL.Validated := pValidated;
            HotRechargeEntryL.Modify();
        end;
    end;

    internal procedure FillHotRechargeEntryErrorRecord(pPOSTransaction: Record "LSC POS Transaction"; pPayload: Text; pResponse: Text; pLogStatus: Option Success,Failed; pURI: Text; pheader: Text)
    var
        HotRechargeEntryL: Record "Hot Recharge Entry";
        HotRechargeEntryLogsL: Record "Hot Recharge Entry Logs";
        OutStream: OutStream;
    begin
        if not HotRechargeEntryL.Get(pPOSTransaction."Receipt No.") then begin
            Clear(HotRechargeEntryL);
            HotRechargeEntryL.Init();
            HotRechargeEntryL.Validate("Entry No.", pPOSTransaction."Receipt No.");
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

    procedure GetTextAfterDollarSymbol(InputText: Text): Text
    var
        Position: Integer;
        Result: Text;
        SearchString: Text;
    begin
        SearchString := '$SI';

        Position := STRPOS(InputText, SearchString);
        if Position > 0 then
            Result := COPYSTR(InputText, Position + STRLEN(SearchString))
        else
            Result := '';

        exit(Result);
    end;
}*/