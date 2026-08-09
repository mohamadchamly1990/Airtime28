controladdin JsonBeautifier
{
    RequestedHeight = 1;
    MinimumHeight = 1;
    MaximumHeight = 1;
    RequestedWidth = 1;
    MinimumWidth = 1;
    MaximumWidth = 1;
    Scripts = '.\src\Js\JsonBeautifier.js';

    event ReceiveBeautifiedJson(BeautifiedJson: Text);

    procedure Beautify(JsonData: JsonObject);
}