using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.Extensions.Logging;

namespace DemoFunctionApp;

/// <summary>
/// Durable orchestrator that coordinates the order enrichment pipeline:
///   1. TransformOrderActivity  — enriches the <see cref="InternalOrder"/> into an <see cref="EnrichedOrder"/>
///   2. AuditOrderActivity      — writes enriched order + metadata to the SQL audit log
///   3. PublishOrderActivity    — forwards the enriched order to the orders-enriched topic
/// </summary>
public class OrderEnrichmentOrchestrator
{
    [Function(nameof(OrderEnrichmentOrchestrator))]
    public async Task<EnrichedOrder> Run([OrchestrationTrigger] TaskOrchestrationContext context)
    {
        var logger = context.CreateReplaySafeLogger<OrderEnrichmentOrchestrator>();
        var order = context.GetInput<InternalOrder>();

        if (order is null
            || string.IsNullOrWhiteSpace(order.OrderId)
            || order.Customer is null
            || order.LineItem is null)
        {
            throw new InvalidOperationException(
                "OrderEnrichmentOrchestrator requires orderId, customer, and lineItem in the InternalOrder input.");
        }

        // Activity 1: transform / enrich the order
        logger.LogInformation("Calling TransformOrderActivity for order {OrderId}", order.OrderId);
        var enriched = await context.CallActivityAsync<EnrichedOrder>(
            nameof(TransformOrderActivity), order);

        // Activity 2: persist enriched order + metadata to SQL audit log
        logger.LogInformation("Calling AuditOrderActivity for order {OrderId}", enriched.OrderId);
        await context.CallActivityAsync(
            nameof(AuditOrderActivity),
            new AuditInput(enriched.OrderId, context.InstanceId, enriched));

        // Activity 3: publish enriched order to orders-enriched topic
        logger.LogInformation("Calling PublishOrderActivity for order {OrderId}", enriched.OrderId);
        await context.CallActivityAsync(nameof(PublishOrderActivity), enriched);

        return enriched;
    }
}
