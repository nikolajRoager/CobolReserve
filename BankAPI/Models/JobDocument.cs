/*
*A document containing the important information for jobs on the Z/OS mainframe, returned by the REST API, as descriped at
*https://www.ibm.com/docs/en/zos/2.4.0?topic=zjri-json-document-specifications-zos-jobs-rest-interface-requests#JSONDocumentSpecifications__JobDocumentContents
*There is a lot more information in the JSON, but that is not important here
*/

using System.Text.Json.Serialization;

namespace BankAPI.Models;

public class JobDocument
{
    [JsonPropertyName("jobname")]
    public string JobName { get; set; } = null!;

    [JsonPropertyName("jobid")]
    public string JobId { get; set; } = null!;

    [JsonPropertyName("owner")]
    public string Owner { get; set; } = null!;

    [JsonPropertyName("status")]
    public string Status { get; set; } = null!;
}