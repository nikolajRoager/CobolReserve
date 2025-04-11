/*
*A user of the bank, with all required information
*/

using System.Text.Json.Serialization;

namespace BankAPI.Models;

public class User
{

/// <summary>
/// 20 char name of user, must be unique
/// </summary>
    [JsonPropertyName("Name")]
    public string Name { get; set; } = null!;

/// <summary>
/// Balance, either positive or negative
/// </summary>
    [JsonPropertyName("Balance")]
    public double Balance { get; set; }

    /// <summary>
    /// Currency, as 3 char key
    /// </summary>
    [JsonPropertyName("Currency")]
    public string Currency { get; set; } = null!;
}