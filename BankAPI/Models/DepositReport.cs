/*
Report on what happened when we tried to deposit or withdraw an ammount in our currency
*/


using System.Text.Json.Serialization;

namespace BankAPI.Models;


public class DepositReport
{
    [JsonPropertyName("Currency")]
    public double Currency { get; set; }

    [JsonPropertyName("TransferFee")]
    public string TransferFee { get; set; } = null!;

    [JsonPropertyName("ExchangeFee")]
    public string ExchangeFee { get; set; } = null!;

    [JsonPropertyName("ToAccount")]
    public string ToAccount { get; set; } = null!;

    [JsonPropertyName("Balance")]
    public double Balance { get; set; }
}