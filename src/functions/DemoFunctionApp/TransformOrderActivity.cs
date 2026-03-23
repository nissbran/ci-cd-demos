using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace DemoFunctionApp;

/// <summary>
/// Activity 1 — Enriches the raw internal-format order with processing metadata.
/// </summary>
public class TransformOrderActivity(ILogger<TransformOrderActivity> logger)
{
    [Function(nameof(TransformOrderActivity))]
    public string Run([ActivityTrigger] string messageBody, TaskActivityContext context)
    {
        logger.LogInformation("TransformOrderActivity: enriching message");

        var order = JsonNode.Parse(messageBody)!.AsObject();
        var orderId = order["orderId"]?.GetValue<string>() ?? "unknown";

        order["status"] = "processing";
        order["processingNotes"] = "Order validated and queued for fulfilment by DemoFunctionApp";
        order["processedAt"] = DateTime.UtcNow.ToString("o");
        order["orchestrationInstanceId"] = context.InstanceId;

        var enriched = order.ToJsonString(new JsonSerializerOptions { WriteIndented = false });

        logger.LogInformation("TransformOrderActivity: enriched order {OrderId}", orderId);
        return enriched;
    }
}
