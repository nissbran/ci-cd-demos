using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.Extensions.Logging;
using System.Text.Json.Nodes;

namespace DemoFunctionApp;

/// <summary>
/// Durable orchestrator that coordinates the order enrichment pipeline:
///   1. TransformOrderActivity  — enriches the raw order JSON
///   2. AuditOrderActivity      — writes enriched order + metadata to SQL audit log
///   3. PublishOrderActivity    — forwards enriched order to the orders-enriched topic
/// </summary>
public class OrderEnrichmentOrchestrator
{
    [Function(nameof(OrderEnrichmentOrchestrator))]
    public async Task<string> Run([OrchestrationTrigger] TaskOrchestrationContext context)
    {
        var logger = context.CreateReplaySafeLogger<OrderEnrichmentOrchestrator>();
        var rawMessage = context.GetInput<string>()!;

        // Activity 1: transform / enrich the message
        logger.LogInformation("Calling TransformOrderActivity");
        var enriched = await context.CallActivityAsync<string>(
            nameof(TransformOrderActivity), rawMessage);

        // Extract orderId for the audit record (best-effort)
        var orderId = TryGetOrderId(enriched) ?? context.InstanceId;

        // Activity 2: persist enriched message + metadata to SQL audit log
        logger.LogInformation("Calling AuditOrderActivity for order {OrderId}", orderId);
        await context.CallActivityAsync(
            nameof(AuditOrderActivity),
            new AuditInput(orderId, context.InstanceId, enriched));

        // Activity 3: publish enriched message to orders-enriched topic
        logger.LogInformation("Calling PublishOrderActivity for order {OrderId}", orderId);
        await context.CallActivityAsync(nameof(PublishOrderActivity), enriched);

        return enriched;
    }

    private static string? TryGetOrderId(string json)
    {
        try { return JsonNode.Parse(json)?["orderId"]?.GetValue<string>(); }
        catch { return null; }
    }
}
