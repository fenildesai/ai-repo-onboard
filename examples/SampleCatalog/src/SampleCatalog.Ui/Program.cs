var builder = WebApplication.CreateBuilder(args);
builder.Services.AddRazorPages();
builder.Services.AddHttpClient("Catalog", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["CatalogApi:BaseUrl"] ?? "http://localhost:51873");
    client.Timeout = TimeSpan.FromSeconds(5);
});
var app = builder.Build();

app.UseStaticFiles();
app.MapRazorPages();
app.Run();
