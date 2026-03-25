using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask.Client;
using Microsoft.Extensions.Logging;

namespace DemoFunctionApp;

/// <summary>
/// Receives an <see cref="InternalOrder"/> from the <c>orders-internal</c> Service Bus topic
/// and starts a durable orchestration to enrich, audit, and publish the order.
/// </summary>
public class OrderEnrichmentStarter(ILogger<OrderEnrichmentStarter> logger)
{
    [Function(nameof(OrderEnrichmentStarter))]
    public async Task Run(
        [ServiceBusTrigger("orders-internal", "func-internal", Connection = "OrdersServiceBus")]
        InternalOrder order,
        [DurableClient] DurableTaskClient durableClient)
    {
        if (order is null)
        {
            logger.LogError("OrderEnrichmentStarter: received null InternalOrder payload from Service Bus message");
            return;
        }

        if (string.IsNullOrWhiteSpace(order.OrderId)
            || order.Customer is null
            || order.LineItem is null)
        {
            logger.LogError(
                "OrderEnrichmentStarter: skipping malformed message. Required fields: orderId, customer, lineItem");
            return;
        }

        var instanceId = await durableClient.ScheduleNewOrchestrationInstanceAsync(
            nameof(OrderEnrichmentOrchestrator), order);

        logger.LogInformation(
            "Started orchestration {InstanceId} for order {OrderId}",
            instanceId, order.OrderId);
    }
}
