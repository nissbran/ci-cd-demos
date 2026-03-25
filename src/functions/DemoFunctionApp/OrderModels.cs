using System.Text.Json.Serialization;

namespace DemoFunctionApp;

/// <summary>
/// External inbound order — submitted by external systems to Logic App <c>ReceiveOrderWorkflow</c>
/// or directly via <see cref="SubmitOrderFunction"/>.
/// Matches the input contract of <c>ExternalToInternal.liquid</c>.
/// </summary>
public record ExternalOrder(
    [property: JsonPropertyName("CustomerName")] string CustomerName,
    [property: JsonPropertyName("CustomerEmail")] string CustomerEmail,
    [property: JsonPropertyName("ProductCode")] string ProductCode,
    [property: JsonPropertyName("Quantity")] int Quantity,
    [property: JsonPropertyName("UnitPrice")] decimal UnitPrice,
    [property: JsonPropertyName("OrderDate")] string OrderDate);

/// <summary>Customer details within an <see cref="InternalOrder"/>.</summary>
public record OrderCustomer(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("email")] string Email);

/// <summary>Line-item details within an <see cref="InternalOrder"/>.</summary>
public record OrderLineItem(
    [property: JsonPropertyName("productCode")] string ProductCode,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("unitPrice")] decimal UnitPrice,
    [property: JsonPropertyName("totalPrice")] decimal TotalPrice);

/// <summary>
/// Internal order format.
/// <list type="bullet">
///   <item><description>
///     <b>Produced by</b>: Logic App <c>ExternalToInternal.liquid</c> (via <c>ReceiveOrderWorkflow</c>)
///     or <see cref="SubmitOrderFunction"/> (direct path).
///   </description></item>
///   <item><description>
///     <b>Consumed by</b>: <see cref="OrderEnrichmentStarter"/> via the <c>orders-internal</c> Service Bus topic.
///   </description></item>
/// </list>
/// </summary>
public record InternalOrder(
    [property: JsonPropertyName("orderId")] string OrderId,
    [property: JsonPropertyName("createdAt")] string CreatedAt,
    [property: JsonPropertyName("customer")] OrderCustomer Customer,
    [property: JsonPropertyName("lineItem")] OrderLineItem LineItem,
    [property: JsonPropertyName("status")] string Status);

/// <summary>
/// Enriched order — extends <see cref="InternalOrder"/> with processing metadata.
/// <list type="bullet">
///   <item><description>
///     <b>Produced by</b>: <see cref="TransformOrderActivity"/>.
///   </description></item>
///   <item><description>
///     <b>Consumed by</b>: Logic App <c>InternalToExternal.liquid</c> (via <c>PublishOrderWorkflow</c>)
///     over the <c>orders-enriched</c> Service Bus topic.
///   </description></item>
/// </list>
/// </summary>
public record EnrichedOrder(
    [property: JsonPropertyName("orderId")] string OrderId,
    [property: JsonPropertyName("createdAt")] string CreatedAt,
    [property: JsonPropertyName("customer")] OrderCustomer Customer,
    [property: JsonPropertyName("lineItem")] OrderLineItem LineItem,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("processingNotes")] string ProcessingNotes,
    [property: JsonPropertyName("processedAt")] string ProcessedAt,
    [property: JsonPropertyName("orchestrationInstanceId")] string OrchestrationInstanceId);
