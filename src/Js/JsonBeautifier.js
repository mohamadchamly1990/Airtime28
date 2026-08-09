function Beautify(jsonData) {
    const obj = JSON.parse(jsonData['data']);
    const BeautifiedJson = JSON.stringify(obj, null, 4);
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ReceiveBeautifiedJson', [BeautifiedJson]);
}