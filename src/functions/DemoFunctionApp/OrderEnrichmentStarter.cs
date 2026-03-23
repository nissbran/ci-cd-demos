using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask.Client;
using Microsoft.Extensions.Logging;

namespace DemoFunctionApp;

/// <summary>
/// Receives an order from the orders-internal Service Bus topic and starts a
/// durable orchestration to enrich, audit, and publish the order.
/// </summary>
public class OrderEnrichmentStarter(ILogger<OrderEnrichmentStarter> logger)
{
    [Function(nameof(OrderEnrichmentStarter))]
    public async Task Run(
        [ServiceBusTrigger("orders-internal", "func-internal", Connection = "ServiceBusConnection")]
        string messageBody,
        [DurableClient] DurableTaskClient durableClient)
    {
        var instanceId = await durableClient.ScheduleNewOrchestrationInstanceAsync(
            nameof(OrderEnrichmentOrchestrator), messageBody);

        logger.LogInformation(
            "Started orchestration {InstanceId} for message ({Length} chars)",
            instanceId, messageBody.Length);
    }
}
