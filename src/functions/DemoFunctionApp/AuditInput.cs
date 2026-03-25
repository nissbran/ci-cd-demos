namespace DemoFunctionApp;

/// <summary>Payload passed from the orchestrator to the audit activity.</summary>
public record AuditInput(string OrderId, string InstanceId, EnrichedOrder EnrichedOrder);
