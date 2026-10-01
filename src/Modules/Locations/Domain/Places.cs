using SharedKernel;

namespace Locations.Domain;

public sealed class City : Entity
{
    public string Name { get; private set; } = default!;
    public string State { get; private set; } = default!;
    public double Latitude { get; private set; }
    public double Longitude { get; private set; }

    private City() { }
    public static City Create(string name, string state, double lat, double lng)
        => new() { Name = name, State = state, Latitude = lat, Longitude = lng };
}

public sealed class Locality : Entity
{
    public Guid CityId { get; private set; }
    public string Name { get; private set; } = default!;
    public double Latitude { get; private set; }
    public double Longitude { get; private set; }

    private Locality() { }
    public static Locality Create(Guid cityId, string name, double lat, double lng)
        => new() { CityId = cityId, Name = name, Latitude = lat, Longitude = lng };
}
