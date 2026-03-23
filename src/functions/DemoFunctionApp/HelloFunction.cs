using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

namespace DemoFunctionApp;

public class HelloFunction
{
    private readonly ILogger<HelloFunction> _logger;

    public HelloFunction(ILogger<HelloFunction> logger)
    {
        _logger = logger;
    }

    [Function("Hello")]
    public HttpResponseData Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "hello")] HttpRequestData req)
    {
        _logger.LogInformation("Hello function triggered.");

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json");
        response.WriteString("{\"message\": \"Hello from DemoFunctionApp!\"}");
        return response;
    }
}
