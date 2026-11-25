using SampleCatalog.Domain;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<Catalog>();
var app = builder.Build();

app.MapGet("/products", (string? q, Catalog catalog) => catalog.Search(q));
app.MapGet("/products/{id:int}", (int id, Catalog catalog) =>
    catalog.Find(id) is { } product ? Results.Ok(product) : Results.NotFound());

app.Run();
