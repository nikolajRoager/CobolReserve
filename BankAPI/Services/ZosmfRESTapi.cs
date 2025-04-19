using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Text.Json;
using BankAPI.Models;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json.Serialization;

namespace BankAPI.Services.ZosmfRESTapi
{
    ///<summary>
    /// An interface for the class which interacts with Z/OS Mainframe by sending http requests, all interactions with the REST API lives here, and are not exposed outside
    ///</summary>
    public interface IZosmfRESTapi
    {
        public Task<IEnumerable<User>> GetUsers();
        
        public Task AddUser (User user);

        public Task<TransferReport> depositWithdraw(string user, double amount, string currency);
    }

    ///<summary>
    /// Class which interacts with Z/OS Mainframe by sending http requests, all interactions with the REST API lives here, and are not exposed outside
    ///</summary>
    public class ZosmfRESTapi : IZosmfRESTapi
    {
        /// <summary>
        /// Try launching zowe cli to see if the address is right, return true if it works
        /// </summary>
        /// <returns></returns>
        public bool zoweCliWorks()
        {
            //Just inquire the version
            ProcessStartInfo processStartInfo = new ProcessStartInfo
            {
                    FileName =  zoweCliExe,
                    Arguments= $"-V",
                    RedirectStandardOutput=true,
                    RedirectStandardError=true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
            };
            //Launch the process
            try
            {
                using (Process process = new Process())
                {
                    process.StartInfo=processStartInfo;
                    
                    //Launch the process
                    process.Start();

                    string output = process.StandardOutput.ReadToEnd();
                    string error = process.StandardError.ReadToEnd();

                    //Async is not available
                    process.WaitForExit();

                    //This will only happen is the launching of the command fails
                    if (!string.IsNullOrEmpty(error))
                    {
                        return false;
                    }
                    return true;
                }
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// A bodge solution to not being allowed to post jobs with http: simply launch zowe cli in the commandline
        /// The function either returns the ID of the job when submitted, or throws an exception if it did not work
        /// Returns direct link to job, anddirect link to files
        /// </summary>
        private (string,string) SubmitZoweJob(string jclJob)
        {
            ProcessStartInfo processStartInfo = new ProcessStartInfo
            {
                    FileName =  zoweCliExe,
                    Arguments= $"zos-jobs submit ds \"{jclJob}\" --rfj",
                    RedirectStandardOutput=true,
                    RedirectStandardError=true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
            };

            //Launch the process
            using (Process process = new Process())
            {
                process.StartInfo=processStartInfo;
                
                //Launch the process
                process.Start();

                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();

                //Async is not available
                process.WaitForExit();

                //This will only happen is the launching of the command fails
                if (!string.IsNullOrEmpty(error))
                {
                    Console.WriteLine(error);
                    throw new Exception($"Error launching Z/OS job with zowe CLI : {error}");
                }


                var JsonOutput = System.Text.Json.JsonDocument.Parse(output);
                var success = JsonOutput.RootElement.GetProperty("success").GetBoolean();
                if (success)
                {
                    var jobUrl =JsonOutput.RootElement.GetProperty("data").GetProperty("url").GetString();
                    var jobFilesUrl =JsonOutput.RootElement.GetProperty("data").GetProperty("files-url").GetString();
                    if (jobUrl==null || jobFilesUrl==null)
                        throw new Exception($"Job was launched but zowe did not return an ID");
                    else
                    {
                        return (jobUrl,jobFilesUrl);
                    }
                }
                else
                {
                    throw new Exception($"Job could not be submitted, zowe cli returned error {JsonOutput.RootElement.GetProperty("message").GetString()}");
                }
            }
        }


        /// <summary>
        /// A bodge solution to post a job with a custom argument, 
        /// The function either returns the ID of the job when submitted, or throws an exception if it did not work
        /// Returns direct link to job, and direct link to files
        /// I don't have a REST version as I can't debug/test it
        /// </summary>
        private (string,string) SubmitZoweJobArg(string thisJcl)
        {
            //Create a temporary file with the raw JCL, this is a unique name, regardless of how many threads have been launched
            string tempJCLFile= Path.GetTempFileName()+".jcl";
            Console.WriteLine("INFO: created "+tempJCLFile);
            Console.WriteLine(thisJcl);
            try
            {
                File.WriteAllText(tempJCLFile,thisJcl);
            
                ProcessStartInfo processStartInfo = new ProcessStartInfo
                {
                        FileName =  zoweCliExe,
                        Arguments= $"zos-jobs submit lf \"{tempJCLFile}\" --rfj",
                        RedirectStandardOutput=true,
                        RedirectStandardError=true,
                        UseShellExecute = false,
                        CreateNoWindow = true,
                };

                Console.WriteLine($"zos-jobs submit lf {tempJCLFile} --rfj");

                //Launch the process
                using (Process process = new Process())
                {
                    process.StartInfo=processStartInfo;
                    
                    //Launch the process
                    process.Start();

                    string output = process.StandardOutput.ReadToEnd();
                    string error = process.StandardError.ReadToEnd();

                    //Async is not available
                    process.WaitForExit();

                    //This will only happen is the launching of the command fails
                    if (!string.IsNullOrEmpty(error))
                    {
                        throw new Exception($"Error launching Z/OS job with zowe CLI : {error}");
                    }


                    var JsonOutput = System.Text.Json.JsonDocument.Parse(output);
                    var success = JsonOutput.RootElement.GetProperty("success").GetBoolean();
                    if (success)
                    {
                        var jobUrl =JsonOutput.RootElement.GetProperty("data").GetProperty("url").GetString();
                        var jobFilesUrl =JsonOutput.RootElement.GetProperty("data").GetProperty("files-url").GetString();
                        if (jobUrl==null || jobFilesUrl==null)
                            throw new Exception($"Job was launched but zowe did not return an ID");
                        else
                        {
                            return (jobUrl,jobFilesUrl);
                        }
                    }
                    else
                    {
                        Console.WriteLine(JsonOutput.RootElement.GetProperty("message").GetString());
                        throw new Exception($"Job could not be submitted, zowe cli returned error {JsonOutput.RootElement.GetProperty("message").GetString()}");
                    }
                }
            }
            finally
            {
                Console.WriteLine("INFO: delete "+tempJCLFile);
                //Remove the temp file
                if (File.Exists(tempJCLFile))
                    File.Delete(tempJCLFile);
            }
        }


        /// <summary>
        /// Poll the status of a job with a particular url
        /// </summary>
        /// <param name="jobUrl"></param>
        /// <returns>one of ACTIVE, OUTPUT, COMPLETE, ABENDED, CANCELLED, HOLD, SUSPENDED, NOTRUN, WAITING</returns>
        private async Task<string> getJobStatus(string jobUrl)
        {
            Console.WriteLine($"{jobUrl}");
            var response = await client.GetAsync($"{jobUrl}");
            response.EnsureSuccessStatusCode();
            var content = await response.Content.ReadAsStringAsync();

            
            var JsonOutput = System.Text.Json.JsonDocument.Parse(content);

            string? status = JsonOutput.RootElement.GetProperty("status").GetString();

            //This is bad
            if (status==null)
                return "ABENDED";
            return status;
        }

        /// <summary>
        /// Get sysout from a particular job
        /// </summary>
        /// <param name="jobFilesUrl"></param>
        /// <returns>string containing the output data</returns>
        private async Task<string> getSysout(string jobFilesUrl)
        {
            Console.WriteLine($"get output from {jobFilesUrl}");
            
            //Get all meta-data, including the url, to all files produced by the process
            var response = await client.GetAsync($"{jobFilesUrl}");
            response.EnsureSuccessStatusCode();
            var content = await response.Content.ReadAsStringAsync();

            //Filter the list and look for sysout, (unfortunately there is no way to only query sysout)

            var JsonOutput = System.Text.Json.JsonDocument.Parse(content);
            if (JsonOutput!=null)
                foreach (var Element in JsonOutput.RootElement.EnumerateArray())
                {
                    var ddname     = Element.GetProperty("ddname").GetString();
                    var recordsUrl = Element.GetProperty("records-url").GetString();
                    if (ddname=="SYSOUT" && recordsUrl!=null)
                    {
                        //Ok, now get and return data
                        Console.WriteLine($"Getting sysout recordsUrl {recordsUrl}");
                        
                        var data_records= await client.GetAsync($"{recordsUrl}");
                        data_records.EnsureSuccessStatusCode();
                        var data = await data_records.Content.ReadAsStringAsync();
                        return data;

                    }
                }
            
            throw new Exception("Job did not produce sysout");
        }

        private HttpClientHandler handler;
        private HttpClient client;
        private readonly string zosUsername;
        private readonly string zosmfUrl;

        private readonly string getUsersJCL;

        /// <summary>
        /// Path to executable zowe commandline Executable
        /// </summary>
        private readonly string zoweCliExe;

        private readonly string AddUserRawJCL;

        private readonly string DepositRawJCL;

        public ZosmfRESTapi(string host, string port, string zosUsername, string zosPassword)
        {
            

            this.zosUsername=zosUsername;
        
            handler = new HttpClientHandler();
            //only for testing, disable cerfification
            handler.ServerCertificateCustomValidationCallback = (message, cert, chain, errors) => true;

            zosmfUrl = "restjobs/jobs";
            client = new HttpClient(handler);
            
            client.BaseAddress =new Uri($"https://{host}:{port}/zosmf/");

            Console.WriteLine($"using https://{host}:{port}/zosmf/");

            //Use the username and password
            string authInfo = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{zosUsername}:{zosPassword}"));
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authInfo);
            
            getUsersJCL=$"{zosUsername}.BANK.JCL(GETUSRS)";
            
            
            zoweCliExe="";//If will be set below, but the compiler doesn't know that and keeps giving me warnings
            //First check if Zowe is in PATH
            ProcessStartInfo which = new ProcessStartInfo
            {
                FileName = OperatingSystem.IsWindows() ? "where" : "which",
                Arguments = "zowe",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };
            Process process = new Process {StartInfo = which};
            process.Start();
            string? path = process.StandardOutput.ReadLine();
            process.WaitForExit();

            bool zoweNotFound;
            if (!string.IsNullOrEmpty(path))
            {
                //Found it, just call it and see if it works
                zoweCliExe=path;
                zoweNotFound=!zoweCliWorks();
            }
            else
                zoweNotFound=true;
            if (zoweNotFound)
            {
                if (System.Runtime.InteropServices.RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                {
                    //This is where it would go if it was installed through npm
                    zoweCliExe=  $"C:\\Users\\{Environment.UserName}\\AppData\\Roaming\\npm\\zowe.cmd";
                }
                else//Linux or similar
                {
                    //get npm bin
                    ProcessStartInfo npm = new ProcessStartInfo
                    {
                        FileName = "npm",
                        Arguments = "-g",
                        RedirectStandardOutput = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    };
                    Process npm_process = new Process {StartInfo = npm};
                    npm_process.Start();
                    string? bin_path = process.StandardOutput.ReadLine();
                    process.WaitForExit();

                    //oh well just try this
                    if (string.IsNullOrEmpty(bin_path))
                        bin_path = "/usr";

                    zoweCliExe=Path.Combine(Path.Combine(bin_path.Trim(), "bin"),"zowe");
                }
            }

            AddUserRawJCL=
                "//ADDUSER JOB (ACCT),'ADDUSER',CLASS=A,MSGCLASS=A,NOTIFY=&SYSUID\n"+
                "//STEP1 EXEC PGM=ADDUSER,PARM='REPLACE'\n"+
                "//*Link VSAM file\n"+
                "//ACCOUNTS DD DSN=&SYSUID..BANK.USERS.ACCOUNTS,DISP=SHR\n"+
                "//EXCHANGE DD DSN=&SYSUID..BANK.EXCHANGE,DISP=SHR\n"+
                "//*Link libraries\n"+
                "//STEPLIB DD DSN=&SYSUID..BANK.LOAD,DISP=SHR\n"+
                "//SYSOUT    DD SYSOUT=*,OUTLIM=15000\n"+
                "//CEEDUMP   DD DUMMY\n"+
                "//SYSUDUMP  DD DUMMY\n";

            DepositRawJCL=
                "//DEPWITH JOB (ACCT),'DEPWITH',CLASS=A,MSGCLASS=A,NOTIFY=&SYSUID\n"+
                "//STEP1 EXEC PGM=DEPWIT,PARM='REPLACE'\n"+
                "//*Link VSAM file\n"+
                "//ACCOUNTS DD DSN=&SYSUID..BANK.USERS.ACCOUNTS,DISP=SHR\n"+
                "//TRANSFER DD DSN=&SYSUID..BANK.USERS.TRANSFER,DISP=SHR\n"+
                "//EXCHANGE DD DSN=&SYSUID..BANK.EXCHANGE,DISP=SHR\n"+
                "//*Link libraries\n"+
                "//STEPLIB DD DSN=&SYSUID..BANK.LOAD,DISP=SHR\n"+
                "//SYSOUT    DD SYSOUT=*,OUTLIM=15000\n"+
                "//CEEDUMP   DD DUMMY\n"+
                "//SYSUDUMP  DD DUMMY\n";


            if (!zoweCliWorks())
                throw new Exception($"Zowe CLI could not be found at {zoweCliExe}, install it through npm, and add it to your path");
            Console.WriteLine($"INFO: Found Zowe CLI at {zoweCliExe}");

        }

        class ReturnedUser{
            [JsonPropertyName("Success")] public int Success {get;set;}
            [JsonPropertyName("Error")] public string Error {get;set;} =null!;
            [JsonPropertyName("Users")] public List<User>? Users {get;set;}
        }

        public async Task<IEnumerable<User>> GetUsers()
        {
            //Post the job using the rest api, this is the better version but is not permitted by Z-Explore
            //string response = await SubmitJob(getShipsJCL);
            //Post the job using a ZOWE hack (if the mainframe doesn't support http post)
            (string jobUrl,string jobFilesUrl) = SubmitZoweJob(getUsersJCL);
            string status="ACTIVE";
            //ONLY poll up to 15 times, spaced out over 1 minute
            for (int i = 0; i < 15; ++i)
            {
                //Wait 2 seconds
                await Task.Delay(4000);
                //Check status
                status =await getJobStatus(jobUrl);

                //Some documentation insist that this is also a valid exit code
                if (status=="ABENDED")
                {
                    //Should really not happen in normal usage
                    throw new Exception("Job exited with mainframe-side COBOL error (status: ABEND)");
                }
                else if (status!="ACTIVE" && status!="IDLE" && status!="WAITING")
                {
                    break;
                }
            }

            if (status!="OUTPUT")
            {
                throw new Exception("Job stopped or timed out, with status other than output, status: "+status);
            }
            //The job is done, now get the result
            string shiplist = await getSysout(jobFilesUrl);
            
            Console.WriteLine(shiplist);

            var jobList = JsonSerializer.Deserialize<ReturnedUser>(shiplist, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
            if (jobList==null)
                throw new Exception($"Error getting user list, no output returned");
            if (jobList.Success==0 || jobList.Users==null)
            {
                throw new Exception($"Error getting user list {jobList.Error}");
            }

            return jobList.Users;
        }

        public async Task AddUser (User user)
        {
            //Post the job using a ZOWE hack (if the mainframe doesn't support http post)
            //Put the balance in the expected format
            if (user.Currency.Length!=3)
                throw new Exception("Currency code must be 3 chars");
            else if (user.Name.Length>9)
                throw new Exception("User name too long, at most 9 chars");
            //No need to explicitly pad out the length, COBOL can handle too short arguments
            (string jobUrl,string jobFilesUrl) = SubmitZoweJobArg(AddUserRawJCL.Replace("REPLACE",$"{user.Balance.ToString("000000000000.0000")}{user.Currency}{user.Name}"));
            string status="ACTIVE";
            //ONLY poll up to 15 times, spaced out over 1 minute
            for (int i = 0; i < 15; ++i)
            {
                //Wait 2 seconds
                await Task.Delay(4000);
                //Check status
                status =await getJobStatus(jobUrl);

                //Some documentation insist that this is also a valid exit code
                if (status=="ABENDED")
                {
                    //Should really not happen in normal usage
                    throw new Exception("Job exited with mainframe-side COBOL error (status: ABEND)");
                }
                else if (status!="ACTIVE" && status!="IDLE" && status!="WAITING")
                {
                    break;
                }
            }

            if (status!="OUTPUT")
            {
                throw new Exception("Job stopped or timed out, with status other than output, status: "+status);
            }
            //The job is done, now get the result
            string output= await getSysout(jobFilesUrl);
            
            Console.WriteLine(output);
        }

        public Task<TransferReport> depositWithdraw(string user, double amount, string currency)
        {
            //Post the job using a ZOWE hack (if the mainframe doesn't support http post)
            //Put the balance in the expected format
            if (currency.Length!=3)
                throw new Exception("Currency code must be 3 chars");
            else if (user.Length>9)
                throw new Exception("User name too long, at most 9 chars");
            
            //No need to explicitly pad out the length, COBOL can handle too short arguments
            (string jobUrl,string jobFilesUrl) = SubmitZoweJobArg(DepositRawJCL.Replace("REPLACE",$"{Amount.ToString("000000000000.0000")}{Currency}{user}"));
            string status="ACTIVE";
            //ONLY poll up to 15 times, spaced out over 1 minute
            for (int i = 0; i < 15; ++i)
            {
                //Wait 2 seconds
                await Task.Delay(4000);
                //Check status
                status =await getJobStatus(jobUrl);

                //Some documentation insist that this is also a valid exit code
                if (status=="ABENDED")
                {
                    //Should really not happen in normal usage
                    throw new Exception("Job exited with mainframe-side COBOL error (status: ABEND)");
                }
                else if (status!="ACTIVE" && status!="IDLE" && status!="WAITING")
                {
                    break;
                }
            }

            if (status!="OUTPUT")
            {
                throw new Exception("Job stopped or timed out, with status other than output, status: "+status);
            }
            //The job is done, now get the result
            string output= await getSysout(jobFilesUrl);
            
            Console.WriteLine(output);
        }
    }
}