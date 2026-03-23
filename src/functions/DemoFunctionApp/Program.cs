using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        var fqdn = context.Configuration["ServiceBusConnection__fullyQualifiedNamespace"]
                   ?? throw new InvalidOperationException("ServiceBusConnection__fullyQualifiedNamespace is not set");

        // Shared ServiceBusClient — activities use it to publish to orders-enriched
        services.AddSingleton(_ => new ServiceBusClient(fqdn, new DefaultAzureCredential()));
    })
    .Build();

host.Run();
