using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.Extensions.Logging;

namespace DemoFunctionApp;

/// <summary>
/// Activity 3 — Publishes the enriched order to the orders-enriched Service Bus topic
/// using the shared <see cref="ServiceBusClient"/> registered in DI.
/// </summary>
public class PublishOrderActivity(ServiceBusClient serviceBusClient, ILogger<PublishOrderActivity> logger)
{
    [Function(nameof(PublishOrderActivity))]
    public async Task Run([ActivityTrigger] string enrichedMessage, TaskActivityContext context)
    {
        logger.LogInformation("PublishOrderActivity: sending message to orders-enriched");

        await using var sender = serviceBusClient.CreateSender("orders-enriched");
        await sender.SendMessageAsync(new ServiceBusMessage(enrichedMessage)
        {
            ContentType = "application/json",
            ApplicationProperties =
            {
                ["orchestrationInstanceId"] = context.InstanceId,
            },
        });

        logger.LogInformation("PublishOrderActivity: message sent to orders-enriched");
    }
}
