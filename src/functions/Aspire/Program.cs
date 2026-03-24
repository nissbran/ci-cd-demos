var builder = DistributedApplication.CreateBuilder(args);

var storage = builder.AddAzureStorage("storage").RunAsEmulator(b =>
{
    b.WithLifetime(ContainerLifetime.Persistent);
});
var sql = builder.AddAzureSqlServer("sql")
    .RunAsContainer(container =>
    {
        container.WithLifetime(ContainerLifetime.Persistent);
    });

var auditDb = sql.AddDatabase("audit-db");

var serviceBus = builder.AddAzureServiceBus("messaging")
    .RunAsEmulator(emulator =>
    {
        emulator.WithConfigurationFile(
            path: "./ServiceBusConfig.json");
    });


var agent = builder.AddAzureFunctionsProject<Projects.DemoFunctionApp>("DemoFunctionApp")
    .WithHostStorage(storage)
    .WithReference(auditDb)
    .WithReference(serviceBus)
    .WaitFor(storage)
    .WithExternalHttpEndpoints();

builder.Build().Run();