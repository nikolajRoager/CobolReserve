/*
Report on what happened when we tried to move money around
*/

using System.Text.Json.Serialization;

namespace BankAPI.Models;


public class TransferReport
{
    
    //The account this reference belongs to
    [JsonPropertyName("Key")]
    public string Key { get; set; } = null!;
    
    //The account this reference belongs to
    [JsonPropertyName("Account")]
    public string Account { get; set; } = null!;

    //The other account involved
    [JsonPropertyName("Timestamp")]
    public string Timestamp { get; set; } = null!;
    
    [JsonPropertyName("OtherAccount")]
    public string OtherAccount { get; set; } = null!;
    
    //The type of transfer
    [JsonPropertyName("Type")]
    public string Type { get; set; } = null!;

    //Currency the transfer is denoted in
    [JsonPropertyName("OwnCurrency")]
    public string OwnCurrency { get; set; } = null!;

    //Nominal amount of the transfer, in transfer currency
    [JsonPropertyName("AmountNominal")]
    public double AmountNominal { get; set; }
    
    //My own currency
    [JsonPropertyName("TransactionCurrency")]
    public string TransactionCurrency { get; set; } = null!;
    
    //Transfer fee deducted before money was added to my account
    [JsonPropertyName("AmountTransfered")]
    public double AmountTransfered { get; set; }

    //Transfer fee deducted before money was added to my account
    [JsonPropertyName("TransactionFee")]
    public double TransactionFee { get; set; }

    //Exchange fee deducted before money was added to my account
    [JsonPropertyName("ExchangeFee")]
        public double ExchangeFee { get; set; }
}
