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
}
