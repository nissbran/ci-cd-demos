using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.DurableTask;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace DemoFunctionApp;

/// <summary>
/// Activity 2 — Writes the enriched order and orchestration metadata to the SQL
/// AuditLog table. The table is created on first use if it does not already exist.
/// Connects via managed identity (Authentication=Active Directory Managed Identity).
/// </summary>
public class AuditOrderActivity(IConfiguration configuration, ILogger<AuditOrderActivity> logger)
{
    private readonly string _connectionString = configuration["SqlConnectionString"]
        ?? throw new InvalidOperationException("SqlConnectionString is not configured");

    [Function(nameof(AuditOrderActivity))]
    public async Task Run([ActivityTrigger] AuditInput input, TaskActivityContext context)
    {
        logger.LogInformation(
            "AuditOrderActivity: writing audit record for order {OrderId} (instance {InstanceId})",
            input.OrderId, input.InstanceId);

        var messageJson = JsonSerializer.Serialize(input.EnrichedOrder);

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync();

        await EnsureTableExistsAsync(conn);

        const string insertSql = """
            INSERT INTO AuditLog (OrderId, InstanceId, MessageJson, AuditedAt, Source)
            VALUES (@OrderId, @InstanceId, @MessageJson, SYSUTCDATETIME(), 'DemoFunctionApp')
            """;

        await using var cmd = new SqlCommand(insertSql, conn);
        cmd.Parameters.AddWithValue("@OrderId", input.OrderId);
        cmd.Parameters.AddWithValue("@InstanceId", input.InstanceId);
        cmd.Parameters.AddWithValue("@MessageJson", messageJson);
        await cmd.ExecuteNonQueryAsync();

        logger.LogInformation(
            "AuditOrderActivity: audit record written for order {OrderId}", input.OrderId);
    }

    private static async Task EnsureTableExistsAsync(SqlConnection conn)
    {
        const string createTableSql = """
            IF NOT EXISTS (
                SELECT 1 FROM INFORMATION_SCHEMA.TABLES
                WHERE TABLE_NAME = 'AuditLog'
            )
            BEGIN
                CREATE TABLE AuditLog (
                    Id         INT          IDENTITY(1,1) PRIMARY KEY,
                    OrderId    NVARCHAR(100) NOT NULL,
                    InstanceId NVARCHAR(100) NOT NULL,
                    MessageJson NVARCHAR(MAX) NOT NULL,
                    AuditedAt  DATETIME2    NOT NULL,
                    Source     NVARCHAR(100) NOT NULL
                )
            END
            """;

        await using var cmd = new SqlCommand(createTableSql, conn);
        await cmd.ExecuteNonQueryAsync();
    }
}
