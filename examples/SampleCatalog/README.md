# Sample Catalog

A .NET 10 sample for validating AI Repo Onboard against a multi-project repository.

| Project | Purpose |
| --- | --- |
| `src/SampleCatalog.Api` | ASP.NET Core minimal API for searching and retrieving products |
| `src/SampleCatalog.Domain` | Product and catalog logic |
| `src/SampleCatalog.Ui` | ASP.NET Core Razor Pages UI that calls the API |
| `tests/SampleCatalog.Domain.Tests` | xUnit unit tests for catalog behavior |

## Build and test

```powershell
dotnet build SampleCatalog.slnx
dotnet test SampleCatalog.slnx
```

## Run locally

Start the API and UI in separate terminals from the solution directory.

```powershell
dotnet run --project src/SampleCatalog.Api --no-launch-profile -- --urls http://localhost:51873
dotnet run --project src/SampleCatalog.Ui --no-launch-profile -- --urls http://localhost:51874
```

Open [Sample Catalog](http://localhost:51874). The API also serves `GET /products?q=pen` and `GET /products/1`.

Point AI Repo Onboard at the solution directory to assess the whole repository.
