/*
Report on what happened when we tried to move money around
*/

using System.Text.Json.Serialization;

namespace BankAPI.Models;


public class TransferReport
{
    
    //The account this reference belongs to
    [JsonPropertyName("Account")]
    public string Account { get; set; } = null!;
    
    //The other account involved
    [JsonPropertyName("Other")]
    public string Other { get; set; } = null!;
    
    //The type of transfer
    [JsonPropertyName("Type")]
    public string Type { get; set; } = null!;

    //Currency the transfer is denoted in
    [JsonPropertyName("TrfCurrency")]
    public string Currency { get; set; } = null!;

    //Nominal amount of the transfer, in transfer currency
    [JsonPropertyName("AmountNominal")]
    public double AmountNominal { get; set; }
    
    //My own currency
    [JsonPropertyName("ActCurrency")]
    public string Currency { get; set; } = null!;
    
    //Transfer fee deducted before money was added to my account
    [JsonPropertyName("AccountAmount")]
    public double Amount { get; set; }

    //Transfer fee deducted before money was added to my account
    [JsonPropertyName("TransferFee")]
    public double TransferFee { get; set; }

    //Exchange fee deducted before money was added to my account
    [JsonPropertyName("ExchangeFee")]
    public double TransferFee { get; set; }
}