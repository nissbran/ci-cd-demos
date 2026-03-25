using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace DemoFunctionApp;

/// <summary>
/// Activity 3 — Serializes the <see cref="EnrichedOrder"/> and publishes it to the
/// <c>orders-enriched</c> Service Bus topic using the shared <see cref="ServiceBusClient"/> from DI.
/// The JSON payload matches the input contract of <c>InternalToExternal.liquid</c>.
/// </summary>
public class PublishOrderActivity(ServiceBusClient serviceBusClient, ILogger<PublishOrderActivity> logger)
{
    [Function(nameof(PublishOrderActivity))]
    public async Task Run([ActivityTrigger] EnrichedOrder enrichedOrder, TaskActivityContext context)
    {
        logger.LogInformation(
            "PublishOrderActivity: sending order {OrderId} to orders-enriched", enrichedOrder.OrderId);

        var json = JsonSerializer.Serialize(enrichedOrder);

        await using var sender = serviceBusClient.CreateSender("orders-enriched");
        await sender.SendMessageAsync(new ServiceBusMessage(json)
        {
            ContentType = "application/json",
            ApplicationProperties =
            {
                ["orchestrationInstanceId"] = context.InstanceId,
            },
        });

        logger.LogInformation(
            "PublishOrderActivity: order {OrderId} sent to orders-enriched", enrichedOrder.OrderId);
    }
}
