using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SampleCatalog.Domain;

namespace SampleCatalog.Ui.Pages;

public sealed class IndexModel(IHttpClientFactory clients) : PageModel
{
    [BindProperty(SupportsGet = true)]
    public string? Query { get; set; }

    public IReadOnlyList<Product> Products { get; private set; } = [];
    public bool CatalogUnavailable { get; private set; }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        try
        {
            var route = $"products?q={Uri.EscapeDataString(Query ?? string.Empty)}";
            Products = await clients.CreateClient("Catalog")
                .GetFromJsonAsync<Product[]>(route, cancellationToken) ?? [];
        }
        catch (HttpRequestException)
        {
            CatalogUnavailable = true;
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            CatalogUnavailable = true;
        }
    }
}
