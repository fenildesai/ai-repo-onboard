namespace SampleCatalog.Domain;

public sealed record Product(int Id, string Name, decimal Price);

public sealed class Catalog
{
    private readonly Product[] products =
    [
        new(1, "Notebook", 3.50m),
        new(2, "Pen", 1.20m),
        new(3, "Pencil", 0.80m)
    ];

    public IReadOnlyList<Product> Search(string? query)
    {
        var term = query?.Trim();
        return products
            .Where(product => string.IsNullOrEmpty(term) ||
                product.Name.Contains(term, StringComparison.OrdinalIgnoreCase))
            .ToArray();
    }

    public Product? Find(int id) => Array.Find(products, product => product.Id == id);
}
