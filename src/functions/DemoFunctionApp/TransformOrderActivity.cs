using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.Extensions.Logging;

namespace DemoFunctionApp;

/// <summary>
/// Activity 1 — Enriches the internal-format order with processing metadata.
/// Accepts <see cref="InternalOrder"/> and returns an <see cref="EnrichedOrder"/>.
/// </summary>
public class TransformOrderActivity(ILogger<TransformOrderActivity> logger)
{
    [Function(nameof(TransformOrderActivity))]
    public EnrichedOrder Run([ActivityTrigger] InternalOrder order, TaskActivityContext context)
    {
        if (order is null
            || string.IsNullOrWhiteSpace(order.OrderId)
            || order.Customer is null
            || order.LineItem is null)
        {
            throw new ArgumentException(
                "TransformOrderActivity requires orderId, customer, and lineItem in the InternalOrder input.",
                nameof(order));
        }

        logger.LogInformation("TransformOrderActivity: enriching order {OrderId}", order.OrderId);

        var enriched = new EnrichedOrder(
            OrderId: order.OrderId,
            CreatedAt: order.CreatedAt,
            Customer: order.Customer,
            LineItem: order.LineItem,
            Status: "processing",
            ProcessingNotes: "Order validated and queued for fulfilment by DemoFunctionApp",
            ProcessedAt: DateTime.UtcNow.ToString("o"),
            OrchestrationInstanceId: context.InstanceId);

        logger.LogInformation("TransformOrderActivity: enriched order {OrderId}", enriched.OrderId);
        return enriched;
    }
}
