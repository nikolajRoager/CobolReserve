using BankAPI.Models;
using BankAPI.Services.ZosmfRESTapi;
using Microsoft.AspNetCore.Mvc;

namespace BankAPI.Controllers;

[ApiController]
[Route("[controller]")]
public class BankController : ControllerBase
{
    private readonly IZosmfRESTapi zosmfApi;

    private readonly ILogger<BankController> logger;

    public BankController(ILogger<BankController> _logger,IZosmfRESTapi _zosmfApi)
    {
        zosmfApi = _zosmfApi;
        logger = _logger;
    }

    [HttpGet("GetUsers")]
    public async Task<ActionResult<IEnumerable<User>>> GetUsers()
    {
        try
        {
            var list = await zosmfApi.GetUsers();
            return Ok(list);
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }

    [HttpPost("AddUser")]
    public async Task<ActionResult> AddUser(User user)
    {
        try
        {
            await zosmfApi.AddUser(user);
            return Ok();
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }

    ///Deposit or withdraw an amount from this or to this account
    ///Returns a copy of the transfer report for this operation
    ///Returns error in case of overdraft or invalid user
    [HttpPost("deposit-withdraw")]
    public async Task<ActionResult<TransferReport>> AddUser(string user, double amount, string currency)
    {
        try
        {
            //Realistically, this is where we should check username and password
            //This isn't done in this example... but it should be here
            var Out = await zosmfApi.depositWithdraw(user, amount, currency);
            return Ok(Out);
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }

    ///View all historical transfers involving this user, and only this user
    ///Returns a (maybe empty) list
    [HttpGet("getTransfers")]
    public async Task<ActionResult<IEnumerable<TransferReport>>> AddUser(string user)
    {
        try
        {
            //Realistically, this is where we should check username and password
            //This isn't done in this example... but it should be here
            var Out = await zosmfApi.getTransfers(user);
            return Ok(Out);
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }

    [HttpPost("Transfer")]
    public async Task<ActionResult<IEnumerable<TransferReport>>> AddUser(string From, string To, double Amount, string Currency)
    {
        try
        {
            //Realistically, this is where we should check username and password
            //This isn't done in this example... but it should be here
            var Out = await zosmfApi.transfer(From, To, Amount, Currency);
            return Ok(Out);
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }
}
