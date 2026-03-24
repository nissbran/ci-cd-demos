using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        var fqdn = context.Configuration["OrdersServiceBus:fullyQualifiedNamespace"];
        var connectionString = context.Configuration["OrdersServiceBus"];

        // Managed identity (Azure): uses fullyQualifiedNamespace + DefaultAzureCredential
        // Local dev: uses connection string (injected by Aspire emulator or set in local.settings.json)
        var serviceBusClient = fqdn is not null
            ? new ServiceBusClient(fqdn, new DefaultAzureCredential())
            : new ServiceBusClient(connectionString
                ?? throw new InvalidOperationException(
                    "Either OrdersServiceBus__fullyQualifiedNamespace (managed identity) or OrdersServiceBus (connection string) must be configured."));

        services.AddSingleton(serviceBusClient);
    })
    .Build();

host.Run();
