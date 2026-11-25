using SampleCatalog.Domain;
using Xunit;

namespace SampleCatalog.Domain.Tests;

public sealed class CatalogTests
{
    [Fact]
    public void SearchWithoutQueryReturnsAllProducts() =>
        Assert.Equal(3, new Catalog().Search(null).Count);

    [Fact]
    public void SearchTrimsQueryAndIgnoresCase() =>
        Assert.Equal("Notebook", Assert.Single(new Catalog().Search(" NOTE ")).Name);

    [Fact]
    public void SearchWithoutMatchesReturnsEmpty() =>
        Assert.Empty(new Catalog().Search("eraser"));

    [Fact]
    public void FindReturnsProductForKnownId() =>
        Assert.Equal(1.20m, new Catalog().Find(2)?.Price);

    [Fact]
    public void FindReturnsNullForUnknownId() =>
        Assert.Null(new Catalog().Find(99));
}
