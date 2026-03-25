using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Text.Json;

namespace DemoFunctionApp;

/// <summary>
/// HTTP-triggered function that accepts an <see cref="ExternalOrder"/>, applies the same
/// transformation as <c>ExternalToInternal.liquid</c>, and publishes the resulting
/// <see cref="InternalOrder"/> to the <c>orders-internal</c> Service Bus topic.
///
/// This provides a direct submission path that mirrors the Logic App
/// <c>ReceiveOrderWorkflow</c> — useful for testing, debugging, and direct API access.
/// </summary>
public class SubmitOrderFunction(
    ServiceBusClient serviceBusClient,
    ILogger<SubmitOrderFunction> logger)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    [Function("SubmitOrder")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "orders")] HttpRequestData req)
    {
        ExternalOrder? externalOrder;
        try
        {
            externalOrder = await JsonSerializer.DeserializeAsync<ExternalOrder>(
                req.Body, JsonOptions);
        }
        catch (JsonException ex)
        {
            logger.LogWarning("SubmitOrderFunction: invalid request body — {Message}", ex.Message);
            var badRequest = req.CreateResponse(HttpStatusCode.BadRequest);
            await badRequest.WriteAsJsonAsync(new { error = "Invalid JSON in request body." });
            return badRequest;
        }

        if (externalOrder is null
            || string.IsNullOrWhiteSpace(externalOrder.CustomerName)
            || string.IsNullOrWhiteSpace(externalOrder.ProductCode)
            || string.IsNullOrWhiteSpace(externalOrder.OrderDate)
            || externalOrder.Quantity <= 0
            || externalOrder.UnitPrice <= 0)
        {
            var badRequest = req.CreateResponse(HttpStatusCode.BadRequest);
            await badRequest.WriteAsJsonAsync(new
            {
                error = "Missing or invalid required fields: CustomerName, ProductCode, OrderDate, Quantity (>0), UnitPrice (>0)."
            });
            return badRequest;
        }

        var internalOrder = ToInternalOrder(externalOrder);
        var json = JsonSerializer.Serialize(internalOrder);

        await using var sender = serviceBusClient.CreateSender("orders-internal");
        var message = new ServiceBusMessage(json)
        {
            ContentType = "application/json",
            ApplicationProperties = { ["source"] = "SubmitOrderFunction" },
        };
        await sender.SendMessageAsync(message);

        logger.LogInformation(
            "SubmitOrderFunction: order {OrderId} published to orders-internal", internalOrder.OrderId);

        var accepted = req.CreateResponse(HttpStatusCode.Accepted);
        await accepted.WriteAsJsonAsync(new { orderId = internalOrder.OrderId });
        return accepted;
    }

    /// <summary>
    /// Converts an <see cref="ExternalOrder"/> to an <see cref="InternalOrder"/> using the
    /// same rules as <c>ExternalToInternal.liquid</c>:
    /// <list type="bullet">
    ///   <item><description><c>orderId</c> = "ORD-{PRODUCTCODE}-{OrderDateWithoutDashes}"</description></item>
    ///   <item><description><c>createdAt</c> = "{OrderDate}T00:00:00Z"</description></item>
    ///   <item><description><c>totalPrice</c> = Quantity × UnitPrice (rounded to 2 dp)</description></item>
    ///   <item><description><c>status</c> = "received"</description></item>
    /// </list>
    /// </summary>
    private static InternalOrder ToInternalOrder(ExternalOrder external)
    {
        var cleanCode = external.ProductCode.ToUpperInvariant().Replace(' ', '-');
        var cleanDate = external.OrderDate.Replace("-", "");
        var orderId = $"ORD-{cleanCode}-{cleanDate}";
        var totalPrice = Math.Round((decimal)external.Quantity * external.UnitPrice, 2);

        return new InternalOrder(
            OrderId: orderId,
            CreatedAt: $"{external.OrderDate}T00:00:00Z",
            Customer: new OrderCustomer(external.CustomerName, external.CustomerEmail),
            LineItem: new OrderLineItem(external.ProductCode, external.Quantity, external.UnitPrice, totalPrice),
            Status: "received");
    }
}
